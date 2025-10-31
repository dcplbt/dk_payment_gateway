# frozen_string_literal: true

RSpec.describe DkPaymentGateway do
  it "has a version number" do
    expect(DkPaymentGateway::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields configuration" do
      expect { |b| DkPaymentGateway.configure(&b) }.to yield_with_args(DkPaymentGateway::Configuration)
    end

    it "sets configuration" do
      DkPaymentGateway.configure do |config|
        config.api_key = "test_key"
      end

      expect(DkPaymentGateway.configuration.api_key).to eq("test_key")
    end
  end

  describe ".client" do
    before do
      DkPaymentGateway.configure do |config|
        config.base_url = "http://test.example.com"
        config.api_key = "test_key"
        config.username = "test_user"
        config.password = "test_pass"
        config.client_id = "test_client_id"
        config.client_secret = "test_secret"
        config.source_app = "SRC_TEST_0001"
      end
    end

    it "returns a client instance" do
      expect(DkPaymentGateway.client).to be_a(DkPaymentGateway::Client)
    end
  end
end

