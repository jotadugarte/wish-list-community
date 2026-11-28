# frozen_string_literal: true

# Creates, extends, and cancels secret reservations with limit checks.
# Traceability: [REQ-RES-001], [REQ-RES-005], [REQ-RES-006], [REQ-ARCH-003], [REQ-USER-003], [REQ-WISH-004]
class ReservationService
  class Error < StandardError; end

  # [REQ-RES-001] [REQ-RES-005] Pre-condition: item kept, estimated_date present.
  # Post-condition: returns persisted active Reservation.
  def self.create!(item:, user:, estimated_date:, private_note: nil)
    raise Error, I18n.t("reservations.errors.item_required") if item.nil? || item.discarded?
    raise Error, I18n.t("reservations.errors.user_required") if user.nil? || user.discarded?

    date_vo = EstimatedDate.new(estimated_date, time_zone: user.time_zone.presence || "UTC")
    date_vo.assert_not_past!
    assert_activity_reserve_allowed!(item: item, user: user)

    Reservation.transaction do
      wishlist = item.wishlist
      lock_secret_santa_activity!(wishlist)
      wishlist.lock!
      enforce_per_wishlist_limit!(wishlist: wishlist, user: user)
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

      ActivityNotifier.reservation_created!(reservation: reservation) if wishlist.activity_scoped?
      reservation
    end
  end

  # [REQ-RES-001] [REQ-RES-006] O5A extend: set new date; grace → active.
  def self.extend!(reservation:, estimated_date:, private_note: :unchanged)
    raise Error, I18n.t("reservations.errors.reservation_required") if reservation.nil?
    raise Error, I18n.t("reservations.errors.not_extendable") unless ReservationStatus::ACTIVE_HOLD.include?(reservation.status)

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
      unless reservation.status == "active" && reservation.grace_expires_at.nil?
        raise "Post-condition failed: extend must leave reservation active with nil grace"
      end

      reservation
    end
  end

  # [REQ-RES-001] O6A voluntary cancel.
  def self.cancel!(reservation:, actor:)
    raise Error, I18n.t("reservations.errors.reservation_required") if reservation.nil?
    raise Error, I18n.t("reservations.errors.not_cancelable") unless ReservationStatus::ACTIVE_HOLD.include?(reservation.status)

    Reservation.transaction do
      reservation.update!(status: "canceled", grace_expires_at: nil)
      AuditEvent.record!(
        actor: actor,
        action: "reservation.canceled",
        auditable: reservation,
        metadata: { item_id: reservation.item_id }
      )
      raise "Post-condition failed: cancel must leave status canceled" unless reservation.status == "canceled"

      if reservation.item.wishlist&.activity_scoped?
        ActivityNotifier.reservation_released!(reservation: reservation)
      end
      reservation
    end
  end

  def self.enforce_per_wishlist_limit!(wishlist:, user:)
    enforce_secret_santa_activity_limit!(wishlist: wishlist, user: user)

    limit = wishlist.max_reservations_per_user
    return if limit.nil?

    raise Error, I18n.t("reservations.errors.limit_must_be_positive") if limit < 1

    count = Reservation.joins(:item)
                       .where(
                         user_id: user.id,
                         status: ReservationStatus::ACTIVE_HOLD,
                         items: { wishlist_id: wishlist.id, discarded_at: nil }
                       )
                       .limit(limit + 1)
                       .count
    raise Error, I18n.t("reservations.errors.limit_reached") if count >= limit
  end
  private_class_method :enforce_per_wishlist_limit!

  # [REQ-RES-005] Lock Activity before wishlist so SS creates across lists serialize.
  def self.lock_secret_santa_activity!(wishlist)
    return unless wishlist&.activity_scoped?

    activity = wishlist.activity
    return unless activity&.secret_santa?

    activity.lock!
  end
  private_class_method :lock_secret_santa_activity!

  # [REQ-RES-005] O5A: secret_santa is 1 active hold per participant across the activity.
  def self.enforce_secret_santa_activity_limit!(wishlist:, user:)
    return unless wishlist&.activity_scoped?

    activity = wishlist.activity
    return unless activity&.secret_santa?

    count = Reservation.joins(item: :wishlist)
                       .where(
                         user_id: user.id,
                         status: ReservationStatus::ACTIVE_HOLD,
                         wishlists: { activity_id: activity.id }
                       )
                       .where(items: { discarded_at: nil })
                       .limit(2)
                       .count
    raise Error, I18n.t("reservations.errors.limit_reached") if count >= 1
  end
  private_class_method :enforce_secret_santa_activity_limit!

  # [REQ-ACT-001] [REQ-ACT-005] [REQ-NOTIF-001] O3A/O4A: activity gate + budget re-check on reserve.
  def self.assert_activity_reserve_allowed!(item:, user:)
    wishlist = item.wishlist
    return unless wishlist&.activity_scoped?

    ActivityVisibilityGate.assert_may_reserve!(viewer: user, item: item)
    BudgetEnforcement.assert_item!(item: item)
  rescue ActivityVisibilityGate::Error => e
    raise Error, e.message
  rescue ArgumentError => e
    notify_budget_reject_if_needed!(item: item, actor: user, error: e)
    raise Error, e.message
  end
  private_class_method :assert_activity_reserve_allowed!

  # [REQ-NOTIF-001] O6A: budget reject on reserve → item owner.
  def self.notify_budget_reject_if_needed!(item:, actor:, error:)
    return unless error.message.match?(/budget|price|fixed|min|max|range/i)

    ActivityNotifier.budget_rejected!(item: item, actor: actor)
  end
  private_class_method :notify_budget_reject_if_needed!
end
