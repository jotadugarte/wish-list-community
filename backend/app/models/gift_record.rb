# frozen_string_literal: true

# Dual-path gift fulfillment + optional thank-you + admin purchase link (Sprint 6).
# Traceability: [REQ-GIFT-001], [REQ-GIFT-002], [REQ-GIFT-003], [REQ-GIFT-004], [REQ-ADM-001], [REQ-RES-002]
class GiftRecord < ApplicationRecord
  belongs_to :item
  belongs_to :gifter, class_name: "User", optional: true

  validates :status, presence: true
  validate :status_must_be_allowed
  validate :thank_you_note_must_be_valid
  validate :purchase_link_ref_must_be_valid

  # [REQ-GIFT-001] Status Value Object for the stored lifecycle status.
  def status_vo
    GiftStatus.new(status)
  end

  # [REQ-GIFT-001] [REQ-GIFT-004] [REQ-RES-002] API JSON — no purchase_link_ref; gifter_id only for gifter/admin.
  def as_api_json(viewer: nil)
    payload = {
      id: id,
      item_id: item_id,
      wishlist_id: item.wishlist_id,
      status: status,
      thank_you_note: thank_you_note,
      created_at: created_at,
      updated_at: updated_at
    }
    payload[:gifter_id] = gifter_id if reveal_gifter_id?(viewer)
    payload
  end

  # [REQ-GIFT-002] Open gifts that block availability for third parties.
  def self.open_for_item(item_id)
    where(item_id: item_id, status: GiftStatus::OPEN).limit(5)
  end


  # [REQ-LIFE-001] O8D: void open gifts on an item; optionally notify gifter; never touch received_confirmed.
  def self.void_open_for_item!(item_id, notify_gifter:, actor:)
    where(item_id: item_id, status: GiftStatus::OPEN).limit(50).find_each do |gift|
      void_gift!(gift, notify_gifter: notify_gifter, actor: actor, reason: "owner_delete")
    end
  end

  # [REQ-BLOCK-002] O8D: void open gifts between a pair (owner↔gifter) without reopen on restore.
  def self.void_between_users!(user_a, user_b, notify_gifter:, actor:)
    raise ArgumentError, "users required" if user_a.nil? || user_b.nil?

    ids = [ user_a.id, user_b.id ]
    where(status: GiftStatus::OPEN, gifter_id: ids).limit(200).find_each do |gift|
      owner_id = gift.item.wishlist.owner_id
      next unless ids.include?(owner_id)

      void_gift!(gift, notify_gifter: notify_gifter, actor: actor, reason: "relationship_end")
    end
  end

  # [REQ-GIFT-002] True when an open gift exists between the pair (for warn/confirm UX).
  def self.open_between_users?(user_a, user_b)
    return false if user_a.nil? || user_b.nil?

    ids = [ user_a.id, user_b.id ]
    where(status: GiftStatus::OPEN, gifter_id: ids).limit(50).any? do |gift|
      ids.include?(gift.item.wishlist.owner_id)
    end
  end

  def self.void_gift!(gift, notify_gifter:, actor:, reason:)
    was_delivered = gift.status == "delivered_pending_confirmation"
    gift.update!(status: "voided")
    clear_owner_delivery_prompts!(gift) if was_delivered
    AuditEvent.record!(
      actor: actor,
      action: "gift.voided",
      auditable: gift,
      metadata: { item_id: gift.item_id, reason: reason, notify_gifter: notify_gifter }
    )
    notify_gifter_voided!(gift) if notify_gifter
  end
  private_class_method :void_gift!

  def self.clear_owner_delivery_prompts!(gift)
    owner = gift.item.wishlist.owner
    return if owner.nil?

    Notification.where(
      user_id: owner.id,
      event_key: "gift.delivered_pending_confirmation"
    ).limit(50).find_each do |note|
      next unless note.payload.is_a?(Hash) && note.payload["gift_id"] == gift.id

      note.destroy!
    end
  end
  private_class_method :clear_owner_delivery_prompts!

  def self.notify_gifter_voided!(gift)
    gifter = gift.gifter
    return if gifter.nil? || gifter.discarded?

    I18n.with_locale(gifter.locale.presence || I18n.default_locale) do
      NotificationDispatcher.dispatch!(
        user: gifter,
        event_key: "gift.voided_by_owner_delete",
        title: I18n.t("notifications.gift.voided_by_owner_delete.title"),
        body: I18n.t("notifications.gift.voided_by_owner_delete.body", item: gift.item.title),
        payload: { gift_id: gift.id, item_id: gift.item_id }
      )
    end
  end
  private_class_method :notify_gifter_voided!

  private

  def reveal_gifter_id?(viewer)
    return false if viewer.nil?

    viewer.id == gifter_id || viewer.role == "admin"
  end

  def status_must_be_allowed
    GiftStatus.new(status)
  rescue ArgumentError
    errors.add(:status, I18n.t("gifts.errors.invalid_status"))
  end

  def thank_you_note_must_be_valid
    return if thank_you_note.blank?

    ThankYouNote.new(thank_you_note)
  rescue ArgumentError
    errors.add(:thank_you_note, I18n.t("gifts.errors.invalid_thank_you"))
  end

  def purchase_link_ref_must_be_valid
    return if purchase_link_ref.blank?

    PurchaseLinkRef.new(purchase_link_ref)
  rescue ArgumentError
    errors.add(:purchase_link_ref, I18n.t("gifts.errors.invalid_purchase_link"))
  end
end

UserBlock.register_cleanup_hook(:void_gifts) do |blocker, blocked|
  GiftRecord
  GiftRecord.void_between_users!(blocker, blocked, notify_gifter: false, actor: blocker)
end
