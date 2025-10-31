# frozen_string_literal: true

require_relative 'dk_payment_gateway/version'
require_relative 'dk_payment_gateway/configuration'
require_relative 'dk_payment_gateway/errors'
require_relative 'dk_payment_gateway/utils'
require_relative 'dk_payment_gateway/client'
require_relative 'dk_payment_gateway/authentication'
require_relative 'dk_payment_gateway/signature'
require_relative 'dk_payment_gateway/pull_payment'
require_relative 'dk_payment_gateway/intra_transaction'
require_relative 'dk_payment_gateway/qr_payment'
require_relative 'dk_payment_gateway/transaction_status'

module DkPaymentGateway
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.client
    Client.new(configuration)
  end
end
