# frozen_string_literal: true

# Value Object for an optional anonymous thank-you note from owner to gifter.
# Traceability: [REQ-GIFT-004]
class ThankYouNote
  MAX_LENGTH = 500

  attr_reader :value

  # [REQ-GIFT-004] Pre-condition: raw is non-blank and ≤ MAX_LENGTH after strip.
  # Post-condition: @value is a frozen non-blank string.
  def initialize(raw_note)
    normalized = raw_note.to_s.strip
    raise ArgumentError, "thank_you_note cannot be blank" if normalized.empty?
    raise ArgumentError, "thank_you_note too long" if normalized.length > MAX_LENGTH

    @value = normalized.freeze
    raise "Post-condition failed: value must be frozen non-blank" unless @value.frozen? && !@value.empty?
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
