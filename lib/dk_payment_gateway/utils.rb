# frozen_string_literal: true

require "securerandom"
require "time"

module DkPaymentGateway
  module Utils
    # Generate a unique request ID
    # @param prefix [String] Optional prefix for the request ID
    # @return [String] Unique request ID
    def self.generate_request_id(prefix = "REQ")
      "#{prefix}_#{Time.now.to_i}_#{SecureRandom.hex(6)}"
    end

    # Generate ISO 8601 timestamp
    # @param time [Time] Optional time object (defaults to current time)
    # @return [String] ISO 8601 formatted timestamp
    def self.generate_timestamp(time = Time.now)
      time.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    end

    # Validate account number format
    # @param account_number [String] Account number to validate
    # @return [Boolean] True if valid format
    def self.valid_account_number?(account_number)
      return false if account_number.nil? || account_number.empty?
      
      # Account numbers should be numeric and between 8-15 digits
      account_number.to_s.match?(/^\d{8,15}$/)
    end

    # Validate phone number format (Bhutan)
    # @param phone_number [String] Phone number to validate
    # @return [Boolean] True if valid format
    def self.valid_phone_number?(phone_number)
      return false if phone_number.nil? || phone_number.empty?
      
      # Bhutan phone numbers are typically 8 digits
      phone_number.to_s.match?(/^\d{8}$/)
    end

    # Validate email format
    # @param email [String] Email to validate
    # @return [Boolean] True if valid format
    def self.valid_email?(email)
      return false if email.nil? || email.empty?
      
      email.to_s.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    end

    # Validate amount
    # @param amount [Numeric] Amount to validate
    # @return [Boolean] True if valid
    def self.valid_amount?(amount)
      return false if amount.nil?
      
      amount.is_a?(Numeric) && amount >= 0
    end

    # Format amount to 2 decimal places
    # @param amount [Numeric] Amount to format
    # @return [String] Formatted amount
    def self.format_amount(amount)
      format("%.2f", amount.to_f)
    end

    # Validate date format (YYYY-MM-DD)
    # @param date_string [String] Date string to validate
    # @return [Boolean] True if valid format
    def self.valid_date_format?(date_string)
      return false if date_string.nil? || date_string.empty?
      
      date_string.to_s.match?(/^\d{4}-\d{2}-\d{2}$/)
    end

    # Parse date string
    # @param date_string [String] Date string in YYYY-MM-DD format
    # @return [Date, nil] Parsed date or nil if invalid
    def self.parse_date(date_string)
      return nil unless valid_date_format?(date_string)
      
      Date.parse(date_string)
    rescue ArgumentError
      nil
    end

    # Sanitize string for API request
    # @param str [String] String to sanitize
    # @return [String] Sanitized string
    def self.sanitize_string(str)
      return "" if str.nil?
      
      str.to_s.strip
    end

    # Mask sensitive data for logging
    # @param data [String] Sensitive data to mask
    # @param visible_chars [Integer] Number of characters to show at start and end
    # @return [String] Masked string
    def self.mask_sensitive(data, visible_chars = 4)
      return "" if data.nil? || data.empty?
      
      data_str = data.to_s
      return data_str if data_str.length <= visible_chars * 2
      
      "#{data_str[0...visible_chars]}#{'*' * (data_str.length - visible_chars * 2)}#{data_str[-visible_chars..]}"
    end

    # Bank codes mapping
    BANK_CODES = {
      "1010" => "Bank of Bhutan",
      "1040" => "Bhutan National Bank",
      "1060" => "Digital Kidu",
      "1070" => "Druk PNB Bank",
      "1080" => "T Bank"
    }.freeze

    # Get bank name from code
    # @param bank_code [String] Bank code
    # @return [String, nil] Bank name or nil if not found
    def self.bank_name(bank_code)
      BANK_CODES[bank_code.to_s]
    end

    # Validate bank code
    # @param bank_code [String] Bank code to validate
    # @return [Boolean] True if valid
    def self.valid_bank_code?(bank_code)
      BANK_CODES.key?(bank_code.to_s)
    end

    # Common MCC codes
    MCC_CODES = {
      "5411" => "Grocery Stores, Supermarkets",
      "5812" => "Eating Places, Restaurants",
      "5999" => "Miscellaneous and Specialty Retail Stores",
      "5814" => "Fast Food Restaurants",
      "5912" => "Drug Stores and Pharmacies",
      "5311" => "Department Stores",
      "5541" => "Service Stations",
      "5732" => "Electronics Stores",
      "5942" => "Book Stores",
      "5945" => "Hobby, Toy, and Game Shops"
    }.freeze

    # Get MCC description
    # @param mcc_code [String] MCC code
    # @return [String, nil] MCC description or nil if not found
    def self.mcc_description(mcc_code)
      MCC_CODES[mcc_code.to_s]
    end

    # Validate MCC code format
    # @param mcc_code [String] MCC code to validate
    # @return [Boolean] True if valid format (4 digits)
    def self.valid_mcc_format?(mcc_code)
      mcc_code.to_s.match?(/^\d{4}$/)
    end
  end
end

