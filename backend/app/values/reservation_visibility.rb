# frozen_string_literal: true

# Value Object for reservation visibility within an activity.
# Traceability: [REQ-ACT-001]
class ReservationVisibility
  ALLOWED = %w[hidden_from_recipient visible_to_recipient].freeze

  attr_reader :value

  def initialize(raw)
    normalized = raw.to_s.strip.downcase
    raise ArgumentError, "Invalid reservation_visibility: must be one of #{ALLOWED.join(', ')}" unless ALLOWED.include?(normalized)

    @value = normalized.freeze
  end

  def to_s
    value
  end

  def visible_to_recipient?
    value == "visible_to_recipient"
  end

  def hidden_from_recipient?
    value == "hidden_from_recipient"
  end
end
