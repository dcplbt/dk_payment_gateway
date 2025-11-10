# frozen_string_literal: true

module DkPaymentGateway
  class IntraTransaction
    attr_reader :client

    def initialize(client)
      @client = client
    end

    # Intra (DK - DK) Beneficiary Account Inquiry
    # Validates beneficiary account details before initiating a fund transfer
    #
    # @param params [Hash] Account inquiry parameters
    # @option params [String] :request_id Unique identifier for the inquiry request
    # @option params [Numeric] :amount Transaction amount
    # @option params [String] :currency Currency code (e.g., "BTN")
    # @option params [String] :bene_bank_code Beneficiary bank code (1060 for intra)
    # @option params [String] :bene_account_number Beneficiary account number
    # @option params [String] :source_account_name Source account holder name (optional)
    # @option params [String] :source_account_number Source account number
    #
    # @return [Hash] Response containing inquiry_id and account_name
    def account_inquiry(params)
      validate_inquiry_params!(params)

      request_body = build_inquiry_body(params)
      signature_headers = generate_signature_headers(request_body)

      response = client.post(
        '/v1/beneficiary/account_inquiry',
        body: request_body.to_json,
        headers: signature_headers
      )

      validate_response!(response, 'Account Inquiry')
      response['response_data']
    end

    # Intra (DK - DK) Fund Transfer
    # Initiates a fund transfer after successful account inquiry
    #
    # @param params [Hash] Fund transfer parameters
    # @option params [String] :request_id Unique identifier for the request
    # @option params [String] :inquiry_id Inquiry ID from account_inquiry
    # @option params [String] :source_app Source application identifier
    # @option params [Numeric] :transaction_amount Amount to transfer
    # @option params [String] :currency Currency code (e.g., "BTN")
    # @option params [String] :transaction_datetime Transaction timestamp (ISO 8601)
    # @option params [String] :bene_bank_code Beneficiary bank code
    # @option params [String] :bene_account_number Beneficiary account number
    # @option params [String] :bene_cust_name Beneficiary customer name
    # @option params [String] :source_account_name Source account holder name (optional)
    # @option params [String] :source_account_number Source account number
    # @option params [String] :payment_type Payment type (should be "INTRA" for DK-DK)
    # @option params [String] :narration Transaction description/purpose
    #
    # @return [Hash] Response containing inquiry_id and txn_status_id
    def fund_transfer(params)
      validate_transfer_params!(params)

      request_body = build_transfer_body(params)
      signature_headers = generate_signature_headers(request_body)

      response = client.post(
        '/v1/initiate/transaction',
        body: request_body.to_json,
        headers: signature_headers
      )

      validate_response!(response, 'Fund Transfer')
      response['response_data']
    end

    private

    def build_inquiry_body(params)
      {
        request_id: params[:request_id],
        amount: params[:amount].to_s,
        currency: params[:currency],
        bene_bank_code: params[:bene_bank_code],
        bene_account_number: params[:bene_account_number],
        soure_account_number: params[:source_account_number] # NOTE: API has typo "soure"
      }.tap do |body|
        body[:source_account_name] = params[:source_account_name] if params[:source_account_name]
      end
    end

    def build_transfer_body(params)
      {
        request_id: params[:request_id],
        inquiry_id: params[:inquiry_id],
        transaction_datetime: params[:transaction_datetime],
        source_app: params[:source_app] || client.config.source_app,
        transaction_amount: params[:transaction_amount],
        currency: params[:currency],
        payment_type: params[:payment_type] || 'INTRA',
        source_account_number: params[:source_account_number],
        bene_cust_name: params[:bene_cust_name],
        bene_account_number: params[:bene_account_number],
        bene_bank_code: params[:bene_bank_code],
        narration: params[:narration]
      }.tap do |body|
        body[:source_account_name] = params[:source_account_name] if params[:source_account_name]
      end
    end

    def validate_inquiry_params!(params)
      required = %i[request_id amount currency bene_bank_code
                    bene_account_number source_account_number]

      missing = required.select { |key| params[key].nil? || params[key].to_s.empty? }

      raise InvalidParameterError, "Missing required parameters: #{missing.join(', ')}" unless missing.empty?
    end

    def validate_transfer_params!(params)
      required = %i[request_id inquiry_id transaction_amount currency
                    transaction_datetime bene_bank_code bene_account_number
                    bene_cust_name source_account_number narration]

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
