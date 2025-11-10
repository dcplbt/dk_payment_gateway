# frozen_string_literal: true

require 'dotenv/load' # Load environment variables

module DkPaymentGateway
  class Configuration
    attr_accessor :base_url, :api_key, :username, :password, :client_id,
                  :client_secret, :source_app, :timeout, :open_timeout

    def initialize
      @base_url = ENV['DK_BASE_URL']
      @api_key = ENV['DK_API_KEY']
      @username = ENV['DK_USERNAME']
      @password = ENV['DK_PASSWORD']
      @client_id = ENV['DK_CLIENT_ID']
      @client_secret = ENV['DK_CLIENT_SECRET']
      @source_app = ENV['DK_SOURCE_APP']
      @timeout = 30
      @open_timeout = 10
    end

    def valid?
      required_fields.all? { |field| !send(field).nil? && !send(field).to_s.empty? }
    end

    def required_fields
      %i[base_url api_key username password client_id client_secret source_app]
    end

    def missing_fields
      required_fields.reject { |field| !send(field).nil? && !send(field).to_s.empty? }
    end
  end
end
