# frozen_string_literal: true

# Value Object for gift fulfillment lifecycle statuses (Sprint 6).
# Traceability: [REQ-GIFT-001], [REQ-GIFT-002]
class GiftStatus
  ALLOWED = %w[
    purchased_secret
    delivered_pending_confirmation
    received_confirmed
    voided
  ].freeze
  OPEN = %w[purchased_secret delivered_pending_confirmation].freeze

  attr_reader :value

  # [REQ-GIFT-001] Pre-condition: raw normalizes to an allowed gift status.
  # Post-condition: @value is a frozen allowed status string.
  def initialize(raw_status)
    normalized = raw_status.to_s.strip.downcase
    raise ArgumentError, "Invalid gift status: #{raw_status}" unless ALLOWED.include?(normalized)

    @value = normalized.freeze
    raise "Post-condition failed: status must be frozen allowed value" unless @value.frozen? && ALLOWED.include?(@value)
  end

  def open?
    OPEN.include?(value)
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
