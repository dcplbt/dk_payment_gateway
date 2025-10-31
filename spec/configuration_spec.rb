# frozen_string_literal: true

RSpec.describe DkPaymentGateway::Configuration do
  subject(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.base_url).to eq("http://internal-gateway.uat.digitalkidu.bt/api/dkpg")
      expect(config.source_app).to eq("SRC_AVS_0201")
      expect(config.timeout).to eq(30)
      expect(config.open_timeout).to eq(10)
    end
  end

  describe "#valid?" do
    context "when all required fields are set" do
      before do
        config.api_key = "test_key"
        config.username = "test_user"
        config.password = "test_pass"
        config.client_id = "test_client_id"
        config.client_secret = "test_secret"
      end

      it "returns true" do
        expect(config.valid?).to be true
      end
    end

    context "when required fields are missing" do
      it "returns false" do
        expect(config.valid?).to be false
      end
    end
  end

  describe "#missing_fields" do
    it "returns array of missing required fields" do
      missing = config.missing_fields
      expect(missing).to include(:api_key, :username, :password, :client_id, :client_secret)
    end

    it "returns empty array when all fields are set" do
      config.api_key = "test_key"
      config.username = "test_user"
      config.password = "test_pass"
      config.client_id = "test_client_id"
      config.client_secret = "test_secret"

      expect(config.missing_fields).to be_empty
    end
  end
end

