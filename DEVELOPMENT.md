# Development Guide

Guide for developers working on the DK Payment Gateway gem.

## Setup Development Environment

### Prerequisites

- Ruby >= 2.7.0
- Bundler

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/dk_payment_gateway.git
cd dk_payment_gateway

# Install dependencies
bundle install
```

## Project Structure

```
dk_payment_gateway/
├── lib/
│   ├── dk_payment_gateway/
│   │   ├── authentication.rb      # Token and key fetching
│   │   ├── client.rb              # Main client class
│   │   ├── configuration.rb       # Configuration management
│   │   ├── errors.rb              # Custom exceptions
│   │   ├── intra_transaction.rb   # Intra-bank operations
│   │   ├── pull_payment.rb        # Pull payment operations
│   │   ├── qr_payment.rb          # QR code generation
│   │   ├── signature.rb           # Request signing
│   │   ├── transaction_status.rb  # Status verification
│   │   └── version.rb             # Gem version
│   └── dk_payment_gateway.rb      # Main entry point
├── spec/
│   ├── configuration_spec.rb      # Configuration tests
│   ├── dk_payment_gateway_spec.rb # Main module tests
│   └── spec_helper.rb             # Test configuration
├── API_REFERENCE.md               # Complete API documentation
├── CHANGELOG.md                   # Version history
├── EXAMPLES.md                    # Usage examples
├── QUICK_START.md                 # Quick start guide
├── README.md                      # Main documentation
├── Gemfile                        # Dependencies
├── Rakefile                       # Rake tasks
└── dk_payment_gateway.gemspec     # Gem specification
```

## Running Tests

### Run all tests

```bash
bundle exec rspec
```

### Run specific test file

```bash
bundle exec rspec spec/configuration_spec.rb
```

### Run with coverage

```bash
COVERAGE=true bundle exec rspec
```

## Code Style

This project uses RuboCop for code style enforcement.

```bash
# Check code style
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a
```

## Testing Against Live API

### Setup Test Credentials

Create a `.env.test` file:

```bash
DK_BASE_URL=https://internal-gateway.uat.digitalkidu.bt/api/dkpg
DK_API_KEY=your_test_api_key
DK_USERNAME=your_test_username
DK_PASSWORD=your_test_password
DK_CLIENT_ID=your_test_client_id
DK_CLIENT_SECRET=your_test_client_secret
DK_SOURCE_APP=SRC_AVS_0201
```

### Manual Testing Script

Create `test_script.rb`:

```ruby
require 'bundler/setup'
require 'dk_payment_gateway'
require 'dotenv/load'

# Configure
DkPaymentGateway.configure do |config|
  config.base_url = ENV['DK_BASE_URL']
  config.api_key = ENV['DK_API_KEY']
  config.username = ENV['DK_USERNAME']
  config.password = ENV['DK_PASSWORD']
  config.client_id = ENV['DK_CLIENT_ID']
  config.client_secret = ENV['DK_CLIENT_SECRET']
  config.source_app = ENV['DK_SOURCE_APP']
end

# Test authentication
client = DkPaymentGateway.client
puts "Authenticating..."
client.authenticate!
puts "✓ Authentication successful"

# Test other operations...
```

Run with:

```bash
ruby test_script.rb
```

## Adding New Features

### 1. Create Feature Branch

```bash
git checkout -b feature/new-feature-name
```

### 2. Implement Feature

Add your implementation in the appropriate file under `lib/dk_payment_gateway/`.

### 3. Add Tests

Create or update test files in `spec/`.

```ruby
# spec/new_feature_spec.rb
RSpec.describe DkPaymentGateway::NewFeature do
  describe "#method_name" do
    it "does something" do
      # Test implementation
    end
  end
