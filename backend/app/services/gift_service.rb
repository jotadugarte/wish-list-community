# frozen_string_literal: true

# Dual-path gift fulfillment: mark purchased, deliver, confirm / owner receive.
# Applies to personal and activity-scoped items (O1B reuse; activity copy in O6A).
# Traceability: [REQ-GIFT-001], [REQ-GIFT-002], [REQ-GIFT-003], [REQ-GIFT-004],
# [REQ-ADM-001], [REQ-RES-002], [REQ-RES-006], [REQ-NOTIF-001]
class GiftService
  class Error < StandardError; end
  class ConflictError < Error; end

  # [REQ-GIFT-001] [REQ-RES-006] O6A Path 1 start: active|expired_grace → GiftRecord purchased_secret.
  # Pre-condition: reservation is the actor's active hold; no open gift on the item.
  # Post-condition: gift persisted purchased_secret; reservation completed_by_gift.
  def self.mark_purchased!(reservation:, actor:, purchase_link_ref: nil)
    raise Error, I18n.t("gifts.errors.reservation_required") if reservation.nil?
    raise Error, I18n.t("gifts.errors.actor_required") if actor.nil? || actor.discarded?
    raise Error, I18n.t("gifts.errors.not_purchasable") unless mark_purchased_allowed?(reservation, actor)

    link_value = normalize_purchase_link(purchase_link_ref)

    GiftRecord.transaction do
      item = reservation.item.lock!
      raise ConflictError, I18n.t("gifts.errors.open_gift_exists") if open_gift_exists?(item.id)

      gift = GiftRecord.create!(
        item: item,
        gifter: actor,
        status: "purchased_secret",
        purchase_link_ref: link_value
      )
      reservation.update!(status: "completed_by_gift", grace_expires_at: nil)
      AuditEvent.record!(
        actor: actor,
        action: "gift.mark_purchased",
        auditable: gift,
        metadata: {
          item_id: item.id,
          reservation_id: reservation.id,
          purchase_link_ref_present: link_value.present?
        }
      )
      unless gift.persisted? && gift.status == "purchased_secret" && reservation.status == "completed_by_gift"
        raise "Post-condition failed: mark_purchased must leave open gift and completed hold"
      end

      gift
    end
  rescue ActiveRecord::RecordNotUnique
    raise ConflictError, I18n.t("gifts.errors.open_gift_exists")
  end

  def self.mark_purchased_allowed?(reservation, actor)
    reservation.user_id == actor.id && ReservationStatus::ACTIVE_HOLD.include?(reservation.status)
  end
  private_class_method :mark_purchased_allowed?

  def self.open_gift_exists?(item_id)
    GiftRecord.where(item_id: item_id, status: GiftStatus::OPEN).limit(1).exists?
  end
  private_class_method :open_gift_exists?

  def self.normalize_purchase_link(raw)
    return nil if raw.blank?

    PurchaseLinkRef.new(raw).value
  rescue ArgumentError
    raise Error, I18n.t("gifts.errors.invalid_purchase_link")
  end
  private_class_method :normalize_purchase_link

  # [REQ-GIFT-001] [REQ-NOTIF-001] O7A: purchased_secret → delivered_pending_confirmation + anonymous owner notify.
  def self.mark_delivered!(gift:, actor:)
    raise Error, I18n.t("gifts.errors.gift_required") if gift.nil?
    raise Error, I18n.t("gifts.errors.actor_required") if actor.nil? || actor.discarded?
    raise Error, I18n.t("gifts.errors.not_deliverable") unless gift.gifter_id == actor.id && gift.status == "purchased_secret"

    GiftRecord.transaction do
      gift.update!(status: "delivered_pending_confirmation")
      AuditEvent.record!(
        actor: actor,
        action: "gift.mark_delivered",
        auditable: gift,
        metadata: { item_id: gift.item_id }
      )
      notify_owner_delivered!(gift)
      raise "Post-condition failed: gift must be delivered_pending_confirmation" unless gift.status == "delivered_pending_confirmation"

      gift
    end
  end

  # [REQ-GIFT-001] [REQ-GIFT-004] Path 1 owner confirm on delivered_pending_confirmation.
  def self.confirm_received!(gift:, actor:, thank_you_note: nil)
    raise Error, I18n.t("gifts.errors.gift_required") if gift.nil?
    raise Error, I18n.t("gifts.errors.actor_required") if actor.nil? || actor.discarded?
    raise Error, I18n.t("gifts.errors.not_confirmable") unless owner?(gift.item, actor)
    raise Error, I18n.t("gifts.errors.not_confirmable") unless gift.status == "delivered_pending_confirmation"

    finalize_received!(gift: gift, actor: actor, thank_you_note: thank_you_note)
  end

  # [REQ-GIFT-003] [REQ-GIFT-004] Path 2: owner marks item received in one step.
  def self.owner_mark_received!(item:, actor:, thank_you_note: nil)
    raise Error, I18n.t("gifts.errors.item_required") if item.nil? || item.discarded?
    raise Error, I18n.t("gifts.errors.actor_required") if actor.nil? || actor.discarded?
    raise Error, I18n.t("gifts.errors.not_confirmable") unless owner?(item, actor)

    GiftRecord.transaction do
      item.lock!
      open_gift = GiftRecord.where(item_id: item.id, status: GiftStatus::OPEN).limit(1).first
      hold = Reservation.where(item_id: item.id, status: ReservationStatus::ACTIVE_HOLD).limit(1).first


      if open_gift
        finalize_received!(gift: open_gift, actor: actor, thank_you_note: thank_you_note)
      elsif hold
        close_hold_for_path2!(hold)
        gift = GiftRecord.create!(item: item, gifter: hold.user, status: "purchased_secret")
        finalize_received!(gift: gift, actor: actor, thank_you_note: thank_you_note)
      else
        # FC1: free item — received_confirmed with no gifter; ignore thank-you.
        gift = GiftRecord.create!(item: item, gifter: nil, status: "received_confirmed", thank_you_note: nil)
        AuditEvent.record!(
          actor: actor,
          action: "gift.owner_mark_received",
          auditable: gift,
          metadata: { item_id: item.id, path: "fc1_free" }
        )
        gift
      end
    end
  end

  def self.finalize_received!(gift:, actor:, thank_you_note:)
    note_value = normalize_thank_you(thank_you_note, gifter_id: gift.gifter_id)
    gift.update!(status: "received_confirmed", thank_you_note: note_value)
    AuditEvent.record!(
      actor: actor,
      action: "gift.received_confirmed",
      auditable: gift,
      metadata: { item_id: gift.item_id, thank_you_present: note_value.present? }
    )
    notify_gifter_received!(gift)
    notify_gifter_thank_you!(gift) if note_value.present? && gift.gifter_id.present?
    raise "Post-condition failed: gift must be received_confirmed" unless gift.status == "received_confirmed"

    gift
  end
  private_class_method :finalize_received!

  def self.close_hold_for_path2!(hold)
    hold.update!(status: "completed_by_gift", grace_expires_at: nil)
  end
  private_class_method :close_hold_for_path2!

  def self.owner?(item, actor)
    item.wishlist.owner_id == actor.id
  end
  private_class_method :owner?

  def self.normalize_thank_you(raw, gifter_id:)
    return nil if gifter_id.blank?
    return nil if raw.blank?

    ThankYouNote.new(raw).value
  rescue ArgumentError
    raise Error, I18n.t("gifts.errors.invalid_thank_you")
  end
  private_class_method :normalize_thank_you

  def self.notify_owner_delivered!(gift)
    owner = gift.item.wishlist.owner
    return if owner.nil? || owner.discarded?

    I18n.with_locale(owner.locale.presence || I18n.default_locale) do
      NotificationDispatcher.dispatch!(
        user: owner,
        event_key: "gift.delivered_pending_confirmation",
        title: I18n.t("notifications.gift.delivered_pending_confirmation.title"),
        body: I18n.t("notifications.gift.delivered_pending_confirmation.body", item: gift.item.title),
        payload: { gift_id: gift.id, item_id: gift.item_id }
      )
    end
  end
  private_class_method :notify_owner_delivered!

  def self.notify_gifter_received!(gift)
    gifter = gift.gifter
    return if gifter.nil? || gifter.discarded?

    I18n.with_locale(gifter.locale.presence || I18n.default_locale) do
      NotificationDispatcher.dispatch!(
        user: gifter,
        event_key: "gift.received_confirmed_to_gifter",
        title: I18n.t("notifications.gift.received_confirmed_to_gifter.title"),
        body: I18n.t("notifications.gift.received_confirmed_to_gifter.body", item: gift.item.title),
        payload: { gift_id: gift.id, item_id: gift.item_id }
      )
    end
  end
  private_class_method :notify_gifter_received!

  def self.notify_gifter_thank_you!(gift)
    gifter = gift.gifter
    return if gifter.nil? || gifter.discarded?

    I18n.with_locale(gifter.locale.presence || I18n.default_locale) do
      NotificationDispatcher.dispatch!(
        user: gifter,
        event_key: "gift.thank_you",
        title: I18n.t("notifications.gift.thank_you.title"),
        body: gift.thank_you_note,
        payload: { gift_id: gift.id, item_id: gift.item_id }
      )
    end
  end
  private_class_method :notify_gifter_thank_you!
end
