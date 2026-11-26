# frozen_string_literal: true

# Single giftable unit inside a Wishlist with media and purchase links.
# Traceability: [REQ-ITEM-001], [REQ-ITEM-002], [REQ-ITEM-003], [REQ-ITEM-005],
# [REQ-ARCH-002], [REQ-LIFE-001]
class Item < ApplicationRecord
  include SoftDeletable

  MAX_IMAGES = 3
  CURRENCY_FORMAT = /\A[A-Z]{3}\z/

  belongs_to :wishlist
  has_many :item_links, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :item
  has_many_attached :images

  before_validation :apply_default_priority, on: :create
  before_validation :normalize_currency
  before_create :assign_append_position

  validates :title, presence: true
  validates :priority, presence: true, inclusion: { in: ItemPriority::ALLOWED }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :price_and_currency_pair
  validate :currency_format_when_present
  validate :images_count_within_limit

  # [REQ-ITEM-003] Priority Value Object for the stored desire level.
  def priority_vo
    ItemPriority.new(priority)
  end

  # [REQ-ITEM-001] JSON payload for API clients (no reservation fields).
  def as_api_json
    {
      id: id,
      wishlist_id: wishlist_id,
      title: title,
      specifications: specifications,
      priority: priority,
      price_cents: price_cents,
      currency: currency,
      position: position,
      discarded_at: discarded_at,
      links: item_links.limit(50).map(&:as_api_json),
      image_ids: images.attachments.limit(MAX_IMAGES).map(&:id),
      created_at: created_at,
      updated_at: updated_at
    }
  end

  private

  def apply_default_priority
    self.priority = ItemPriority.default.value if priority.blank?
  end

  def normalize_currency
    self.currency = currency.to_s.strip.upcase.presence
  end

  def assign_append_position
    return if position_changed? && position.present? && !position.zero? && persisted?

    max_position = wishlist.items.where(discarded_at: nil).maximum(:position)
    self.position = max_position.nil? ? 0 : max_position + 1
  end

  def price_and_currency_pair
    if price_cents.present? ^ currency.present?
      errors.add(:base, "price_cents and currency must both be present or both blank")
    end
  end

  def currency_format_when_present
    return if currency.blank?
    return if currency.match?(CURRENCY_FORMAT)

    errors.add(:currency, "must be a 3-letter ISO code")
  end

  def images_count_within_limit
    return unless images.attached?
    return if images.attachments.size <= MAX_IMAGES

    errors.add(:images, "cannot exceed #{MAX_IMAGES}")
  end
end
