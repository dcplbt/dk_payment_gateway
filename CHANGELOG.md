# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-10-31

### Added
- Initial release of DK Payment Gateway Ruby gem
- Authentication module for token and RSA key management
- Signature generation using RS256 algorithm
- Pull payment support (authorization and debit)
- Intra-bank transaction support (account inquiry and fund transfer)
- QR code generation (static and dynamic)
- Transaction status verification (current day and historical)
- Comprehensive error handling with custom exception classes
- Configuration management
- Full documentation and usage examples

### Features
- **Authentication**
  - Fetch authorization token with configurable scopes
  - Retrieve RSA private key for request signing
  
- **Pull Payment**
  - Payment gateway authorization with OTP request
  - Debit request with OTP verification
  - STAN number generation utility
  
- **Intra-Bank Transactions**
  - Beneficiary account inquiry
  - Fund transfer between DK accounts
  
- **QR Payments**
  - Static QR generation (customer enters amount)
  - Dynamic QR generation (fixed amount)
  - QR image saving utility
  
- **Transaction Status**
  - Current day transaction status check
  - Historical transaction status check
  
- **Error Handling**
  - ConfigurationError
  - AuthenticationError
  - InvalidParameterError
  - TransactionError
  - NetworkError
  - SignatureError
  - APIError

### Dependencies
- faraday ~> 2.0 (HTTP client)
- jwt ~> 2.7 (JWT encoding for signatures)

### Development Dependencies
- rake ~> 13.0
- rspec ~> 3.0
- webmock ~> 3.18
- vcr ~> 6.1
- rubocop ~> 1.21

