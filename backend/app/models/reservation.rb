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


  # [REQ-LIFE-001] [REQ-BLOCK-002] Permanently ends an active/grace hold (no ghost on restore).
  def self.cancel_active_holds_for_item!(item_id)
    where(item_id: item_id, status: ReservationStatus::ACTIVE_HOLD).limit(50).find_each do |reservation|
      reservation.update!(status: "canceled", grace_expires_at: nil)
    end
  end

  # [REQ-BLOCK-002] Cancels active/grace holds between two users (either as reserver on the other's items).
  def self.cancel_between_users!(user_a, user_b)
    raise ArgumentError, "users required" if user_a.nil? || user_b.nil?

    ids = [user_a.id, user_b.id]
    where(status: ReservationStatus::ACTIVE_HOLD, user_id: ids).limit(200).find_each do |reservation|
      owner_id = reservation.item.wishlist.owner_id
      next unless ids.include?(owner_id)

      reservation.update!(status: "canceled", grace_expires_at: nil)
    end
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


UserBlock.register_cleanup_hook(:cancel_reservations) do |blocker, blocked|
  Reservation
  Reservation.cancel_between_users!(blocker, blocked)
end
