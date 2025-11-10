# frozen_string_literal: true

module DkPaymentGateway
  class TransactionStatus
    attr_reader :client

    def initialize(client)
      @client = client
    end

    # Payment Status Verification - For current date
    # Checks the status of a payment transaction for the current day
    #
    # @param params [Hash] Status check parameters
    # @option params [String] :request_id Unique identifier for the request
    # @option params [String] :transaction_id Transaction ID returned during payment
    # @option params [String] :bene_account_number Beneficiary account number
    #
    # @return [Hash] Response containing transaction status details
    def check_current_day(params)
      validate_current_day_params!(params)

      request_body = build_current_day_body(params)
      signature_headers = generate_signature_headers(request_body)

      response = client.post(
        '/v1/transaction/status',
        body: request_body,
        headers: signature_headers
      )

      validate_response!(response, 'Transaction Status Check')
      response['response_data']
    end

    # Payment Status Verification - Subsequent Business Days
    # Checks the status of a payment transaction for previous business days
    #
    # @param params [Hash] Status check parameters
    # @option params [String] :request_id Unique identifier for the request
    # @option params [String] :transaction_id Transaction ID returned during payment
    # @option params [String] :transaction_date Date when transaction was initiated (YYYY-MM-DD)
    # @option params [String] :bene_account_number Beneficiary account number
    #
    # @return [Hash] Response containing transaction status details
    def check_previous_days(params)
      validate_previous_days_params!(params)

      request_body = build_previous_days_body(params)
      signature_headers = generate_signature_headers(request_body)

      response = client.post(
        '/v1/transactions/status',
        body: request_body,
        headers: signature_headers
      )

      validate_response!(response, 'Transaction Status Check')
      response['response_data']
    end

    # Alias for better readability
    alias check_status check_current_day
    alias check_historical_status check_previous_days

    private

    def build_current_day_body(params)
      {
        request_id: params[:request_id],
        transaction_id: params[:transaction_id],
        bene_account_number: params[:bene_account_number]
      }
    end

    def build_previous_days_body(params)
      {
        request_id: params[:request_id],
        transaction_id: params[:transaction_id],
        trasnaction_date: params[:transaction_date], # NOTE: API has typo "trasnaction"
        bene_account_number: params[:bene_account_number]
      }
    end

    def validate_current_day_params!(params)
      required = %i[request_id transaction_id bene_account_number]

      missing = required.select { |key| params[key].nil? || params[key].to_s.empty? }

      raise InvalidParameterError, "Missing required parameters: #{missing.join(', ')}" unless missing.empty?
    end

    def validate_previous_days_params!(params)
      required = %i[request_id transaction_id transaction_date bene_account_number]

      missing = required.select { |key| params[key].nil? || params[key].to_s.empty? }

      raise InvalidParameterError, "Missing required parameters: #{missing.join(', ')}" unless missing.empty?

      # Validate date format
      return if params[:transaction_date].match?(/^\d{4}-\d{2}-\d{2}$/)

      raise InvalidParameterError, 'transaction_date must be in YYYY-MM-DD format'
    end

    def validate_response!(response, operation)
      return if response.is_a?(Hash) && response['response_code'] == '0000'

      error_msg = response['response_description'] || response['response_detail'] ||
                  response['response_message'] || 'Unknown error'
      raise TransactionError.new(
        "#{operation} failed: #{error_msg}",
        response_code: response['response_code'],
        response_message: response['response_message'],
        response_description: response['response_description'],
        response_detail: response['response_detail']
      )
    end

    def generate_signature_headers(request_body)
      raise SignatureError, 'Private key not available. Call client.authenticate! first' unless client.private_key

      Signature.generate(client.private_key, request_body)
    end
  end
end
