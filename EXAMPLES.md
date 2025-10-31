# DK Payment Gateway - Usage Examples

This document provides comprehensive examples for all API operations supported by the DK Payment Gateway gem.

## Table of Contents

1. [Setup and Authentication](#setup-and-authentication)
2. [Pull Payment Examples](#pull-payment-examples)
3. [Intra-Bank Transaction Examples](#intra-bank-transaction-examples)
4. [QR Payment Examples](#qr-payment-examples)
5. [Transaction Status Examples](#transaction-status-examples)
6. [Complete Workflow Examples](#complete-workflow-examples)

## Setup and Authentication

### Basic Configuration

```ruby
require 'dk_payment_gateway'

DkPaymentGateway.configure do |config|
  config.base_url = "http://internal-gateway.uat.digitalkidu.bt/api/dkpg"
  config.api_key = "98cf3639-df33-4587-9d36-dae9d2bb974c"
  config.username = "your_username"
  config.password = "your_password"
  config.client_id = "0fefeac4-e969-46ce-8d02-92db4ed8e62e"
  config.client_secret = "your_client_secret"
  config.source_app = "SRC_AVS_0201"
end

# Initialize client
client = DkPaymentGateway.client

# Authenticate (fetches token and private key)
client.authenticate!
```

### Using Environment Variables

```ruby
# Set environment variables
# export DK_API_KEY="your_api_key"
# export DK_USERNAME="your_username"
# export DK_PASSWORD="your_password"
# export DK_CLIENT_ID="your_client_id"
# export DK_CLIENT_SECRET="your_client_secret"

DkPaymentGateway.configure do |config|
  config.base_url = ENV['DK_BASE_URL'] || "http://internal-gateway.uat.digitalkidu.bt/api/dkpg"
  config.api_key = ENV['DK_API_KEY']
  config.username = ENV['DK_USERNAME']
  config.password = ENV['DK_PASSWORD']
  config.client_id = ENV['DK_CLIENT_ID']
  config.client_secret = ENV['DK_CLIENT_SECRET']
  config.source_app = ENV['DK_SOURCE_APP'] || "SRC_AVS_0201"
end
```

## Pull Payment Examples

### Example 1: Complete Pull Payment Flow

```ruby
# Step 1: Generate STAN number
source_app_suffix = "0201" # Last 4 digits of SRC_AVS_0201
stan = DkPaymentGateway::PullPayment.generate_stan(source_app_suffix)
puts "Generated STAN: #{stan}"

# Step 2: Request authorization (sends OTP to remitter)
begin
  auth_response = client.pull_payment.authorize(
    transaction_datetime: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
    stan_number: stan,
    transaction_amount: 1500.00,
    transaction_fee: 10.00,
    payment_desc: "Online purchase - Order #ORD123456",
    account_number: "110158212197",
    account_name: "Merchant Store",
    email_id: "merchant@example.com",
    phone_number: "17811440",
    remitter_account_number: "770182571",
    remitter_account_name: "Customer Name",
    remitter_bank_id: "1040"
  )
  
  puts "Authorization successful!"
  puts "Transaction ID: #{auth_response['bfs_txn_id']}"
  puts "STAN: #{auth_response['stan_number']}"
  
  # Store the transaction ID for the debit request
  bfs_txn_id = auth_response['bfs_txn_id']
  
  # Step 3: Customer receives OTP and provides it
  # In a real application, you would collect this from the user
  otp = "123456" # Customer's OTP
  
  # Step 4: Complete the payment with OTP
  debit_response = client.pull_payment.debit(
    request_id: "REQ_#{Time.now.to_i}_#{SecureRandom.hex(4)}",
    bfs_txn_id: bfs_txn_id,
    bfs_remitter_otp: otp,
    bfs_order_no: "ORD123456"
  )
  
  if debit_response['code'] == '00'
    puts "Payment completed successfully!"
    puts "Transaction ID: #{debit_response['bfs_txn_id']}"
    puts "Status: #{debit_response['description']}"
  else
    puts "Payment failed: #{debit_response['description']}"
  end
  
rescue DkPaymentGateway::TransactionError => e
  puts "Transaction error: #{e.message}"
  puts "Error code: #{e.response_code}"
rescue DkPaymentGateway::InvalidParameterError => e
  puts "Invalid parameter: #{e.message}"
end
```

### Example 2: Custom STAN Generation

```ruby
# Using timestamp-based STAN
source_app_suffix = "0201"
stan_timestamp = DkPaymentGateway::PullPayment.generate_stan(source_app_suffix)
puts "Timestamp STAN: #{stan_timestamp}"

# Using custom transaction identifier
custom_identifier = "12345678"
stan_custom = DkPaymentGateway::PullPayment.generate_stan(source_app_suffix, custom_identifier)
puts "Custom STAN: #{stan_custom}"
```

## Intra-Bank Transaction Examples

### Example 1: Complete Intra-Bank Transfer

```ruby
# Step 1: Verify beneficiary account
begin
  inquiry_response = client.intra_transaction.account_inquiry(
    request_id: "INQ_#{Time.now.to_i}_#{SecureRandom.hex(4)}",
    amount: 5000.00,
    currency: "BTN",
    bene_bank_code: "1060",
    bene_account_number: "100100148337",
    source_account_name: "Rinzin Jamtsho",
    source_account_number: "100100365856"
  )
  
  puts "Account inquiry successful!"
  puts "Inquiry ID: #{inquiry_response['inquiry_id']}"
  puts "Beneficiary Name: #{inquiry_response['account_name']}"
  
  # Step 2: Proceed with fund transfer
  inquiry_id = inquiry_response['inquiry_id']
  
  transfer_response = client.intra_transaction.fund_transfer(
    request_id: "TXN_#{Time.now.to_i}_#{SecureRandom.hex(4)}",
    inquiry_id: inquiry_id,
    transaction_datetime: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
    transaction_amount: 5000.00,
    currency: "BTN",
    payment_type: "INTRA",
    source_account_name: "Rinzin Jamtsho",
    source_account_number: "100100365856",
    bene_cust_name: inquiry_response['account_name'],
    bene_account_number: "100100148337",
    bene_bank_code: "1060",
    narration: "Salary payment for October 2025"
  )
  
  puts "Transfer initiated successfully!"
  puts "Transaction Status ID: #{transfer_response['txn_status_id']}"
  
rescue DkPaymentGateway::TransactionError => e
  puts "Transfer failed: #{e.message}"
  puts "Error code: #{e.response_code}"
end
```

### Example 2: Bulk Transfer Processing

```ruby
# Process multiple transfers
transfers = [
  { account: "100100148337", amount: 1000.00, name: "Employee 1", narration: "Salary Oct 2025" },
  { account: "100100148338", amount: 1500.00, name: "Employee 2", narration: "Salary Oct 2025" },
  { account: "100100148339", amount: 2000.00, name: "Employee 3", narration: "Salary Oct 2025" }
]

results = []

transfers.each do |transfer|
  begin
    # Step 1: Account inquiry
    inquiry = client.intra_transaction.account_inquiry(
      request_id: "INQ_#{Time.now.to_i}_#{SecureRandom.hex(4)}",
      amount: transfer[:amount],
      currency: "BTN",
      bene_bank_code: "1060",
      bene_account_number: transfer[:account],
      source_account_number: "100100365856"
    )
    
    # Step 2: Fund transfer
    result = client.intra_transaction.fund_transfer(
      request_id: "TXN_#{Time.now.to_i}_#{SecureRandom.hex(4)}",
      inquiry_id: inquiry['inquiry_id'],
      transaction_datetime: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
      transaction_amount: transfer[:amount],
      currency: "BTN",
      payment_type: "INTRA",
      source_account_number: "100100365856",
      bene_cust_name: transfer[:name],
      bene_account_number: transfer[:account],
      bene_bank_code: "1060",
      narration: transfer[:narration]
    )
    
    results << { account: transfer[:account], status: "success", txn_id: result['txn_status_id'] }
    puts "✓ Transfer to #{transfer[:account]}: Success"
    
  rescue DkPaymentGateway::Error => e
    results << { account: transfer[:account], status: "failed", error: e.message }
    puts "✗ Transfer to #{transfer[:account]}: Failed - #{e.message}"
  end
  
  # Add delay between requests to avoid rate limiting
  sleep 1
end

puts "\nTransfer Summary:"
puts "Successful: #{results.count { |r| r[:status] == 'success' }}"
puts "Failed: #{results.count { |r| r[:status] == 'failed' }}"
```

## QR Payment Examples

### Example 1: Generate Static QR Code

```ruby
# Static QR - customer enters amount at payment time
begin
  qr_response = client.qr_payment.generate_qr(
    request_id: "QR_#{Time.now.to_i}_#{SecureRandom.hex(4)}",
    currency: "BTN",
    bene_account_number: "100100148337",
    amount: 0, # 0 = static QR
    mcc_code: "5411", # Grocery store
    remarks: "Payment to Merchant Store"
  )
  
  # Save QR code image
  filename = "static_qr_#{Time.now.to_i}.png"
  client.qr_payment.save_qr_image(qr_response['image'], filename)
  puts "Static QR code saved to #{filename}"
  
rescue DkPaymentGateway::Error => e
  puts "QR generation failed: #{e.message}"
end
```

### Example 2: Generate Dynamic QR Code

```ruby
# Dynamic QR - fixed amount
begin
  qr_response = client.qr_payment.generate_qr(
    request_id: "QR_#{Time.now.to_i}_#{SecureRandom.hex(4)}",
    currency: "BTN",
    bene_account_number: "100100148337",
    amount: 250.50, # Fixed amount
    mcc_code: "5812", # Restaurant
    remarks: "Invoice #INV-2025-001"
  )
  
  # Save QR code image
  filename = "invoice_qr_#{Time.now.to_i}.png"
  client.qr_payment.save_qr_image(qr_response['image'], filename)
  puts "Dynamic QR code saved to #{filename}"
  puts "Amount: BTN 250.50"
  
rescue DkPaymentGateway::Error => e
  puts "QR generation failed: #{e.message}"
end
```

## Transaction Status Examples

### Example 1: Check Current Day Transaction

```ruby
begin
  status = client.transaction_status.check_current_day(
    request_id: "STATUS_#{Time.now.to_i}",
    transaction_id: "test_txn_update23567",
    bene_account_number: "100100365856"
  )
  
  puts "Transaction Status:"
  puts "Status: #{status['status']['status_desc']}"
  puts "Amount: BTN #{status['status']['amount']}"
  puts "Timestamp: #{status['status']['txn_ts']}"
  puts "Debit Account: #{status['status']['debit_account']}"
  puts "Credit Account: #{status['status']['credit_account']}"
  
rescue DkPaymentGateway::TransactionError => e
  puts "Status check failed: #{e.message}"
end
```

### Example 2: Check Historical Transaction

```ruby
begin
  status = client.transaction_status.check_previous_days(
    request_id: "STATUS_#{Time.now.to_i}",
    transaction_id: "test_txn_update23567",
    transaction_date: "2025-09-18",
    bene_account_number: "100100365856"
  )
  
  if status.is_a?(Array)
    status.each do |txn|
      puts "Transaction found:"
      puts "  Status: #{txn['status_desc']}"
      puts "  Amount: BTN #{txn['amount']}"
      puts "  Date: #{txn['txn_ts']}"
    end
  end
  
rescue DkPaymentGateway::TransactionError => e
  puts "Status check failed: #{e.message}"
end
```

## Complete Workflow Examples

### Example: E-commerce Payment Flow

```ruby
class PaymentProcessor
  def initialize
    @client = DkPaymentGateway.client
    @client.authenticate!
  end
  
  def process_order_payment(order)
    # Step 1: Initiate payment authorization
    stan = DkPaymentGateway::PullPayment.generate_stan("0201")
    
    auth_response = @client.pull_payment.authorize(
      transaction_datetime: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
      stan_number: stan,
      transaction_amount: order[:total_amount],
      transaction_fee: calculate_fee(order[:total_amount]),
      payment_desc: "Order ##{order[:order_id]}",
      account_number: merchant_account,
      account_name: merchant_name,
      email_id: order[:customer_email],
      phone_number: order[:customer_phone],
      remitter_account_number: order[:customer_account],
      remitter_account_name: order[:customer_name],
      remitter_bank_id: order[:customer_bank_id]
    )
    
    # Store transaction ID
    order[:bfs_txn_id] = auth_response['bfs_txn_id']
    
    # Return transaction ID to customer for OTP entry
    auth_response
  end
  
  def complete_payment(order, otp)
    debit_response = @client.pull_payment.debit(
      request_id: "ORD_#{order[:order_id]}_#{Time.now.to_i}",
      bfs_txn_id: order[:bfs_txn_id],
      bfs_remitter_otp: otp,
      bfs_order_no: order[:order_id]
    )
    
    if debit_response['code'] == '00'
      # Payment successful - update order status
      update_order_status(order[:order_id], 'paid')
      send_confirmation_email(order)
      true
    else
      # Payment failed
      update_order_status(order[:order_id], 'payment_failed')
      false
    end
  end
  
  private
  
  def calculate_fee(amount)
    # Example fee calculation
    [amount * 0.01, 5.0].max # 1% with minimum 5 BTN
  end
  
  def merchant_account
    "110158212197"
  end
  
  def merchant_name
    "My E-commerce Store"
  end
  
  def update_order_status(order_id, status)
    # Update in database
  end
  
  def send_confirmation_email(order)
    # Send email
  end
end

# Usage
processor = PaymentProcessor.new

order = {
  order_id: "ORD123456",
  total_amount: 2500.00,
  customer_email: "customer@example.com",
  customer_phone: "17811440",
  customer_account: "770182571",
  customer_name: "John Doe",
  customer_bank_id: "1040"
}

# Initiate payment
auth = processor.process_order_payment(order)
puts "Please enter OTP sent to #{order[:customer_phone]}"

# Customer enters OTP
otp = gets.chomp

# Complete payment
if processor.complete_payment(order, otp)
  puts "Payment successful! Order confirmed."
else
  puts "Payment failed. Please try again."
end
```

## Error Handling Best Practices

```ruby
def safe_payment_operation
  client = DkPaymentGateway.client
  client.authenticate!
  
  # Your payment logic here
  
rescue DkPaymentGateway::ConfigurationError => e
  log_error("Configuration issue", e)
  notify_admin("Payment gateway configuration error: #{e.message}")
  
rescue DkPaymentGateway::AuthenticationError => e
  log_error("Authentication failed", e)
  # Retry authentication or notify admin
  
rescue DkPaymentGateway::InvalidParameterError => e
  log_error("Invalid parameters", e)
  # Return user-friendly error message
  { error: "Invalid payment details", details: e.response_detail }
  
rescue DkPaymentGateway::TransactionError => e
  log_error("Transaction failed", e)
  # Handle based on error code
  case e.response_code
  when "4002"
    { error: "Invalid transaction details" }
  when "5001"
    { error: "Service temporarily unavailable" }
  else
    { error: "Transaction failed", code: e.response_code }
  end
  
rescue DkPaymentGateway::NetworkError => e
  log_error("Network error", e)
  # Retry logic or queue for later
  
rescue DkPaymentGateway::Error => e
  log_error("General payment gateway error", e)
  { error: "Payment processing error" }
end
```

