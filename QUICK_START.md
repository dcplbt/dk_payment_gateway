# Quick Start Guide

Get started with DK Payment Gateway in 5 minutes.

## Installation

```bash
gem install dk_payment_gateway
```

Or add to your Gemfile:

```ruby
gem 'dk_payment_gateway'
```

## Basic Setup

```ruby
require 'dk_payment_gateway'

# Configure
DkPaymentGateway.configure do |config|
  config.base_url = "https://internal-gateway.uat.digitalkidu.bt/api/dkpg"
  config.api_key = "your_api_key"
  config.username = "your_username"
  config.password = "your_password"
  config.client_id = "your_client_id"
  config.client_secret = "your_client_secret"
  config.source_app = "SRC_AVS_0201"
end

# Initialize and authenticate
client = DkPaymentGateway.client
client.authenticate!
```

## Common Use Cases

### 1. Accept Payment (Pull Payment)

```ruby
# Step 1: Request authorization (sends OTP)
stan = DkPaymentGateway::PullPayment.generate_stan("0201")

auth = client.pull_payment.authorize(
  transaction_datetime: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  stan_number: stan,
  transaction_amount: 100.00,
  transaction_fee: 5.00,
  payment_desc: "Order #12345",
  account_number: "110158212197",
  account_name: "Your Store",
  phone_number: "17811440",
  remitter_account_number: "770182571",
  remitter_account_name: "Customer Name",
  remitter_bank_id: "1040"
)

# Step 2: Complete with OTP
result = client.pull_payment.debit(
  request_id: "REQ_#{Time.now.to_i}",
  bfs_txn_id: auth["bfs_txn_id"],
  bfs_remitter_otp: "123456" # OTP from customer
)

puts "Payment #{result['code'] == '00' ? 'successful' : 'failed'}"
```

### 2. Transfer Money (Intra-Bank)

```ruby
# Step 1: Verify account
inquiry = client.intra_transaction.account_inquiry(
  request_id: "INQ_#{Time.now.to_i}",
  amount: 500.00,
  currency: "BTN",
  bene_bank_code: "1060",
  bene_account_number: "100100148337",
  source_account_number: "100100365856"
)

# Step 2: Transfer funds
transfer = client.intra_transaction.fund_transfer(
  request_id: "TXN_#{Time.now.to_i}",
  inquiry_id: inquiry["inquiry_id"],
  transaction_datetime: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  transaction_amount: 500.00,
  currency: "BTN",
  payment_type: "INTRA",
  source_account_number: "100100365856",
  bene_cust_name: inquiry["account_name"],
  bene_account_number: "100100148337",
  bene_bank_code: "1060",
  narration: "Payment for services"
)

puts "Transfer ID: #{transfer['txn_status_id']}"
```

### 3. Generate QR Code

```ruby
# Static QR (customer enters amount)
qr = client.qr_payment.generate_qr(
  request_id: "QR_#{Time.now.to_i}",
  currency: "BTN",
  bene_account_number: "100100148337",
  amount: 0, # 0 = static
  mcc_code: "5411"
)

# Save QR image
client.qr_payment.save_qr_image(qr["image"], "payment_qr.png")
```

### 4. Check Transaction Status

```ruby
# Current day
status = client.transaction_status.check_current_day(
  request_id: "STATUS_#{Time.now.to_i}",
  transaction_id: "txn_12345",
  bene_account_number: "100100365856"
)

puts "Status: #{status['status']['status_desc']}"
puts "Amount: #{status['status']['amount']}"
```

## Error Handling

```ruby
begin
  client.authenticate!
  # Your payment operations
rescue DkPaymentGateway::AuthenticationError => e
  puts "Auth failed: #{e.message}"
rescue DkPaymentGateway::TransactionError => e
  puts "Transaction failed: #{e.message}"
  puts "Code: #{e.response_code}"
rescue DkPaymentGateway::Error => e
  puts "Error: #{e.message}"
end
```

## Environment Variables (Recommended)

Create a `.env` file:

```bash
DK_BASE_URL=https://internal-gateway.uat.digitalkidu.bt/api/dkpg
DK_API_KEY=your_api_key
DK_USERNAME=your_username
DK_PASSWORD=your_password
DK_CLIENT_ID=your_client_id
DK_CLIENT_SECRET=your_client_secret
DK_SOURCE_APP=SRC_AVS_0201
```

Then configure:

```ruby
require 'dotenv/load'

DkPaymentGateway.configure do |config|
  config.base_url = ENV['DK_BASE_URL']
  config.api_key = ENV['DK_API_KEY']
  config.username = ENV['DK_USERNAME']
  config.password = ENV['DK_PASSWORD']
  config.client_id = ENV['DK_CLIENT_ID']
  config.client_secret = ENV['DK_CLIENT_SECRET']
  config.source_app = ENV['DK_SOURCE_APP']
end
```

## Next Steps

- Read the [README](README.md) for detailed documentation
- Check [EXAMPLES.md](EXAMPLES.md) for more use cases
- See [API_REFERENCE.md](API_REFERENCE.md) for complete API documentation

## Support

For issues and questions, please refer to the documentation or contact support.
