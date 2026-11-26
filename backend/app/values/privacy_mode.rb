# frozen_string_literal: true

# Value Object for personal wishlist privacy modes (friends | shared).
# Traceability: [REQ-WISH-001]
class PrivacyMode
  ALLOWED = %w[friends shared].freeze

  attr_reader :value

  # [REQ-WISH-001] Pre-condition: raw mode must normalize to friends or shared.
  # Post-condition: @value is a frozen allowed mode string.
  def initialize(raw_mode)
    normalized = raw_mode.to_s.strip.downcase
    raise ArgumentError, "Invalid privacy_mode: must be friends or shared" unless ALLOWED.include?(normalized)

    @value = normalized.freeze
    raise "Post-condition failed: privacy_mode must be frozen allowed value" unless @value.frozen? && ALLOWED.include?(@value)
  end

  def friends?
    value == "friends"
  end

  def shared?
    value == "shared"
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
