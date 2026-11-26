# frozen_string_literal: true

# Recurring sweep: active past estimated_date → expired_grace; due grace → auto_released.
# Traceability: [REQ-RES-006], [REQ-USER-003]
class ReservationGraceSweepJob < ApplicationJob
  queue_as :default
  MAX_BATCH = 200
  GRACE_HOURS = 72
  # Oversample ordered by estimated_date so overdue holds are not starved behind future-dated ones.
  CANDIDATE_MULTIPLIER = 10

  # [REQ-RES-006] Idempotent batch transitions with reserver notifications.
  def perform
    enter_grace_batch!
    auto_release_batch!
  end

  private

  def enter_grace_batch!
    transitioned = 0
    candidate_ids = Reservation.where(status: "active")
                               .where("estimated_date <= ?", Date.current + 1)
                               .order(:estimated_date, :id)
                               .limit(MAX_BATCH * CANDIDATE_MULTIPLIER)
                               .pluck(:id)
    return if candidate_ids.empty?

    Reservation.where(id: candidate_ids).includes(:user).order(:estimated_date, :id).each do |reservation|
      break if transitioned >= MAX_BATCH

      user = reservation.user
      if user.nil? || user.discarded?
        reservation.update!(status: "canceled", grace_expires_at: nil)
        transitioned += 1
        next
      end

      zone = ActiveSupport::TimeZone[user.time_zone.presence || "UTC"] || ActiveSupport::TimeZone["UTC"]
      next if reservation.estimated_date >= zone.today

      grace_ends = zone.now + GRACE_HOURS.hours
      reservation.update!(status: "expired_grace", grace_expires_at: grace_ends)
      dispatch_safe!(
        user: user,
        event_key: "reservation.grace_started",
        title_key: "notifications.reservation.grace_started.title",
        body_key: "notifications.reservation.grace_started.body",
        payload: { reservation_id: reservation.id }
      )
      transitioned += 1
    end
  end

  def auto_release_batch!
    transitioned = 0
    Reservation.where(status: "expired_grace")
               .where("grace_expires_at <= ?", Time.current)
               .includes(:user)
               .order(:grace_expires_at, :id)
               .limit(MAX_BATCH * CANDIDATE_MULTIPLIER)
               .each do |reservation|
      break if transitioned >= MAX_BATCH

      user = reservation.user
      if user.nil? || user.discarded?
        reservation.update!(status: "canceled", grace_expires_at: nil)
        transitioned += 1
        next
      end

      reservation.update!(status: "auto_released", grace_expires_at: nil)
      dispatch_safe!(
        user: user,
        event_key: "reservation.auto_released",
        title_key: "notifications.reservation.auto_released.title",
        body_key: "notifications.reservation.auto_released.body",
        payload: { reservation_id: reservation.id }
      )
      transitioned += 1
    end
  end

  def dispatch_safe!(user:, event_key:, title_key:, body_key:, payload:)
    I18n.with_locale(user.locale.presence || I18n.default_locale) do
      NotificationDispatcher.dispatch!(
        user: user,
        event_key: event_key,
        title: I18n.t(title_key),
        body: I18n.t(body_key),
        payload: payload
      )
    end
  rescue ArgumentError
    # Discarded/missing user should never abort the batch.
    nil
  end
end
