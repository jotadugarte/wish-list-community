# frozen_string_literal: true

# Value Object for activity assignment mode.
# Traceability: [REQ-ACT-001]
class AssignmentMode
  ALLOWED = %w[secret_santa open_gifting].freeze

  attr_reader :value

  def initialize(raw)
    normalized = raw.to_s.strip.downcase
    raise ArgumentError, "Invalid assignment_mode: must be one of #{ALLOWED.join(', ')}" unless ALLOWED.include?(normalized)

    @value = normalized.freeze
  end

  def secret_santa?
    value == "secret_santa"
  end

  def open_gifting?
    value == "open_gifting"
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
