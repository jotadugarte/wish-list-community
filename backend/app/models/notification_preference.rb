# frozen_string_literal: true

# Per-user per-event channel toggles (in_app / email / push). Defaults all-on for catalog events.
# Traceability: [REQ-NOTIF-001]
class NotificationPreference < ApplicationRecord
  # Sprint 9 O7A: full prefs catalog (friendship + reservation + gift).
  DEFAULT_EVENTS = %w[
    friend.request_received
    friend.request_accepted
    reservation.grace_started
    reservation.auto_released
    reservation.item_critical_edit
    reservation.item_deleted
    gift.delivered_pending_confirmation
    gift.received_confirmed_to_gifter
    gift.thank_you
    gift.voided_by_owner_delete
    activity.invite
    activity.accepted
    activity.declined
    activity.co_organizer_appointed
    activity.drawn
    activity.arrancar
    activity.left
    activity.dropout_needs_cure
    activity.blind_bridged
    activity.full_redraw
    activity.cancelled
    activity.ownership_transferred
    activity.item_touched_while_reserved
    activity.reservation_created
    activity.reservation_released
    activity.reservation_grace_started
    activity.reservation_auto_released
    activity.gift_purchased
    activity.gift_delivered
    activity.gift_received
    activity.budget_rejected
  ].freeze
  # Reservation-only subset retained for callers that still name S5 events.
  S5_EVENTS = %w[
    reservation.grace_started
    reservation.auto_released
    reservation.item_critical_edit
    reservation.item_deleted
  ].freeze
  CHANNELS = %w[in_app email push].freeze

  belongs_to :user

  # [REQ-NOTIF-001] Returns channel hash for an event (defaults all true when missing).
  def enabled_channels_for(event_key)
    defaults = { "in_app" => true, "email" => true, "push" => true }
    stored = channels.is_a?(Hash) ? channels[event_key.to_s] : nil
    return defaults if stored.blank?

    merged = defaults.merge(stored.stringify_keys.slice(*CHANNELS))
    merged.transform_values { |v| ActiveModel::Type::Boolean.new.cast(v) }
  end

  # [REQ-NOTIF-001] Class helper: load or synthesize defaults for a user.
  def self.for_user(user)
    find_by(user_id: user.id) || new(user: user, channels: {})
  end
end
