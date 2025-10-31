#!/usr/bin/env ruby
# frozen_string_literal: true

# Intra-bank transfer example using DK Payment Gateway
# This demonstrates transferring funds between DK accounts

require 'bundler/setup'
require 'dk_payment_gateway'

# Configure the client
DkPaymentGateway.configure do |config|
  config.base_url = ENV['DK_BASE_URL'] || "https://internal-gateway.uat.digitalkidu.bt/api/dkpg"
  config.api_key = ENV['DK_API_KEY']
  config.username = ENV['DK_USERNAME']
  config.password = ENV['DK_PASSWORD']
  config.client_id = ENV['DK_CLIENT_ID']
  config.client_secret = ENV['DK_CLIENT_SECRET']
  config.source_app = ENV['DK_SOURCE_APP'] || "SRC_AVS_0201"
end

def main
  puts "=== DK Payment Gateway - Intra-Bank Transfer Example ==="
  puts

  # Initialize client
  client = DkPaymentGateway.client
  
  # Authenticate
  puts "Authenticating..."
  client.authenticate!
  puts "✓ Authentication successful"
  puts

  # Transfer details
  source_account = "100100365856"
  beneficiary_account = "100100148337"
  amount = 500.00
  
  puts "Transfer Details:"
  puts "  From: #{source_account}"
  puts "  To: #{beneficiary_account}"
  puts "  Amount: BTN #{amount}"
  puts

  begin
    # Step 1: Verify beneficiary account
    puts "Step 1: Verifying beneficiary account..."
    
    inquiry_response = client.intra_transaction.account_inquiry(
      request_id: DkPaymentGateway::Utils.generate_request_id("INQ"),
      amount: amount,
      currency: "BTN",
      bene_bank_code: "1060",
      bene_account_number: beneficiary_account,
      source_account_number: source_account
    )
    
    puts "✓ Account verified"
    puts "  Inquiry ID: #{inquiry_response['inquiry_id']}"
    puts "  Beneficiary Name: #{inquiry_response['account_name']}"
    puts

    # Step 2: Confirm transfer
    print "Proceed with transfer? (yes/no): "
    confirmation = gets.chomp.downcase
    
    unless confirmation == 'yes' || confirmation == 'y'
      puts "Transfer cancelled"
      return
    end
    puts

    # Step 3: Execute transfer
    puts "Step 2: Executing transfer..."
    
    transfer_response = client.intra_transaction.fund_transfer(
      request_id: DkPaymentGateway::Utils.generate_request_id("TXN"),
      inquiry_id: inquiry_response['inquiry_id'],
      transaction_datetime: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
      transaction_amount: amount,
      currency: "BTN",
      payment_type: "INTRA",
      source_account_number: source_account,
      bene_cust_name: inquiry_response['account_name'],
      bene_account_number: beneficiary_account,
      bene_bank_code: "1060",
      narration: "Test transfer"
    )
    
    puts "✓ Transfer completed successfully!"
    puts "  Transaction Status ID: #{transfer_response['txn_status_id']}"
    puts

    # Step 4: Verify transaction status
    puts "Step 3: Verifying transaction status..."
    
    # Wait a moment for transaction to process
    sleep 2
    
    # Note: You would use the actual transaction_id returned by the system
    # This is just an example
    puts "✓ Transfer processed"
    
  rescue DkPaymentGateway::TransactionError => e
    puts "✗ Transaction error: #{e.message}"
    puts "  Error code: #{e.response_code}"
  rescue DkPaymentGateway::Error => e
    puts "✗ Error: #{e.message}"
  end
end

# Run the example
main if __FILE__ == $PROGRAM_NAME

