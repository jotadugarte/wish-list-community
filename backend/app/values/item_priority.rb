# frozen_string_literal: true

# Value Object for item desire levels.
# Traceability: [REQ-ITEM-003]
class ItemPriority
  ALLOWED = %w[low medium high must_have].freeze
  DEFAULT = "medium"

  attr_reader :value

  # [REQ-ITEM-003] Pre-condition: raw normalizes to an allowed priority.
  # Post-condition: @value is a frozen allowed priority string.
  def initialize(raw_priority)
    normalized = raw_priority.to_s.strip.downcase
    raise ArgumentError, "Invalid priority: must be low, medium, high, or must_have" unless ALLOWED.include?(normalized)

    @value = normalized.freeze
    raise "Post-condition failed: priority must be frozen allowed value" unless @value.frozen? && ALLOWED.include?(@value)
  end

  # [REQ-ITEM-003] Default desire level for new items.
  def self.default
    new(DEFAULT)
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
