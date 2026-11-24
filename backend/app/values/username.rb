# frozen_string_literal: true

# Value Object wrapping and validating a user's public @username handle.
# Traceability: [REQ-USER-001], [REQ-USER-004]
class Username
  MIN_LENGTH = 3
  MAX_LENGTH = 30
  FORMAT_REGEX = /\A[a-z0-9_]+\z/
  RESERVED_WORDS = %w[
    admin api login logout signup wishlists settings support
    discover activities notifications profile root system help
  ].freeze

  attr_reader :value

  # [REQ-USER-001] Pre-condition: raw_username must meet length, character format, and reserved word constraints.
  # Post-condition: @value is frozen, lowercase, and non-empty.
  def initialize(raw_username)
    normalized = raw_username.to_s.strip.downcase
    validate_length!(normalized)
    validate_format!(normalized)
    validate_not_reserved!(normalized)

    @value = normalized.freeze
    raise "Post-condition failed: username value must be frozen" unless @value.frozen?
  end

  # [REQ-USER-001] Safe to output publicly since @username is the public handle.
  def to_s
    value
  end

  # [REQ-USER-001] Value equality comparison.
  def ==(other)
    other.is_a?(self.class) && value == other.value
  end
  alias eql? ==

  def hash
    value.hash
  end

  private

  def validate_length!(candidate)
    return if candidate.length.between?(MIN_LENGTH, MAX_LENGTH)

    raise ArgumentError, "Username length must be between #{MIN_LENGTH} and #{MAX_LENGTH} characters"
  end

  def validate_format!(candidate)
    return if candidate.match?(FORMAT_REGEX)

    raise ArgumentError, "Username format only allows lowercase letters, numbers, and underscores"
  end

  def validate_not_reserved!(candidate)
    return unless RESERVED_WORDS.include?(candidate)

    raise ArgumentError, "Username '#{candidate}' is a reserved word"
  end
end
