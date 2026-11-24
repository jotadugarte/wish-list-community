# frozen_string_literal: true

require "digest"

# Value Object encapsulating high-entropy bearer token generation and SHA-256 hashing.
# Traceability: [REQ-AUTH-001]
class AuthToken
  TOKEN_BYTE_LENGTH = 32
  REDACTED_LABEL = "[REDACTED_AUTH_TOKEN]"

  attr_reader :raw, :digest

  # [REQ-AUTH-001] Generates a new cryptographically secure token and its SHA-256 digest.
  def self.generate
    new(SecureRandom.base58(TOKEN_BYTE_LENGTH))
  end

  # [REQ-AUTH-001] Wraps an existing raw token to compute its deterministic SHA-256 digest.
  def self.from_raw(raw_token)
    new(raw_token)
  end

  # [REQ-AUTH-001] Pre-condition: raw_token must not be blank.
  # Post-condition: @digest is a 64-character lowercase SHA-256 hex string and never equals @raw.
  def initialize(raw_token)
    cleaned = raw_token.to_s.strip
    raise ArgumentError, "Raw auth token cannot be blank" if cleaned.empty?

    @raw = cleaned.freeze
    @digest = Digest::SHA256.hexdigest(@raw).freeze

    raise "Post-condition failed: SHA-256 digest invalid" unless @digest.length == 64 && @digest != @raw
  end

  # [REQ-AUTH-001] Prevents accidental exposure of raw bearer tokens in logs.
  def to_s
    REDACTED_LABEL
  end

  # [REQ-AUTH-001] Prevents accidental exposure of raw bearer tokens in debug output.
  def inspect
    "#<#{self.class.name} #{REDACTED_LABEL}>"
  end
end
