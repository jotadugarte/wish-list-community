# frozen_string_literal: true

# Dual-path gift fulfillment: mark purchased, deliver, confirm / owner receive.
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
end
