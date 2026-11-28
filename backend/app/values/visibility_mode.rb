# frozen_string_literal: true

# Value Object for activity board visibility.
# Traceability: [REQ-ACT-001]
class VisibilityMode
  ALLOWED = %w[recipient_only all_participants].freeze

  attr_reader :value

  def initialize(raw)
    normalized = raw.to_s.strip.downcase
    raise ArgumentError, "Invalid visibility_mode: must be one of #{ALLOWED.join(', ')}" unless ALLOWED.include?(normalized)

    @value = normalized.freeze
  end

  def to_s
    value
  end
end
