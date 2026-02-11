# frozen_string_literal: true

# Ensure Active Record encryption has keys in local/test environments.
# Production should provide explicit credentials for key rotation control.
if Rails.application.config.active_record.encryption.primary_key.blank?
  base_secret =
    ENV["ACTIVE_RECORD_ENCRYPTION_KEY"].to_s.presence ||
    Rails.application.credentials.secret_key_base.to_s.presence ||
    Rails.application.secret_key_base.to_s

  generator = ActiveSupport::KeyGenerator.new(base_secret, iterations: 1000)
  key_len = ActiveSupport::MessageEncryptor.key_len

  Rails.application.config.active_record.encryption.primary_key = generator.generate_key("ar_primary_key", key_len).unpack1("H*")
  Rails.application.config.active_record.encryption.deterministic_key = generator.generate_key("ar_deterministic_key", key_len).unpack1("H*")
  Rails.application.config.active_record.encryption.key_derivation_salt = generator.generate_key("ar_key_derivation_salt", key_len).unpack1("H*")
end
