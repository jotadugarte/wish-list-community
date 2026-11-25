# frozen_string_literal: true

# Value Object wrapping and validating a user or wishlist abuse report reason.
# Traceability: [REQ-SOC-001], [REQ-DISC-001]
class ReportReason
  ALLOWED_REASONS = %w[
    spam
    harassment
    impersonation
    inappropriate_content
    scam
  ].freeze

  attr_reader :value

  # [REQ-SOC-001] [REQ-DISC-001] Pre-condition: raw_reason must belong to ALLOWED_REASONS.
  # Post-condition: @value is frozen and present in ALLOWED_REASONS.
  def initialize(raw_reason)
    normalized = raw_reason.to_s.strip.downcase
    unless ALLOWED_REASONS.include?(normalized)
      raise ArgumentError, "Invalid report reason '#{normalized}'. Allowed: #{ALLOWED_REASONS.join(', ')}"
    end

    @value = normalized.freeze
    raise "Post-condition failed: report reason must be frozen" unless @value.frozen?
  end

  # [REQ-SOC-001] [REQ-DISC-001] Canonical string representation.
  def to_s
    value
  end

  # [REQ-SOC-001] [REQ-DISC-001] Value equality comparison.
  def ==(other)
    other.is_a?(self.class) && value == other.value
  end
  alias eql? ==

  def hash
    value.hash
  end
end
