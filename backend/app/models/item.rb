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

  # [REQ-LIFE-001] Placeholder for Sprint 5: permanently cancel active/grace reservations on soft-delete.
  register_soft_delete_hook(:cancel_active_reservations_noop) do |_item_record|
    # No Reservation model in Sprint 4 — hook keeps registry contract for S5.
  end

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

  # [REQ-ITEM-001] [REQ-RES-002] JSON payload for API clients.
  # Viewer-relative `availability` is included for non-owners only (O3A).
  def as_api_json(viewer: nil)
    payload = {
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
      images: images.attachments.limit(MAX_IMAGES).map { |att| image_as_json(att) },
      created_at: created_at,
      updated_at: updated_at
    }
    return payload if viewer.nil? || viewer.id == wishlist.owner_id

    payload[:availability] = availability_for(viewer)
    payload
  end

  # [REQ-RES-002] O3A: available | reserved_by_me | unavailable (never exposes reserver identity).
  def availability_for(viewer)
    hold = Reservation.find_by(item_id: id, status: ReservationStatus::ACTIVE_HOLD)
    return "available" if hold.nil?
    return "reserved_by_me" if hold.user_id == viewer.id

    "unavailable"
  end

  private

  def image_as_json(attachment)
    {
      id: attachment.id,
      content_type: attachment.blob.content_type,
      byte_size: attachment.blob.byte_size,
      url: Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)
    }
  end

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
