# frozen_string_literal: true

# Value Object for purchase / store URLs (strict http/https only).
# Traceability: [REQ-ITEM-001], [REQ-ITEM-006]
class ExternalUrl
  ALLOWED_SCHEMES = %w[http https].freeze

  attr_reader :value

  # [REQ-ITEM-001] Pre-condition: raw must parse as http(s) with a host.
  # Post-condition: @value is a frozen absolute http(s) URL string.
  def initialize(raw_url)
    normalized = raw_url.to_s.strip
    raise ArgumentError, "Invalid url: blank" if normalized.empty?

    uri = URI.parse(normalized)
    scheme = uri.scheme.to_s.downcase
    raise ArgumentError, "Invalid url: scheme must be http or https" unless ALLOWED_SCHEMES.include?(scheme)
    raise ArgumentError, "Invalid url: host required" if uri.host.to_s.strip.empty?

    @value = uri.to_s.freeze
    raise "Post-condition failed: value must be frozen http(s) URL" unless @value.frozen? && @value.match?(/\Ahttps?:/i)
  rescue URI::InvalidURIError
    raise ArgumentError, "Invalid url: malformed"
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

  def uri
    URI.parse(value)
  end
end
