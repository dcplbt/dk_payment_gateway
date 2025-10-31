# frozen_string_literal: true

require "faraday"
require "json"

module DkPaymentGateway
  class Client
    attr_reader :config, :access_token, :private_key

    def initialize(config = nil)
      @config = config || DkPaymentGateway.configuration
      validate_configuration!
      @access_token = nil
      @private_key = nil
    end

    # Authentication methods
    def authenticate!
      auth = Authentication.new(self)
      @access_token = auth.fetch_token
      @private_key = auth.fetch_private_key
      self
    end

    # Pull Payment methods
    def pull_payment
      @pull_payment ||= PullPayment.new(self)
    end

    # Intra Transaction methods
    def intra_transaction
      @intra_transaction ||= IntraTransaction.new(self)
    end

    # QR Payment methods
    def qr_payment
      @qr_payment ||= QrPayment.new(self)
    end

    # Transaction Status methods
    def transaction_status
      @transaction_status ||= TransactionStatus.new(self)
    end

    # HTTP request methods
    def post(path, body: {}, headers: {}, skip_auth: false)
      request(:post, path, body: body, headers: headers, skip_auth: skip_auth)
    end

    def get(path, params: {}, headers: {}, skip_auth: false)
      request(:get, path, params: params, headers: headers, skip_auth: skip_auth)
    end

    private

    def validate_configuration!
      raise ConfigurationError, "Configuration is required" if config.nil?
      unless config.valid?
        raise ConfigurationError, "Missing required configuration fields: #{config.missing_fields.join(', ')}"
      end
    end

    def request(method, path, body: {}, params: {}, headers: {}, skip_auth: false)
      url = "#{config.base_url}#{path}"
      
      response = connection.send(method) do |req|
        req.url path
        req.headers = build_headers(headers, skip_auth)
        req.body = body.to_json if method == :post && !body.empty?
        req.params = params if method == :get && !params.empty?
      end

      handle_response(response)
    rescue Faraday::Error => e
      raise NetworkError, "Network error: #{e.message}"
    end

    def connection
      @connection ||= Faraday.new(url: config.base_url) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
        conn.options.timeout = config.timeout
        conn.options.open_timeout = config.open_timeout
      end
    end

    def build_headers(custom_headers = {}, skip_auth = false)
      headers = {
        "Content-Type" => "application/json",
        "X-gravitee-api-key" => config.api_key
      }

      unless skip_auth
        headers["Authorization"] = "Bearer #{access_token}" if access_token
        headers["source_app"] = config.source_app
      end

      headers.merge(custom_headers)
    end

    def handle_response(response)
      case response.status
      when 200..299
        response.body
      when 400..499
        handle_client_error(response)
      when 500..599
        handle_server_error(response)
      else
        raise APIError, "Unexpected response status: #{response.status}"
      end
    end

    def handle_client_error(response)
      body = response.body || {}
      error_message = body["response_message"] || body["response_detail"] || "Client error"
      
      raise InvalidParameterError.new(
        error_message,
        response_code: body["response_code"],
        response_detail: body["response_detail"]
      )
    end

    def handle_server_error(response)
      body = response.body || {}
      error_message = body["response_description"] || body["response_message"] || "Server error"
      
      raise APIError.new(
        error_message,
        response_code: body["response_code"],
        response_message: body["response_message"],
        response_description: body["response_description"]
      )
    end
  end
end

