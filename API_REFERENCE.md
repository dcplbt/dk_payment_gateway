# DK Payment Gateway API Reference

Complete API reference for the DK Payment Gateway Ruby gem.

## Table of Contents

1. [Configuration](#configuration)
2. [Client](#client)
3. [Authentication](#authentication)
4. [Pull Payment](#pull-payment)
5. [Intra Transaction](#intra-transaction)
6. [QR Payment](#qr-payment)
7. [Transaction Status](#transaction-status)
8. [Errors](#errors)

---

## Configuration

### DkPaymentGateway.configure

Configure the gem with your API credentials.

```ruby
DkPaymentGateway.configure do |config|
  config.base_url = String          # API base URL
  config.api_key = String           # X-gravitee-api-key
  config.username = String          # Authentication username
  config.password = String          # Authentication password
  config.client_id = String         # OAuth client ID
  config.client_secret = String     # OAuth client secret
  config.source_app = String        # Source application identifier
  config.timeout = Integer          # Request timeout in seconds (default: 30)
  config.open_timeout = Integer     # Connection timeout in seconds (default: 10)
end
```

### Configuration Methods

#### `#valid?`
Returns `true` if all required configuration fields are set.

#### `#missing_fields`
Returns an array of missing required configuration field names.

---

## Client

### DkPaymentGateway.client

Returns a new client instance with the current configuration.

```ruby
client = DkPaymentGateway.client
```

### Client Methods

#### `#authenticate!`
Fetches access token and private key for signing requests.

```ruby
client.authenticate!
# => Returns self
```

**Raises:**
- `DkPaymentGateway::ConfigurationError` - Invalid configuration
- `DkPaymentGateway::AuthenticationError` - Authentication failed

#### `#pull_payment`
Returns a `PullPayment` instance for pull payment operations.

```ruby
client.pull_payment
# => DkPaymentGateway::PullPayment
```

#### `#intra_transaction`
Returns an `IntraTransaction` instance for intra-bank operations.

```ruby
client.intra_transaction
# => DkPaymentGateway::IntraTransaction
```

#### `#qr_payment`
Returns a `QrPayment` instance for QR code operations.

```ruby
client.qr_payment
# => DkPaymentGateway::QrPayment
```

#### `#transaction_status`
Returns a `TransactionStatus` instance for status verification.

```ruby
client.transaction_status
# => DkPaymentGateway::TransactionStatus
```

---

## Authentication

Authentication is handled automatically when calling `client.authenticate!`.

### Methods

#### `Authentication#fetch_token`
Fetches OAuth access token.

**Returns:** `String` - Access token

**Raises:**
- `DkPaymentGateway::AuthenticationError`

#### `Authentication#fetch_private_key`
Fetches RSA private key for request signing.

**Returns:** `String` - RSA private key in PEM format

**Raises:**
- `DkPaymentGateway::AuthenticationError`

---

## Pull Payment

### PullPayment#authorize

Initiates payment authorization and sends OTP to remitter.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `transaction_datetime` | String | Yes | ISO 8601 timestamp |
| `stan_number` | String | Yes | 12-digit unique transaction number |
| `transaction_amount` | Numeric | Yes | Transaction amount |
| `transaction_fee` | Numeric | No | Transaction fee (default: 0) |
| `payment_desc` | String | Yes | Payment description |
| `account_number` | String | Yes | Beneficiary account number |
| `account_name` | String | Yes | Beneficiary account name |
| `email_id` | String | No | Beneficiary email |
| `phone_number` | String | Yes | Beneficiary phone number |
| `remitter_account_number` | String | Yes | Remitter account number |
| `remitter_account_name` | String | Yes | Remitter account name |
| `remitter_bank_id` | String | Yes | Remitter bank ID |

**Returns:** `Hash`
```ruby
{
  "bfs_txn_id" => "523400081332",
  "stan_number" => "020111571912",
  "account_number" => "110158212197",
  "remitter_account_number" => "770182571"
}
```

**Raises:**
- `DkPaymentGateway::InvalidParameterError`
- `DkPaymentGateway::TransactionError`
- `DkPaymentGateway::SignatureError`

### PullPayment#debit

Completes payment with OTP verification.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `request_id` | String | Yes | Unique request identifier |
| `bfs_txn_id` | String | Yes | Transaction ID from authorization |
| `bfs_remitter_otp` | String | Yes | OTP from remitter |
| `bfs_order_no` | String | No | Order number |

**Returns:** `Hash`
```ruby
{
  "bfs_txn_id" => "523700081429",
  "code" => "00",
  "description" => "Approved"
}
```

**Raises:**
- `DkPaymentGateway::InvalidParameterError`
- `DkPaymentGateway::TransactionError`

### PullPayment.generate_stan

Class method to generate STAN number.

**Parameters:**
- `source_app_suffix` (String) - Last 4 digits of source_app
- `transaction_identifier` (String, optional) - 8-digit identifier

**Returns:** `String` - 12-digit STAN number

```ruby
DkPaymentGateway::PullPayment.generate_stan("0201")
# => "020111571912"

DkPaymentGateway::PullPayment.generate_stan("0201", "12345678")
# => "020112345678"
```

---

## Intra Transaction

### IntraTransaction#account_inquiry

Validates beneficiary account before transfer.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `request_id` | String | Yes | Unique request identifier |
| `amount` | Numeric | Yes | Transaction amount |
| `currency` | String | Yes | Currency code (e.g., "BTN") |
| `bene_bank_code` | String | Yes | Beneficiary bank code |
| `bene_account_number` | String | Yes | Beneficiary account number |
| `source_account_name` | String | No | Source account name |
| `source_account_number` | String | Yes | Source account number |

**Returns:** `Hash`
```ruby
{
  "inquiry_id" => "DKBT--ptr2aseR2Ch85QY-AufVg-776768",
  "account_name" => "Rinzin Jamtsho"
}
```

### IntraTransaction#fund_transfer

Initiates fund transfer between DK accounts.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `request_id` | String | Yes | Unique request identifier |
| `inquiry_id` | String | Yes | Inquiry ID from account_inquiry |
| `source_app` | String | No | Source app (uses config default) |
| `transaction_amount` | Numeric | Yes | Transfer amount |
| `currency` | String | Yes | Currency code |
| `transaction_datetime` | String | Yes | ISO 8601 timestamp |
| `bene_bank_code` | String | Yes | Beneficiary bank code |
| `bene_account_number` | String | Yes | Beneficiary account number |
| `bene_cust_name` | String | Yes | Beneficiary name |
| `source_account_name` | String | No | Source account name |
| `source_account_number` | String | Yes | Source account number |
| `payment_type` | String | No | Payment type (default: "INTRA") |
| `narration` | String | Yes | Transaction description |

**Returns:** `Hash`
```ruby
{
  "inquiry_id" => "DKBT-gllIxZ7rSoqkAOzZj4i2HQ-554567",
  "txn_status_id" => "6f67d4ca-c8f9-49a5-8c2d-96c8b07c74e5"
}
```

---

## QR Payment

### QrPayment#generate_qr

Generates QR code for payment.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `request_id` | String | Yes | Unique request identifier |
| `currency` | String | Yes | Currency code |
| `bene_account_number` | String | Yes | Beneficiary account number |
| `amount` | Numeric | Yes | Amount (0 for static QR) |
| `mcc_code` | String | Yes | Merchant Category Code |
| `remarks` | String | No | Optional remarks |

**Returns:** `Hash`
```ruby
{
  "image" => "base64_encoded_image_data"
}
```

### QrPayment#save_qr_image

Saves base64 QR image to file.

**Parameters:**
- `base64_image` (String) - Base64 encoded image
- `file_path` (String) - Path to save image

**Returns:** `String` - File path

```ruby
client.qr_payment.save_qr_image(response["image"], "qr_code.png")
# => "qr_code.png"
```

---

## Transaction Status

### TransactionStatus#check_current_day

Checks transaction status for current day.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `request_id` | String | Yes | Unique request identifier |
| `transaction_id` | String | Yes | Transaction ID |
| `bene_account_number` | String | Yes | Beneficiary account number |

**Returns:** `Hash`
```ruby
{
  "meta_info" => {...},
  "status" => {
    "status" => "0",
    "status_desc" => "Successfully completed",
    "txn_ts" => "2025-09-18 12:32:21",
    "amount" => "150.00",
    "debit_account" => "200133679",
    "credit_account" => "100100365856"
  }
}
```

### TransactionStatus#check_previous_days

Checks transaction status for previous business days.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `request_id` | String | Yes | Unique request identifier |
| `transaction_id` | String | Yes | Transaction ID |
| `transaction_date` | String | Yes | Date (YYYY-MM-DD format) |
| `bene_account_number` | String | Yes | Beneficiary account number |

**Returns:** `Array<Hash>` - Array of transaction status records

### Aliases

- `check_status` - Alias for `check_current_day`
- `check_historical_status` - Alias for `check_previous_days`

---

## Errors

All errors inherit from `DkPaymentGateway::Error`.

### ConfigurationError

Raised when configuration is invalid or missing.

```ruby
rescue DkPaymentGateway::ConfigurationError => e
  puts e.message
end
```

### AuthenticationError

Raised when authentication fails.

```ruby
rescue DkPaymentGateway::AuthenticationError => e
  puts e.message
end
```

### InvalidParameterError

Raised when request parameters are invalid.

**Attributes:**
- `response_code` - API response code
- `response_detail` - Error details

```ruby
rescue DkPaymentGateway::InvalidParameterError => e
  puts e.message
  puts e.response_code
  puts e.response_detail
end
```

### TransactionError

Raised when transaction fails.

**Attributes:**
- `response_code` - API response code
- `response_message` - Error message
- `response_description` - Error description
- `response_detail` - Error details

```ruby
rescue DkPaymentGateway::TransactionError => e
  puts e.message
  puts e.response_code
  puts e.response_description
end
```

### NetworkError

Raised when network communication fails.

```ruby
rescue DkPaymentGateway::NetworkError => e
  puts e.message
end
```

### SignatureError

Raised when signature generation fails.

```ruby
rescue DkPaymentGateway::SignatureError => e
  puts e.message
end
```

### APIError

Generic API error (parent of TransactionError).

**Attributes:**
- `response_code`
- `response_message`
- `response_description`
- `response_detail`

```ruby
rescue DkPaymentGateway::APIError => e
  puts e.message
  puts e.response_code
end
```

