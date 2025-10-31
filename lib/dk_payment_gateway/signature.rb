# frozen_string_literal: true

require "jwt"
require "base64"
require "json"
require "time"
require "securerandom"

module DkPaymentGateway
  class Signature
    attr_reader :private_key

    def initialize(private_key)
      @private_key = private_key
    end

    # Generate signature headers for a request
    # Returns a hash with DK-Signature, DK-Timestamp, and DK-Nonce
    def generate_headers(request_body)
      timestamp = generate_timestamp
      nonce = generate_nonce
      signature = sign_request(request_body, timestamp, nonce)

      {
        "DK-Signature" => "DKSignature #{signature}",
        "DK-Timestamp" => timestamp,
        "DK-Nonce" => nonce
      }
    end

    private

    # Generate ISO 8601 timestamp
    def generate_timestamp
      Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    end

    # Generate unique alphanumeric nonce
    def generate_nonce
      SecureRandom.hex(16)
    end

    # Sign the request using RS256 algorithm
    def sign_request(request_body, timestamp, nonce)
      # Serialize request body to canonical JSON (sorted keys, no spaces)
      request_body_str = JSON.generate(request_body, space: "", object_nl: "", array_nl: "")
      
      # Base64 encode the request body
      body_base64 = Base64.strict_encode64(request_body_str)

      # Create the payload for signing
      token_payload = {
        "data" => body_base64,
        "timestamp" => timestamp,
        "nonce" => nonce
      }

      # Sign using RS256
      JWT.encode(token_payload, OpenSSL::PKey::RSA.new(private_key), "RS256")
    rescue => e
      raise SignatureError, "Failed to generate signature: #{e.message}"
    end

    class << self
      # Convenience method to generate signature headers
      def generate(private_key, request_body)
        new(private_key).generate_headers(request_body)
      end
    end
  end
end

