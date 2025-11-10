# frozen_string_literal: true

require 'dk_payment_gateway'
require 'webmock/rspec'
require 'vcr'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset configuration before each test
  config.before(:each) do
    DkPaymentGateway.configuration = nil
  end
end

# VCR configuration for recording HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<API_KEY>') { ENV['DK_API_KEY'] }
  config.filter_sensitive_data('<USERNAME>') { ENV['DK_USERNAME'] }
  config.filter_sensitive_data('<PASSWORD>') { ENV['DK_PASSWORD'] }
  config.filter_sensitive_data('<CLIENT_ID>') { ENV['DK_CLIENT_ID'] }
  config.filter_sensitive_data('<CLIENT_SECRET>') { ENV['DK_CLIENT_SECRET'] }
end
