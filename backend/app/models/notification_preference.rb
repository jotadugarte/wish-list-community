# frozen_string_literal: true

# Per-user per-event channel toggles (in_app / email / push). Defaults all-on for S5 events.
# Traceability: [REQ-NOTIF-001]
class NotificationPreference < ApplicationRecord
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
