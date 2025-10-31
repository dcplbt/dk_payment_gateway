# frozen_string_literal: true

require_relative "lib/dk_payment_gateway/version"

Gem::Specification.new do |spec|
  spec.name = "dk_payment_gateway"
  spec.version = DkPaymentGateway::VERSION
  spec.authors = ["Your Name"]
  spec.email = ["your.email@example.com"]

  spec.summary = "Ruby client for DK Payment Gateway API"
  spec.description = "A Ruby gem for integrating with Digital Kidu Payment Gateway API, supporting pull payments, intra-bank transactions, QR generation, and transaction status verification."
  spec.homepage = "https://github.com/yourusername/dk_payment_gateway"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yourusername/dk_payment_gateway"
  spec.metadata["changelog_uri"] = "https://github.com/yourusername/dk_payment_gateway/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "jwt", "~> 2.7"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "vcr", "~> 6.1"
end

