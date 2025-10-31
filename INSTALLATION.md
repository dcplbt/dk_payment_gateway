# Installation Guide

Complete installation and setup guide for the DK Payment Gateway Ruby gem.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation Methods](#installation-methods)
3. [Configuration](#configuration)
4. [Verification](#verification)
5. [Troubleshooting](#troubleshooting)

## System Requirements

### Ruby Version

- Ruby >= 2.7.0
- Recommended: Ruby 3.0 or higher

Check your Ruby version:
```bash
ruby -v
```

### Dependencies

The gem will automatically install these dependencies:
- faraday (~> 2.0)
- jwt (~> 2.7)

## Installation Methods

### Method 1: Using Bundler (Recommended)

Add to your `Gemfile`:

```ruby
gem 'dk_payment_gateway'
```

Then run:
```bash
bundle install
```

### Method 2: Using RubyGems

Install directly:
```bash
gem install dk_payment_gateway
```

### Method 3: From Source (Development)

Clone and install from source:

```bash
# Clone the repository
git clone https://github.com/yourusername/dk_payment_gateway.git
cd dk_payment_gateway

# Install dependencies
bundle install

# Build and install the gem
gem build dk_payment_gateway.gemspec
gem install ./dk_payment_gateway-0.1.0.gem
```

## Configuration

### Step 1: Obtain API Credentials

Contact Digital Kidu to obtain:
- API Key (X-gravitee-api-key)
- Username
- Password
- Client ID
- Client Secret
- Source App ID

### Step 2: Set Up Environment Variables

Create a `.env` file in your project root:

```bash
# DK Payment Gateway Configuration
DK_BASE_URL=http://internal-gateway.uat.digitalkidu.bt/api/dkpg
DK_API_KEY=your_api_key_here
DK_USERNAME=your_username_here
DK_PASSWORD=your_password_here
DK_CLIENT_ID=your_client_id_here
DK_CLIENT_SECRET=your_client_secret_here
DK_SOURCE_APP=SRC_AVS_0201
```

**Important:** Add `.env` to your `.gitignore`:
```bash
echo ".env" >> .gitignore
```

### Step 3: Install dotenv (Optional but Recommended)

Add to your `Gemfile`:
```ruby
gem 'dotenv'
```

Then:
```bash
bundle install
```

### Step 4: Configure the Gem

In your application initialization file (e.g., `config/initializers/dk_payment_gateway.rb` for Rails):

```ruby
require 'dotenv/load' # Load environment variables
require 'dk_payment_gateway'

DkPaymentGateway.configure do |config|
  config.base_url = ENV['DK_BASE_URL']
  config.api_key = ENV['DK_API_KEY']
  config.username = ENV['DK_USERNAME']
  config.password = ENV['DK_PASSWORD']
  config.client_id = ENV['DK_CLIENT_ID']
  config.client_secret = ENV['DK_CLIENT_SECRET']
  config.source_app = ENV['DK_SOURCE_APP']
  
  # Optional: Customize timeouts
  config.timeout = 30
  config.open_timeout = 10
end
```

## Verification

### Test Your Installation

Create a test script `test_installation.rb`:

```ruby
require 'dk_payment_gateway'

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

# Test configuration
puts "Testing DK Payment Gateway installation..."
puts

# Check configuration
config = DkPaymentGateway.configuration
if config.valid?
  puts "✓ Configuration is valid"
else
  puts "✗ Configuration is invalid"
  puts "  Missing fields: #{config.missing_fields.join(', ')}"
  exit 1
end

# Test authentication
begin
  client = DkPaymentGateway.client
  puts "✓ Client initialized"
  
  client.authenticate!
  puts "✓ Authentication successful"
  puts
  puts "Installation verified successfully!"
  
rescue DkPaymentGateway::ConfigurationError => e
  puts "✗ Configuration error: #{e.message}"
  exit 1
rescue DkPaymentGateway::AuthenticationError => e
  puts "✗ Authentication error: #{e.message}"
  exit 1
rescue => e
  puts "✗ Unexpected error: #{e.message}"
  exit 1
end
```

Run the test:
```bash
ruby test_installation.rb
```

Expected output:
```
Testing DK Payment Gateway installation...

✓ Configuration is valid
✓ Client initialized
✓ Authentication successful

Installation verified successfully!
```

## Framework-Specific Setup

### Ruby on Rails

1. Add to `Gemfile`:
   ```ruby
   gem 'dk_payment_gateway'
   gem 'dotenv-rails'
   ```

2. Create `config/initializers/dk_payment_gateway.rb`:
   ```ruby
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

3. Use in controllers:
   ```ruby
   class PaymentsController < ApplicationController
     def create
       client = DkPaymentGateway.client
       client.authenticate!
       
       # Your payment logic
     end
   end
   ```

### Sinatra

```ruby
require 'sinatra'
require 'dk_payment_gateway'
require 'dotenv/load'

# Configure
configure do
  DkPaymentGateway.configure do |config|
    config.base_url = ENV['DK_BASE_URL']
    config.api_key = ENV['DK_API_KEY']
    # ... other config
  end
end

# Use in routes
post '/payment' do
  client = DkPaymentGateway.client
  client.authenticate!
  
  # Your payment logic
end
```

### Plain Ruby Script

```ruby
#!/usr/bin/env ruby
require 'bundler/setup'
require 'dk_payment_gateway'
require 'dotenv/load'

DkPaymentGateway.configure do |config|
  config.base_url = ENV['DK_BASE_URL']
  # ... other config
end

client = DkPaymentGateway.client
client.authenticate!

# Your code here
```

## Troubleshooting

### Issue: Gem Not Found

**Error:**
```
Could not find gem 'dk_payment_gateway'
```

**Solution:**
```bash
# Update gem sources
gem sources --update

# Install the gem
gem install dk_payment_gateway

# Or with bundler
bundle update
```

### Issue: LoadError

**Error:**
```
LoadError: cannot load such file -- dk_payment_gateway
```

**Solution:**
```ruby
# Make sure to require the gem
require 'dk_payment_gateway'

# Or in Gemfile
gem 'dk_payment_gateway'
# Then run: bundle install
```

### Issue: Configuration Error

**Error:**
```
DkPaymentGateway::ConfigurationError: Missing required configuration fields
```

**Solution:**
1. Check your `.env` file exists
2. Verify all required fields are set
3. Make sure dotenv is loaded before configuration

```ruby
require 'dotenv/load'  # Add this before configuration
require 'dk_payment_gateway'
```

### Issue: Authentication Failed

**Error:**
```
DkPaymentGateway::AuthenticationError: Token request failed
```

**Solution:**
1. Verify credentials are correct
2. Check API endpoint is accessible
3. Ensure API key is valid
4. Contact DK support if credentials are correct

### Issue: SSL Certificate Error

**Error:**
```
SSL_connect returned=1 errno=0 state=error
```

**Solution:**
```ruby
# For development/testing only - NOT for production
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
```

Better solution: Update SSL certificates
```bash
# On macOS
brew install openssl

# On Ubuntu/Debian
sudo apt-get install ca-certificates
```

### Issue: Timeout Errors

**Error:**
```
DkPaymentGateway::NetworkError: execution expired
```

**Solution:**
Increase timeout values:
```ruby
DkPaymentGateway.configure do |config|
  # ... other config
  config.timeout = 60        # Increase from default 30
  config.open_timeout = 30   # Increase from default 10
end
```

## Environment-Specific Configuration

### Development

```ruby
# config/environments/development.rb
DkPaymentGateway.configure do |config|
  config.base_url = "http://internal-gateway.uat.digitalkidu.bt/api/dkpg"
  # ... UAT credentials
end
```

### Production

```ruby
# config/environments/production.rb
DkPaymentGateway.configure do |config|
  config.base_url = ENV['DK_BASE_URL']  # Production URL
  # ... production credentials from environment
end
```

## Next Steps

After successful installation:

1. Read the [Quick Start Guide](QUICK_START.md)
2. Review [Usage Examples](EXAMPLES.md)
3. Check [API Reference](API_REFERENCE.md)
4. Run example applications in `examples/` directory

## Support

For installation issues:
- Check this troubleshooting guide
- Review the [README](README.md)
- Contact DK support for credential issues
- Open an issue on GitHub for gem-specific problems

