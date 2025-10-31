#!/usr/bin/env ruby
# frozen_string_literal: true

# QR code generation example using DK Payment Gateway
# This demonstrates generating both static and dynamic QR codes

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
  puts "=== DK Payment Gateway - QR Code Generation Example ==="
  puts

  # Initialize client
  client = DkPaymentGateway.client
  
  # Authenticate
  puts "Authenticating..."
  client.authenticate!
  puts "✓ Authentication successful"
  puts

  # Merchant details
  merchant_account = "100100148337"
  
  puts "Select QR type:"
  puts "1. Static QR (customer enters amount)"
  puts "2. Dynamic QR (fixed amount)"
  print "Choice (1 or 2): "
  choice = gets.chomp
  puts

  begin
    case choice
    when "1"
      generate_static_qr(client, merchant_account)
    when "2"
      generate_dynamic_qr(client, merchant_account)
    else
      puts "Invalid choice"
    end
  rescue DkPaymentGateway::Error => e
    puts "✗ Error: #{e.message}"
  end
end

def generate_static_qr(client, merchant_account)
  puts "Generating Static QR Code..."
  puts "  Merchant Account: #{merchant_account}"
  puts "  Amount: Customer will enter"
  puts

  response = client.qr_payment.generate_qr(
    request_id: DkPaymentGateway::Utils.generate_request_id("QR"),
    currency: "BTN",
    bene_account_number: merchant_account,
    amount: 0, # 0 = static QR
    mcc_code: "5411", # Grocery store
    remarks: "Payment to merchant"
  )

  filename = "static_qr_#{Time.now.to_i}.png"
  client.qr_payment.save_qr_image(response['image'], filename)
  
  puts "✓ Static QR code generated successfully!"
  puts "  Saved to: #{filename}"
  puts "  Customers can scan this QR and enter any amount"
end

def generate_dynamic_qr(client, merchant_account)
  print "Enter amount (BTN): "
  amount = gets.chomp.to_f
  puts

  puts "Generating Dynamic QR Code..."
  puts "  Merchant Account: #{merchant_account}"
  puts "  Amount: BTN #{DkPaymentGateway::Utils.format_amount(amount)}"
  puts

  response = client.qr_payment.generate_qr(
    request_id: DkPaymentGateway::Utils.generate_request_id("QR"),
    currency: "BTN",
    bene_account_number: merchant_account,
    amount: amount,
    mcc_code: "5812", # Restaurant
    remarks: "Invoice payment"
  )

  filename = "dynamic_qr_#{amount.to_i}_#{Time.now.to_i}.png"
  client.qr_payment.save_qr_image(response['image'], filename)
  
  puts "✓ Dynamic QR code generated successfully!"
  puts "  Saved to: #{filename}"
  puts "  Amount is fixed at BTN #{DkPaymentGateway::Utils.format_amount(amount)}"
end

# Run the example
main if __FILE__ == $PROGRAM_NAME

