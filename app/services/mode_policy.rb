# frozen_string_literal: true

# Validates and normalizes mode-related session inputs.
class ModePolicy
  def self.normalize(mode:, target_type:, target_data:)
    safe_mode = mode.to_s.presence
    safe_mode = "profile_builder" unless ArchitectSession::MODES.include?(safe_mode)

    safe_target_type = target_type.to_s.presence
    safe_target_type = nil unless ArchitectSession::TARGET_TYPES.include?(safe_target_type)

    safe_target_data = target_data.is_a?(Hash) ? target_data : {}

    { mode: safe_mode, target_type: safe_target_type, target_data: safe_target_data }
  end

  def self.validate!(mode:, target_type:, target_data:)
    normalized = normalize(mode:, target_type:, target_data:)

    unless ArchitectSession::MODES.include?(normalized[:mode])
      raise ArgumentError, "Unsupported mode: #{normalized[:mode]}"
    end

    if normalized[:target_type].present? && !ArchitectSession::TARGET_TYPES.include?(normalized[:target_type])
      raise ArgumentError, "Unsupported target_type: #{normalized[:target_type]}"
    end

    unless normalized[:target_data].is_a?(Hash)
      raise ArgumentError, "target_data must be a Hash"
    end

    normalized
  end
end
