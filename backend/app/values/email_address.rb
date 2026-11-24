# frozen_string_literal: true

# Value Object wrapping and validating a user's private email address.
# Traceability: [REQ-USER-001], [REQ-AUTH-001]
class EmailAddress
  EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
  REDACTED_LABEL = "[REDACTED_EMAIL]"

  attr_reader :value

  # [REQ-USER-001] Pre-condition: raw_email must be a valid email format after normalization.
  # Post-condition: @value is frozen, stripped, and lowercase.
  def initialize(raw_email)
    normalized = raw_email.to_s.strip.downcase
    raise ArgumentError, "Invalid email address format" unless normalized.match?(EMAIL_REGEX)

    @value = normalized.freeze
    raise "Post-condition failed: email value must be frozen lowercase" unless @value.frozen? && @value == normalized
  end

  # [REQ-USER-001] Redacts raw email in string interpolation / logs to prevent accidental PII leaks.
  def to_s
    REDACTED_LABEL
  end

  # [REQ-USER-001] Redacts raw email in debug inspect output.
  def inspect
    "#<#{self.class.name} #{REDACTED_LABEL}>"
  end

  # [REQ-USER-001] Value equality comparison.
  def ==(other)
    other.is_a?(self.class) && value == other.value
  end
  alias eql? ==

  def hash
    value.hash
  end
end
