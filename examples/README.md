# DK Payment Gateway - Example Applications

This directory contains example applications demonstrating how to use the DK Payment Gateway gem.

## Prerequisites

Before running these examples, make sure you have:

1. Installed the gem:

   ```bash
   gem install dk_payment_gateway
   ```

2. Set up your environment variables in a `.env` file:

   ```bash
   DK_BASE_URL=https://internal-gateway.uat.digitalkidu.bt/api/dkpg
   DK_API_KEY=your_api_key
   DK_USERNAME=your_username
   DK_PASSWORD=your_password
   DK_CLIENT_ID=your_client_id
   DK_CLIENT_SECRET=your_client_secret
   DK_SOURCE_APP=SRC_AVS_0201
   ```

3. Install dotenv gem (optional, for loading .env files):
   ```bash
   gem install dotenv
   ```

## Examples

### 1. Simple Payment (`simple_payment.rb`)

Demonstrates a complete pull payment flow:

- Authentication
- Payment authorization (sends OTP)
- OTP collection from user
- Payment completion with OTP

**Run:**

```bash
ruby examples/simple_payment.rb
```

**What it does:**

1. Authenticates with the API
2. Initiates a payment authorization for BTN 100.00
3. Prompts for OTP
4. Completes the payment

### 2. Intra-Bank Transfer (`intra_transfer.rb`)

Demonstrates transferring funds between DK accounts:

- Account verification
- Fund transfer
- Transaction confirmation

**Run:**

```bash
ruby examples/intra_transfer.rb
```

**What it does:**

1. Authenticates with the API
2. Verifies beneficiary account
3. Asks for confirmation
4. Executes the transfer

### 3. QR Code Generation (`generate_qr.rb`)

Demonstrates generating QR codes for payments:

- Static QR (customer enters amount)
- Dynamic QR (fixed amount)
- QR image saving

**Run:**

```bash
ruby examples/generate_qr.rb
```

**What it does:**

1. Authenticates with the API
2. Asks user to choose QR type
3. Generates QR code
4. Saves QR image to file

## Customizing Examples

### Changing Payment Amounts

Edit the amount variables in each script:

```ruby
# In simple_payment.rb
amount = 100.00  # Change this
fee = 5.00       # Change this

# In intra_transfer.rb
amount = 500.00  # Change this
```

### Changing Account Numbers

Update the account numbers to match your test accounts:

```ruby
# Beneficiary account
account_number: "110158212197"  # Change this

# Remitter account
remitter_account_number: "770182571"  # Change this
```

### Changing Bank Codes

Use different bank codes as needed:

```ruby
remitter_bank_id: "1040"  # 1010, 1040, 1060, etc.
```

## Error Handling

All examples include error handling. If you encounter errors:

1. **Authentication Error**

   - Check your credentials in .env file
   - Verify API endpoint is accessible

2. **Transaction Error**

   - Check account numbers are valid
   - Verify sufficient balance
   - Ensure OTP is correct

3. **Network Error**
   - Check internet connection
   - Verify API endpoint URL

## Testing in Development

For testing without affecting real accounts:

1. Use the UAT (User Acceptance Testing) environment
2. Use test account numbers provided by DK
3. Use small amounts for testing

## Creating Your Own Examples

Use these examples as templates:

```ruby
#!/usr/bin/env ruby
require 'bundler/setup'
require 'dk_payment_gateway'

# Configure
DkPaymentGateway.configure do |config|
  config.base_url = ENV['DK_BASE_URL']
  config.api_key = ENV['DK_API_KEY']
  # ... other config
end

# Your code here
client = DkPaymentGateway.client
client.authenticate!

# Use the client
# ...
```

## Additional Resources

- [Main README](../README.md) - Complete documentation
- [Quick Start Guide](../QUICK_START.md) - Get started in 5 minutes
- [API Reference](../API_REFERENCE.md) - Detailed API documentation
- [Examples Guide](../EXAMPLES.md) - More usage examples

## Support

If you encounter issues with these examples:

1. Check the error message
2. Review the documentation
3. Verify your credentials
4. Check account numbers and amounts
5. Ensure you're using the correct environment (UAT/Production)

## Security Note

⚠️ **Never commit your `.env` file or credentials to version control!**

Add to your `.gitignore`:

```
.env
.env.*
*.pem
*.key
```
