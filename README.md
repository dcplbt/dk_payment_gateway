# DK Payment Gateway Ruby Gem

A Ruby client library for integrating with the Digital Kidu (DK) Payment Gateway API. This gem provides a clean, easy-to-use interface for:

- Pull payments (payment gateway authorization and debit)
- Intra-bank transactions (DK to DK transfers)
- QR code generation for payments
- Transaction status verification

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dk_payment_gateway'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install dk_payment_gateway
```

## Configuration

Configure the gem with your API credentials:

```ruby
DkPaymentGateway.configure do |config|
  config.base_url = "http://internal-gateway.uat.digitalkidu.bt/api/dkpg"
  config.api_key = "98cf3639-df33-4587-9d36-dae9d2bb974c"
  config.username = "your_username"
  config.password = "your_password"
  config.client_id = "0fefeac4-e969-46ce-8d02-92db4ed8e62e"
  config.client_secret = "your_client_secret"
  config.source_app = "SRC_AVS_0201"
  config.timeout = 30
  config.open_timeout = 10
end
```

## Usage

### Initialize Client and Authenticate

```ruby
# Create a client instance
client = DkPaymentGateway.client

# Authenticate and fetch private key for signing
client.authenticate!
```

### Pull Payment (Payment Gateway)

#### 1. Authorization (Account Inquiry and OTP Request)

```ruby
# Generate STAN number
stan = DkPaymentGateway::PullPayment.generate_stan("0201")

# Request authorization
response = client.pull_payment.authorize(
  transaction_datetime: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  stan_number: stan,
  transaction_amount: 100.00,
  transaction_fee: 5.00,
  payment_desc: "Payment for Invoice #123",
  account_number: "110158212197",
  account_name: "John Doe",
  email_id: "customer@example.com",
  phone_number: "17811440",
  remitter_account_number: "770182571",
  remitter_account_name: "Jane Smith",
  remitter_bank_id: "1040"
)

# Response contains:
# {
#   "bfs_txn_id" => "523400081332",
#   "stan_number" => "020111571912",
#   "account_number" => "110158212197",
#   "remitter_account_number" => "770182571"
# }

bfs_txn_id = response["bfs_txn_id"]
```

#### 2. Debit Request (Complete Payment with OTP)

```ruby
response = client.pull_payment.debit(
  request_id: "REQ_#{Time.now.to_i}",
  bfs_txn_id: bfs_txn_id,
  bfs_remitter_otp: "123456",
  bfs_order_no: "ORDER_12345" # optional
)

# Response contains:
# {
#   "bfs_txn_id" => "523700081429",
#   "code" => "00",
#   "description" => "Approved"
# }
```

### Intra-Bank Transactions (DK to DK)

#### 1. Beneficiary Account Inquiry

```ruby
response = client.intra_transaction.account_inquiry(
  request_id: "REQ_#{Time.now.to_i}",
  amount: 300.00,
  currency: "BTN",
  bene_bank_code: "1060",
  bene_account_number: "100100148337",
  source_account_name: "Rinzin Jamtsho",
  source_account_number: "100100365856"
)

# Response contains:
# {
#   "inquiry_id" => "DKBT--ptr2aseR2Ch85QY-AufVg-776768",
#   "account_name" => "Rinzin Jamtsho"
# }

inquiry_id = response["inquiry_id"]
```

#### 2. Fund Transfer

```ruby
response = client.intra_transaction.fund_transfer(
  request_id: "REQ_#{Time.now.to_i}",
  inquiry_id: inquiry_id,
  transaction_datetime: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
  transaction_amount: 300.00,
  currency: "BTN",
  payment_type: "INTRA",
  source_account_name: "Rinzin Jamtsho",
  source_account_number: "100100365856",
  bene_cust_name: "Dorji Wangchuk",
  bene_account_number: "100100148337",
  bene_bank_code: "1060",
  narration: "Payment for services"
)

# Response contains:
# {
#   "inquiry_id" => "DKBT-gllIxZ7rSoqkAOzZj4i2HQ-554567",
#   "txn_status_id" => "6f67d4ca-c8f9-49a5-8c2d-96c8b07c74e5"
# }
```

### QR Code Generation

```ruby
# Generate Static QR (amount = 0, payer enters amount)
response = client.qr_payment.generate_qr(
  request_id: "REQ_#{Time.now.to_i}",
  currency: "BTN",
  bene_account_number: "100100148337",
  amount: 0,
  mcc_code: "5411",
  remarks: "Payment for invoice #1234"
)

# Generate Dynamic QR (fixed amount)
response = client.qr_payment.generate_qr(
  request_id: "REQ_#{Time.now.to_i}",
  currency: "BTN",
  bene_account_number: "100100148337",
  amount: 50.05,
  mcc_code: "5411",
  remarks: "Payment for invoice #1234"
)

# Response contains:
# {
#   "image" => "base64_encoded_image_data"
# }

# Save QR image to file
client.qr_payment.save_qr_image(response["image"], "qr_code.png")
```

### Transaction Status Verification

#### Check Current Day Transaction

```ruby
response = client.transaction_status.check_current_day(
  request_id: "REQ_#{Time.now.to_i}",
  transaction_id: "test_txn_update23567",
  bene_account_number: "100100365856"
)

# Response contains:
# {
#   "meta_info" => {...},
#   "status" => {
#     "status" => "0",
#     "status_desc" => "Successfully completed",
#     "txn_ts" => "2025-09-18 12:32:21",
#     "amount" => "150.00",
#     "debit_account" => "200133679",
#     "credit_account" => "100100365856"
#   }
# }
```

#### Check Previous Days Transaction

```ruby
response = client.transaction_status.check_previous_days(
  request_id: "REQ_#{Time.now.to_i}",
  transaction_id: "test_txn_update23567",
  transaction_date: "2025-09-18",
  bene_account_number: "100100365856"
)

# Response contains array of transaction statuses
```

## Error Handling

The gem provides specific exception classes for different error scenarios:

```ruby
begin
  client.authenticate!
rescue DkPaymentGateway::ConfigurationError => e
  puts "Configuration error: #{e.message}"
rescue DkPaymentGateway::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue DkPaymentGateway::InvalidParameterError => e
  puts "Invalid parameters: #{e.message}"
  puts "Response code: #{e.response_code}"
  puts "Response detail: #{e.response_detail}"
rescue DkPaymentGateway::TransactionError => e
  puts "Transaction failed: #{e.message}"
  puts "Response code: #{e.response_code}"
rescue DkPaymentGateway::NetworkError => e
  puts "Network error: #{e.message}"
rescue DkPaymentGateway::SignatureError => e
  puts "Signature generation failed: #{e.message}"
rescue DkPaymentGateway::APIError => e
  puts "API error: #{e.message}"
end
```

## Bank Codes Reference

Common bank codes for use with the API:

- `1010` - Bank of Bhutan
- `1040` - Bhutan National Bank
- `1060` - Digital Kidu (for intra-bank transactions)

## Merchant Category Codes (MCC)

Refer to ISO 18245 standard for complete list. Common examples:

- `5411` - Grocery Stores, Supermarkets
- `5812` - Eating Places, Restaurants
- `5999` - Miscellaneous and Specialty Retail Stores

## Development

After checking out the repo, run:

```bash
bundle install
```

To run tests:

```bash
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

