# frozen_string_literal: true

require 'uri'
require 'securerandom'

module DkPaymentGateway
  class Authentication
    attr_reader :client

    def initialize(client)
      @client = client
    end

    # Fetch authorization token
    # Returns the access token string
    def fetch_token
      response = client.post(
        '/v1/auth/token',
        body: token_request_body,
        headers: token_request_headers,
        skip_auth: true
      )
      validate_token_response!(response)

      response['response_data']['access_token']
    rescue StandardError => e
      raise AuthenticationError, "Failed to fetch token: #{e.message}"
    end

    # Fetch RSA private key for signing requests
    # Returns the private key as a string
    def fetch_private_key
      raise AuthenticationError, 'Access token required to fetch private key' unless client.access_token

      request_id = generate_request_id
      headers = {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{client.access_token}"
      }
      response = client.post(
        '/v1/sign/key',
        headers: headers,
        body: {
          request_id: request_id,
          source_app: client.config.source_app
        }.to_json,
        skip_auth: false
      )

      # The response is plain text containing the private key
      if response.is_a?(String) && response.include?('BEGIN PRIVATE KEY')
        response
      elsif response.is_a?(Hash) && response['response_code'] == '3001'
        raise AuthenticationError, "Private key not found: #{response['response_detail']}"
      else
        raise AuthenticationError, 'Invalid private key response'
      end
    rescue StandardError => e
      raise AuthenticationError, "Failed to fetch private key: #{e.message}"
    end

    private

    def token_request_body # rubocop:disable Metrics/MethodLength
      URI.encode_www_form(
        {
          username: client.config.username,
          password: client.config.password,
          client_id: client.config.client_id,
          client_secret: client.config.client_secret,
          grant_type: 'password',
          scopes: 'keys:read',
          source_app: client.config.source_app,
          request_id: generate_request_id
        }
      )
    end

    def token_request_headers
      {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'X-gravitee-api-key' => client.config.api_key
      }
    end

    def validate_token_response!(response)
      unless response.is_a?(Hash) && response['response_code'] == '0000'
        error_detail = response['response_detail'] || response['response_message'] || 'Unknown error'
        raise AuthenticationError, "Token request failed: #{error_detail}"
      end

      return if response['response_data'] && response['response_data']['access_token']

      raise AuthenticationError, 'No access token in response'
    end

    def generate_request_id
      "#{Time.now.to_i}-#{SecureRandom.hex(8)}"
    end
  end
end
