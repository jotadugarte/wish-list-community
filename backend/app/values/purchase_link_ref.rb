# frozen_string_literal: true

# Value Object for optional admin-only purchase link reference on a GiftRecord.
# Accepts http(s) URLs or opaque item_link:<id> refs. Traceability: [REQ-ADM-001]
class PurchaseLinkRef
  ITEM_LINK_PATTERN = /\Aitem_link:\d+\z/.freeze

  attr_reader :value

  # [REQ-ADM-001] Pre-condition: raw is a non-blank URL or item_link ref.
  # Post-condition: @value is a frozen non-blank string.
  def initialize(raw_ref)
    normalized = raw_ref.to_s.strip
    raise ArgumentError, "purchase_link_ref cannot be blank" if normalized.empty?

    @value = if ITEM_LINK_PATTERN.match?(normalized)
      normalized.freeze
    else
      ExternalUrl.new(normalized).value
    end
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
