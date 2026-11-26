# frozen_string_literal: true

# Recurring sweep: active past estimated_date → expired_grace; due grace → auto_released.
# Traceability: [REQ-RES-006], [REQ-USER-003]
class ReservationGraceSweepJob < ApplicationJob
  queue_as :default
  MAX_BATCH = 200
  GRACE_HOURS = 72

  # [REQ-RES-006] Idempotent batch transitions with reserver notifications.
  def perform
    enter_grace_batch!
    auto_release_batch!
  end

  private

  def enter_grace_batch!
    Reservation.where(status: "active").includes(:user).limit(MAX_BATCH).find_each do |reservation|
      zone = ActiveSupport::TimeZone[reservation.user.time_zone.presence || "UTC"]
      next if reservation.estimated_date >= zone.today

      grace_ends = zone.now + GRACE_HOURS.hours
      reservation.update!(status: "expired_grace", grace_expires_at: grace_ends)
      NotificationDispatcher.dispatch!(
        user: reservation.user,
        event_key: "reservation.grace_started",
        title: "Reservation grace started",
        body: "Your reservation expired; you have 72 hours to extend or cancel.",
        payload: { reservation_id: reservation.id }
      )
    end
  end

  def auto_release_batch!
    Reservation.where(status: "expired_grace").where("grace_expires_at <= ?", Time.current)
               .limit(MAX_BATCH).find_each do |reservation|
      reservation.update!(status: "auto_released", grace_expires_at: nil)
      NotificationDispatcher.dispatch!(
        user: reservation.user,
        event_key: "reservation.auto_released",
        title: "Reservation auto-released",
        body: "Your reservation was released after the grace window.",
        payload: { reservation_id: reservation.id }
      )
    end
  end
end
