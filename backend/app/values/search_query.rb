# frozen_string_literal: true

# Value Object wrapping and validating an @username prefix search query.
# Traceability: [REQ-SOC-001], [REQ-WISH-001]
class SearchQuery
  MIN_LENGTH = 2
  MAX_LENGTH = 30
  FORMAT_REGEX = /\A[a-z0-9_.]+\z/

  attr_reader :value

  # [REQ-SOC-001] Pre-condition: raw_query must normalize to 2..30 safe handle characters.
  # Post-condition: @value is frozen, lowercase, and non-empty.
  def initialize(raw_query)
    normalized = raw_query.to_s.strip.sub(/\A@+/, "").downcase
    validate_length!(normalized)
    validate_format!(normalized)

    @value = normalized.freeze
    raise "Post-condition failed: search query value must be frozen" unless @value.frozen?
  end

  # [REQ-SOC-001] Returns the normalized search query string.
  def to_s
    value
  end

  # [REQ-SOC-001] Returns an SQL LIKE prefix pattern with wildcards safely escaped.
  def prefix_pattern
    escaped = ActiveRecord::Base.sanitize_sql_like(value)
    "#{escaped}%"
  end

  # [REQ-SOC-001] Value equality comparison.
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

    raise ArgumentError, "Search query length must be between #{MIN_LENGTH} and #{MAX_LENGTH} characters"
  end

  def validate_format!(candidate)
    return if candidate.match?(FORMAT_REGEX)

    raise ArgumentError, "Search query format only allows lowercase letters, numbers, underscores, and dots"
  end
end
