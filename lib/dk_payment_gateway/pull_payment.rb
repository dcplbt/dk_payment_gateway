# frozen_string_literal: true

module DkPaymentGateway
  class PullPayment
    attr_reader :client

    def initialize(client)
      @client = client
    end

    # Payment Gateway Authorization (Account inquiry and OTP request)
    #
    # @param params [Hash] Authorization parameters
    # @option params [String] :transaction_datetime Transaction timestamp in UTC (ISO 8601)
    # @option params [String] :stan_number 12-digit unique transaction number
    # @option params [Numeric] :transaction_amount Amount of the transaction
    # @option params [Numeric] :transaction_fee Transaction fee (use 0 if no fee)
    # @option params [String] :payment_desc Payment description
    # @option params [String] :account_number Beneficiary account number
    # @option params [String] :account_name Beneficiary account name
    # @option params [String] :email_id Beneficiary email (optional)
    # @option params [String] :phone_number Beneficiary phone number
    # @option params [String] :remitter_account_number Remitter account number
    # @option params [String] :remitter_account_name Remitter account name
    # @option params [String] :remitter_bank_id Remitter bank identifier
    #
    # @return [Hash] Response containing bfs_txn_id, stan_number, account_number, remitter_account_number
    def authorize(params)
      validate_authorization_params!(params)

      request_body = build_authorization_body(params)
      signature_headers = generate_signature_headers(request_body)

      response = client.post(
        '/v1/account_auth/pull-payment',
        body: request_body.to_json,
        headers: signature_headers
      )

      validate_response!(response, 'Authorization')
      response['response_data']
    end

    # Payment Gateway Debit Request
    # Completes a previously authorized payment by verifying OTP
    #
    # @param params [Hash] Debit request parameters
    # @option params [String] :request_id Unique identifier for the request
    # @option params [String] :bfs_txn_id Transaction ID from authorization
    # @option params [String] :bfs_remitter_otp OTP sent to remitter
    # @option params [String] :bfs_order_no Order number (optional)
    #
    # @return [Hash] Response containing bfs_txn_id, code, description
    def debit(params)
      validate_debit_params!(params)

      request_body = build_debit_body(params)
      signature_headers = generate_signature_headers(request_body)

      response = client.post(
        '/v1/debit_request/pull-payment',
        body: request_body.to_json,
        headers: signature_headers
      )

      validate_response!(response, 'Debit')
      response['response_data']
    end

    # Generate STAN number
    # @param source_app_suffix [String] Last 4 digits of source_app (e.g., "0201")
    # @param transaction_identifier [String] 8-digit identifier (timestamp or counter)
    # @return [String] 12-digit STAN number
    def self.generate_stan(source_app_suffix, transaction_identifier = nil)
      suffix = source_app_suffix.to_s[-4..]

      identifier = if transaction_identifier
                     transaction_identifier.to_s[-8..]
                   else
                     # Generate from current timestamp (HHMMSSMS format)
                     time = Time.now
                     format('%02d%02d%02d%02d', time.hour, time.min, time.sec, time.usec / 10_000)
                   end

      "#{suffix}#{identifier}"
    end

    private

    def build_authorization_body(params)
      {
        transaction_datetime: params[:transaction_datetime],
        stan_number: params[:stan_number],
        transaction_amount: params[:transaction_amount],
        transaction_fee: params[:transaction_fee] || 0,
        payment_desc: params[:payment_desc],
        account_number: params[:account_number],
        account_name: params[:account_name],
        phone_number: params[:phone_number],
        remitter_account_number: params[:remitter_account_number],
        remitter_account_name: params[:remitter_account_name],
        remitter_bank_id: params[:remitter_bank_id]
      }.tap do |body|
        body[:email_id] = params[:email_id] if params[:email_id]
      end
    end

    def build_debit_body(params)
      {
        request_id: params[:request_id],
        bfs_bfsTxnId: params[:bfs_txn_id],
        bfs_remitter_Otp: params[:bfs_remitter_otp]
      }.tap do |body|
        body[:bfs_orderNo] = params[:bfs_order_no] if params[:bfs_order_no]
      end
    end

    def validate_authorization_params!(params)
      required = %i[transaction_datetime stan_number transaction_amount payment_desc
                    account_number account_name phone_number remitter_account_number
                    remitter_account_name remitter_bank_id]

      missing = required.select { |key| params[key].nil? || params[key].to_s.empty? }

      raise InvalidParameterError, "Missing required parameters: #{missing.join(', ')}" unless missing.empty?
    end

    def validate_debit_params!(params)
      required = %i[request_id bfs_txn_id bfs_remitter_otp]

      missing = required.select { |key| params[key].nil? || params[key].to_s.empty? }

      raise InvalidParameterError, "Missing required parameters: #{missing.join(', ')}" unless missing.empty?
    end

    def validate_response!(response, operation)
      return if response.is_a?(Hash) && response['response_code'] == '0000'

      error_msg = response['response_description'] || response['response_message'] || 'Unknown error'
      raise TransactionError.new(
        "#{operation} failed: #{error_msg}",
        response_code: response['response_code'],
        response_message: response['response_message'],
        response_description: response['response_description']
      )
    end

    def generate_signature_headers(request_body)
      raise SignatureError, 'Private key not available. Call client.authenticate! first' unless client.private_key

      Signature.generate(client.private_key, request_body)
    end
  end
end
