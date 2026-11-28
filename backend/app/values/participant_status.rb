# frozen_string_literal: true

# Value Object for activity participant status.
# Traceability: [REQ-ACT-001]
class ParticipantStatus
  ALLOWED = %w[invited accepted declined left].freeze

  attr_reader :value

  def initialize(raw)
    normalized = raw.to_s.strip.downcase
    raise ArgumentError, "Invalid participant status: must be one of #{ALLOWED.join(', ')}" unless ALLOWED.include?(normalized)

    @value = normalized.freeze
  end

  def invited?
    value == "invited"
  end

  def accepted?
    value == "accepted"
  end

  def declined?
    value == "declined"
  end

  def left?
    value == "left"
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
