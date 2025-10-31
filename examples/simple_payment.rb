#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple payment example using DK Payment Gateway
# This demonstrates a basic pull payment flow

require 'bundler/setup'
require 'dk_payment_gateway'

# Configure the client
DkPaymentGateway.configure do |config|
  config.base_url = ENV['DK_BASE_URL'] || 'https://internal-gateway.uat.digitalkidu.bt'
  config.api_key = ENV['DK_API_KEY']
  config.username = ENV['DK_USERNAME']
  config.password = ENV['DK_PASSWORD']
  config.client_id = ENV['DK_CLIENT_ID']
  config.client_secret = ENV['DK_CLIENT_SECRET']
  config.source_app = ENV['DK_SOURCE_APP'] || 'SRC_AVS_0201'
end

def main
  puts '=== DK Payment Gateway - Simple Payment Example ==='
  puts

  # Initialize client
  client = DkPaymentGateway.client

  # Authenticate
  puts 'Authenticating...'
  client.authenticate!
  puts '✓ Authentication successful'
  puts

  # Payment details
  amount = 100.00
  fee = 5.00

  puts 'Payment Details:'
  puts "  Amount: BTN #{amount}"
  puts "  Fee: BTN #{fee}"
  puts "  Total: BTN #{amount + fee}"
  puts

  # Step 1: Request authorization
  puts 'Step 1: Requesting payment authorization...'

  stan = DkPaymentGateway::PullPayment.generate_stan('0201')

  begin
    auth_response = client.pull_payment.authorize(
      transaction_datetime: Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
      stan_number: stan,
      transaction_amount: amount,
      transaction_fee: fee,
      payment_desc: 'Test payment - Order #TEST001',
      account_number: '110158212197',
      account_name: 'Test Merchant',
      phone_number: '17811440',
      remitter_account_number: '770182571',
      remitter_account_name: 'Test Customer',
      remitter_bank_id: '1040'
    )

    puts '✓ Authorization successful'
    puts "  Transaction ID: #{auth_response['bfs_txn_id']}"
    puts "  STAN: #{auth_response['stan_number']}"
    puts

    # Step 2: Get OTP from user
    puts "Step 2: OTP has been sent to customer's phone"
    print 'Enter OTP: '
    otp = gets.chomp
    puts

    # Step 3: Complete payment
    puts 'Step 3: Completing payment with OTP...'

    debit_response = client.pull_payment.debit(
      request_id: DkPaymentGateway::Utils.generate_request_id('PAY'),
      bfs_txn_id: auth_response['bfs_txn_id'],
      bfs_remitter_otp: otp
    )

    if debit_response['code'] == '00'
      puts '✓ Payment completed successfully!'
      puts "  Transaction ID: #{debit_response['bfs_txn_id']}"
      puts "  Status: #{debit_response['description']}"
    else
      puts '✗ Payment failed'
      puts "  Code: #{debit_response['code']}"
      puts "  Description: #{debit_response['description']}"
    end
  rescue DkPaymentGateway::TransactionError => e
    puts "✗ Transaction error: #{e.message}"
    puts "  Error code: #{e.response_code}"
  rescue DkPaymentGateway::Error => e
    puts "✗ Error: #{e.message}"
  end
end

# Run the example
main if __FILE__ == $PROGRAM_NAME
