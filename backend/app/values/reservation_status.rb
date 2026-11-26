# frozen_string_literal: true

# Value Object for secret reservation lifecycle statuses (Sprint 5 subset).
# Traceability: [REQ-RES-001], [REQ-RES-006]
class ReservationStatus
  ALLOWED = %w[active expired_grace auto_released canceled].freeze
  ACTIVE_HOLD = %w[active expired_grace].freeze

  attr_reader :value

  # [REQ-RES-001] Pre-condition: raw normalizes to an allowed S5 status.
  # Post-condition: @value is a frozen allowed status string.
  def initialize(raw_status)
    normalized = raw_status.to_s.strip.downcase
    raise ArgumentError, "Invalid reservation status: #{raw_status}" unless ALLOWED.include?(normalized)

    @value = normalized.freeze
    raise "Post-condition failed: status must be frozen allowed value" unless @value.frozen? && ALLOWED.include?(@value)
  end

  def active_hold?
    ACTIVE_HOLD.include?(value)
  end

  def ==(other)
    other.is_a?(self.class) && value == other.value
  end
  alias eql? ==

  def hash
    value.hash
  end

  def to_s
    value
  end
end
