# frozen_string_literal: true

# Value Object for opaque URL-safe Secret Link tokens (`/s/:share_token`).
# Traceability: [REQ-WISH-002], [REQ-WISH-006]
class ShareToken
  TOKEN_BYTE_LENGTH = 24
  URL_SAFE_PATTERN = /\A[A-Za-z0-9\-_]+\z/
  MIN_LENGTH = 22

  attr_reader :value

  # [REQ-WISH-002] [REQ-WISH-006] Generates a cryptographically opaque URL-safe token.
  def self.generate
    new(SecureRandom.urlsafe_base64(TOKEN_BYTE_LENGTH))
  end

  # [REQ-WISH-006] Pre-condition: raw token must be non-blank URL-safe.
  # Post-condition: @value is frozen and matches URL_SAFE_PATTERN.
  def initialize(raw_token)
    cleaned = raw_token.to_s.strip
    raise ArgumentError, "Invalid share_token: cannot be blank" if cleaned.empty?
    raise ArgumentError, "Invalid share_token: must be URL-safe" unless cleaned.match?(URL_SAFE_PATTERN)
    raise ArgumentError, "Invalid share_token: too short" if cleaned.length < MIN_LENGTH

    @value = cleaned.freeze
    raise "Post-condition failed: share_token must be frozen URL-safe" unless @value.frozen? && @value.match?(URL_SAFE_PATTERN)
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
