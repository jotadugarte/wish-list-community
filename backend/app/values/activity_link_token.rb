# frozen_string_literal: true

# Value Object for opaque URL-safe Activity Link tokens.
# Traceability: [REQ-ACT-001]
class ActivityLinkToken
  TOKEN_BYTE_LENGTH = 24
  URL_SAFE_PATTERN = /\A[A-Za-z0-9\-_]+\z/
  MIN_LENGTH = 22

  attr_reader :value

  # [REQ-ACT-001] Generates a cryptographically opaque URL-safe token.
  def self.generate
    new(SecureRandom.urlsafe_base64(TOKEN_BYTE_LENGTH))
  end

  # [REQ-ACT-001] Pre-condition: raw token must be non-blank URL-safe.
  # Post-condition: @value is frozen and matches URL_SAFE_PATTERN.
  def initialize(raw_token)
    cleaned = raw_token.to_s.strip
    raise ArgumentError, "Invalid activity_link_token: cannot be blank" if cleaned.empty?
    raise ArgumentError, "Invalid activity_link_token: must be URL-safe" unless cleaned.match?(URL_SAFE_PATTERN)
    raise ArgumentError, "Invalid activity_link_token: too short" if cleaned.length < MIN_LENGTH

    @value = cleaned.freeze
    raise "Post-condition failed: activity_link_token must be frozen URL-safe" unless @value.frozen? && @value.match?(URL_SAFE_PATTERN)
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
