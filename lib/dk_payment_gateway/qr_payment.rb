# frozen_string_literal: true

module DkPaymentGateway
  class QrPayment
    attr_reader :client

    def initialize(client)
      @client = client
    end

    # Generate QR Code for payment transaction
    #
    # If amount = 0, generates a Static QR (payer enters amount)
    # If amount > 0, generates a Dynamic QR (amount is fixed)
    #
    # @param params [Hash] QR generation parameters
    # @option params [String] :request_id Unique identifier for the request
    # @option params [String] :currency Currency code (e.g., "BTN")
    # @option params [String] :bene_account_number Beneficiary account number
    # @option params [Numeric] :amount Transaction amount (0 for static QR, >0 for dynamic QR)
    # @option params [String] :mcc_code Merchant Category Code (ISO 18245)
    # @option params [String] :remarks Optional notes or comments (optional)
    #
    # @return [Hash] Response containing base64 encoded QR image
    def generate_qr(params)
      validate_qr_params!(params)

      request_body = build_qr_body(params)
      signature_headers = generate_signature_headers(request_body)

      response = client.post(
        '/v1/generate_qr',
        body: request_body,
        headers: signature_headers
      )

      validate_response!(response, 'QR Generation')
      response['response_data']
    end

    # Decode base64 QR image and save to file
    # @param base64_image [String] Base64 encoded image
    # @param file_path [String] Path to save the image
    def save_qr_image(base64_image, file_path)
      require 'base64'

      image_data = Base64.decode64(base64_image)
      File.open(file_path, 'wb') { |f| f.write(image_data) }

      file_path
    end

    private

    def build_qr_body(params)
      {
        request_id: params[:request_id],
        currency: params[:currency],
        bene_account_number: params[:bene_account_number],
        amount: params[:amount],
        mcc_code: params[:mcc_code]
      }.tap do |body|
        body[:remarks] = params[:remarks] if params[:remarks]
      end
    end

    def validate_qr_params!(params)
      required = %i[request_id currency bene_account_number amount mcc_code]

      missing = required.select { |key| params[key].nil? }

      raise InvalidParameterError, "Missing required parameters: #{missing.join(', ')}" unless missing.empty?

      # Validate amount is numeric
      return if params[:amount].is_a?(Numeric) || params[:amount].to_s.match?(/^\d+(\.\d+)?$/)

      raise InvalidParameterError, 'Amount must be a valid number'
    end

    def validate_response!(response, operation)
      return if response.is_a?(Hash) && response['response_code'] == '0000'

      error_msg = response['response_detail'] || response['response_message'] || 'Unknown error'
      raise TransactionError.new(
        "#{operation} failed: #{error_msg}",
        response_code: response['response_code'],
        response_detail: response['response_detail']
      )
    end

    def generate_signature_headers(request_body)
      raise SignatureError, 'Private key not available. Call client.authenticate! first' unless client.private_key

      Signature.generate(client.private_key, request_body)
    end
  end
end