end
```

### 4. Update Documentation

- Update README.md with usage examples
- Add to API_REFERENCE.md
- Update CHANGELOG.md

### 5. Run Tests

```bash
bundle exec rspec
bundle exec rubocop
```

### 6. Commit and Push

```bash
git add .
git commit -m "Add new feature: description"
git push origin feature/new-feature-name
```

## Debugging

### Enable Debug Logging

```ruby
# Add to client.rb connection method
conn.response :logger, Logger.new(STDOUT), bodies: true
```

### Inspect Requests

```ruby
# Use Faraday middleware
conn.use Faraday::Response::Logger
```

### Debug Signature Generation

```ruby
# In signature.rb, add debugging
def sign_request(request_body, timestamp, nonce)
  puts "Request Body: #{request_body.inspect}"
  puts "Timestamp: #{timestamp}"
  puts "Nonce: #{nonce}"

  # ... rest of method
end
```

## Common Development Tasks

### Update Version

Edit `lib/dk_payment_gateway/version.rb`:

```ruby
module DkPaymentGateway
  VERSION = "0.2.0"
end
```

Update CHANGELOG.md with changes.

### Build Gem

```bash
gem build dk_payment_gateway.gemspec
```

### Install Locally

```bash
gem install ./dk_payment_gateway-0.1.0.gem
```

### Publish to RubyGems

```bash
# First time setup
gem signin

# Publish
gem push dk_payment_gateway-0.1.0.gem
```

## Troubleshooting

### Issue: Authentication Fails

**Check:**

- Credentials are correct
- API key is valid
- Network connectivity to API endpoint

**Debug:**

```ruby
begin
  client.authenticate!
rescue DkPaymentGateway::AuthenticationError => e
  puts "Error: #{e.message}"
  puts "Check credentials and API endpoint"
end
```

### Issue: Signature Validation Fails

**Check:**

- Private key is correctly fetched
- Request body is properly serialized
- Timestamp is in correct format

**Debug:**

```ruby
# Enable signature debugging
signature = DkPaymentGateway::Signature.new(private_key)
headers = signature.generate_headers(request_body)
puts "Signature Headers: #{headers.inspect}"
```

### Issue: Network Timeouts

**Solution:**
Increase timeout values:

```ruby
DkPaymentGateway.configure do |config|
  # ... other config
  config.timeout = 60
  config.open_timeout = 30
end
```

## Best Practices

### 1. Error Handling

Always wrap API calls in error handling:

```ruby
begin
  result = client.pull_payment.authorize(params)
rescue DkPaymentGateway::Error => e
  # Handle error appropriately
  logger.error("Payment failed: #{e.message}")
  # Notify user, retry, or rollback
end
```

### 2. Request IDs

Generate unique request IDs:

```ruby
request_id = "#{operation}_#{Time.now.to_i}_#{SecureRandom.hex(4)}"
```

### 3. Logging

Log important operations:

```ruby
logger.info("Initiating payment: #{transaction_id}")
result = client.pull_payment.authorize(params)
logger.info("Payment authorized: #{result['bfs_txn_id']}")
```

### 4. Testing

Mock external API calls in tests:

```ruby
RSpec.describe "Payment" do
  before do
    stub_request(:post, /.*\/v1\/account_auth\/pull-payment/)
      .to_return(status: 200, body: mock_response.to_json)
  end

  it "processes payment" do
    # Test implementation
  end
end
```

### 5. Configuration

Use environment variables for sensitive data:

```ruby
# Never commit credentials
# Use .env files (add to .gitignore)
# Use environment-specific configs
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Write tests for your changes
4. Ensure all tests pass
5. Update documentation
6. Submit a pull request

## Resources

- [Faraday Documentation](https://lostisland.github.io/faraday/)
- [JWT Ruby Gem](https://github.com/jwt/ruby-jwt)
- [RSpec Documentation](https://rspec.info/)
- [RuboCop Documentation](https://docs.rubocop.org/)

## Support

For development questions or issues:

- Check existing issues on GitHub
- Review documentation
- Contact the development team
