# frozen_string_literal: true

# Value Object for activity lifecycle status.
# Traceability: [REQ-ACT-001]
class ActivityStatus
  ALLOWED = %w[open sealed cancelled].freeze

  attr_reader :value

  def initialize(raw)
    normalized = raw.to_s.strip.downcase
    raise ArgumentError, "Invalid activity status: must be one of #{ALLOWED.join(', ')}" unless ALLOWED.include?(normalized)

    @value = normalized.freeze
  end

  def open?
    value == "open"
  end

  def sealed?
    value == "sealed"
  end

  def cancelled?
    value == "cancelled"
  end

  def ==(other)
    other.is_a?(self.class) && other.value == value
  end

  alias eql? ==

  def hash
    value.hash
  end

  def to_s
    value
  end
end
