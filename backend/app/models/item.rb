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
  has_many :gift_records, dependent: :restrict_with_exception
  has_many_attached :images

  # [REQ-LIFE-001] Permanently cancel active/grace reservations on soft-delete (no ghosts on restore).
  register_soft_delete_hook(:cancel_active_reservations) do |item_record|
    Reservation
    hold = Reservation.find_by(item_id: item_record.id, status: ReservationStatus::ACTIVE_HOLD)
    Reservation.cancel_active_holds_for_item!(item_record.id)
    Reservation.notify_item_deleted!(reservation: hold) if hold
  end

  # [REQ-LIFE-001] O8D: void open gifts and notify gifter; restore never reopens.
  register_soft_delete_hook(:void_open_gifts) do |item_record|
    GiftRecord
    GiftRecord.void_open_for_item!(item_record.id, notify_gifter: true, actor: item_record.wishlist.owner)
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

  # [REQ-ITEM-001] [REQ-RES-002] [REQ-GIFT-002] JSON for API clients.
  # Viewer-relative `availability` for non-owners only (O3A). Batch maps avoid N+1.
  def as_api_json(viewer: nil, holds_by_item_id: nil, open_gifts_by_item_id: nil,
                  received_gift_ids: nil, pending_confirm_gifts_by_item_id: nil)
    payload = base_api_payload
    payload[:received_gift] = received_gift_flag(received_gift_ids)
    if viewer && viewer.id == wishlist.owner_id
      pending_id = pending_confirm_id(pending_confirm_gifts_by_item_id)
      payload[:pending_confirm_gift_id] = pending_id if pending_id
      return payload
    end
    return payload if viewer.nil?

    payload[:availability] = availability_for(
      viewer,
      holds_by_item_id: holds_by_item_id,
      open_gifts_by_item_id: open_gifts_by_item_id
    )
    payload
  end

  # [REQ-RES-002] [REQ-GIFT-002] O3A/FC2: available | reserved_by_me | unavailable.
  # Blocks on active/grace hold OR open GiftRecord; gifter sees reserved_by_me for their open gift.
  def availability_for(viewer, holds_by_item_id: nil, open_gifts_by_item_id: nil)
    hold = if holds_by_item_id
      holds_by_item_id[id]
    else
      Reservation.find_by(item_id: id, status: ReservationStatus::ACTIVE_HOLD)
    end
    open_gift = if open_gifts_by_item_id
      open_gifts_by_item_id[id]
    else
      GiftRecord.where(item_id: id, status: GiftStatus::OPEN).limit(1).first
    end

    return "reserved_by_me" if hold && hold.user_id == viewer.id
    return "unavailable" if hold
    return "reserved_by_me" if open_gift && open_gift.gifter_id == viewer.id
    return "unavailable" if open_gift

    "available"
  end

  # [REQ-ITEM-004] True when this item has a received_confirmed GiftRecord.
  def received_confirmed?
    GiftRecord.where(item_id: id, status: "received_confirmed").limit(1).exists?
  end

  # [REQ-RES-002] Batch-load active/grace holds for a page of items (bounded lists).
  def self.active_holds_by_item_id(item_ids)
    ids = Array(item_ids).first(200)
    return {} if ids.empty?

    Reservation.where(item_id: ids, status: ReservationStatus::ACTIVE_HOLD)
               .limit(200)
               .index_by(&:item_id)
  end

  # [REQ-GIFT-002] Batch-load open gifts for a page of items (bounded lists).
  def self.open_gifts_by_item_id(item_ids)
    ids = Array(item_ids).first(200)
    return {} if ids.empty?

    GiftRecord.where(item_id: ids, status: GiftStatus::OPEN)
              .limit(200)
              .index_by(&:item_id)
  end

  # [REQ-GIFT-001] Batch-load delivered_pending gifts awaiting owner confirm.
  def self.pending_confirm_gifts_by_item_id(item_ids)
    ids = Array(item_ids).first(200)
    return {} if ids.empty?

    GiftRecord.where(item_id: ids, status: "delivered_pending_confirmation")
              .limit(200)
              .index_by(&:item_id)
  end

  # [REQ-ITEM-004] Item ids in a wishlist that belong in the Received Gifts section.
  def self.received_gift_item_ids_for(wishlist_id)
    joins(:gift_records)
      .where(wishlist_id: wishlist_id, gift_records: { status: "received_confirmed" }, discarded_at: nil)
      .limit(500)
      .distinct
      .pluck(:id)
  end


  private

  def base_api_payload
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
      images: images.attachments.limit(MAX_IMAGES).map { |att| image_as_json(att) },
      created_at: created_at,
      updated_at: updated_at
    }
  end

  def received_gift_flag(received_gift_ids)
    return received_gift_ids.include?(id) if received_gift_ids

    received_confirmed?
  end

  def pending_confirm_id(pending_confirm_gifts_by_item_id)
    gift = if pending_confirm_gifts_by_item_id
      pending_confirm_gifts_by_item_id[id]
    else
      GiftRecord.find_by(item_id: id, status: "delivered_pending_confirmation")
    end
    gift&.id
  end

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
