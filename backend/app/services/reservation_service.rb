# frozen_string_literal: true

# Creates, extends, and cancels secret reservations with limit checks.
# Traceability: [REQ-RES-001], [REQ-RES-005], [REQ-RES-006], [REQ-ARCH-003], [REQ-USER-003], [REQ-WISH-004]
class ReservationService
  class Error < StandardError; end

  # [REQ-RES-001] [REQ-RES-005] Pre-condition: item kept, estimated_date present.
  # Post-condition: returns persisted active Reservation.
  def self.create!(item:, user:, estimated_date:, private_note: nil)
    raise Error, "item required" if item.nil? || item.discarded?
    raise Error, "user required" if user.nil? || user.discarded?

    date_vo = EstimatedDate.new(estimated_date, time_zone: user.time_zone.presence || "UTC")
    date_vo.assert_not_past!

    Reservation.transaction do
      enforce_per_wishlist_limit!(wishlist: item.wishlist, user: user)
      reservation = Reservation.create!(
        item: item,
        user: user,
        status: "active",
        estimated_date: date_vo.value,
        private_note: private_note.presence,
        grace_expires_at: nil
      )
      AuditEvent.record!(
        actor: user,
        action: "reservation.created",
        auditable: reservation,
        metadata: { item_id: item.id, wishlist_id: item.wishlist_id }
      )
      raise "Post-condition failed: reservation must be persisted active" unless reservation.persisted? && reservation.status == "active"

      reservation
    end
  end

  # [REQ-RES-001] [REQ-RES-006] O5A extend: set new date; grace → active.
  def self.extend!(reservation:, estimated_date:, private_note: :unchanged)
    raise Error, "reservation required" if reservation.nil?
    raise Error, "not extendable" unless ReservationStatus::ACTIVE_HOLD.include?(reservation.status)

    date_vo = EstimatedDate.new(estimated_date, time_zone: reservation.user.time_zone.presence || "UTC")
    date_vo.assert_not_past!

    Reservation.transaction do
      attrs = {
        estimated_date: date_vo.value,
        status: "active",
        grace_expires_at: nil
      }
      attrs[:private_note] = private_note.presence if private_note != :unchanged
      reservation.update!(attrs)
      AuditEvent.record!(
        actor: reservation.user,
        action: "reservation.extended",
        auditable: reservation,
        metadata: { estimated_date: date_vo.value.iso8601 }
      )
      reservation
    end
  end

  # [REQ-RES-001] O6A voluntary cancel.
  def self.cancel!(reservation:, actor:)
    raise Error, "reservation required" if reservation.nil?
    raise Error, "not cancelable" unless ReservationStatus::ACTIVE_HOLD.include?(reservation.status)

    Reservation.transaction do
      reservation.update!(status: "canceled", grace_expires_at: nil)
      AuditEvent.record!(
        actor: actor,
        action: "reservation.canceled",
        auditable: reservation,
        metadata: { item_id: reservation.item_id }
      )
      reservation
    end
  end

  def self.enforce_per_wishlist_limit!(wishlist:, user:)
    limit = wishlist.max_reservations_per_user
    return if limit.nil?

    raise Error, "limit must be positive" if limit < 1

    item_ids = wishlist.items.kept.limit(500).pluck(:id)
    count = Reservation.where(user_id: user.id, item_id: item_ids, status: ReservationStatus::ACTIVE_HOLD).limit(500).count
    raise Error, "reservation limit reached for this wishlist" if count >= limit
  end
  private_class_method :enforce_per_wishlist_limit!
end
