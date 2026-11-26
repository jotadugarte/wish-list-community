# frozen_string_literal: true

# Secret hold on one Item by one User (Sprint 5 — no gift transitions).
# Traceability: [REQ-RES-001], [REQ-RES-002], [REQ-RES-006], [REQ-USER-003], [REQ-WISH-004]
class Reservation < ApplicationRecord
  belongs_to :item
  belongs_to :user

  validates :status, presence: true
  validates :estimated_date, presence: true
  validate :status_must_be_allowed
  validate :reserver_must_not_be_owner

  # [REQ-RES-001] Status Value Object for the stored lifecycle status.
  def status_vo
    ReservationStatus.new(status)
  end

  # [REQ-WISH-004] Soft warning when estimated_date is after the wishlist event_date.
  def warn_event_date_exceeded?
    event_date = item&.wishlist&.event_date
    return false if event_date.blank? || estimated_date.blank?

    estimated_date > event_date
  end

  # [REQ-RES-001] [REQ-RES-004] JSON payload for the reserver (never for owner spoilers).
  def as_api_json
    {
      id: id,
      item_id: item_id,
      wishlist_id: item.wishlist_id,
      status: status,
      estimated_date: estimated_date&.iso8601,
      private_note: private_note,
      grace_expires_at: grace_expires_at,
      warn_event_date_exceeded: warn_event_date_exceeded?,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  private

  def status_must_be_allowed
    ReservationStatus.new(status)
  rescue ArgumentError
    errors.add(:status, "is not included in the list")
  end

  def reserver_must_not_be_owner
    return if item.blank? || user.blank?
    return if item.wishlist.blank?
    return if user_id != item.wishlist.owner_id

    errors.add(:user, "cannot reserve their own item")
  end
end
