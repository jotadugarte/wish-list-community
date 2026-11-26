# frozen_string_literal: true

# Single entrypoint for in-app + email enqueue + push no-op (S5 foundation).
# Traceability: [REQ-NOTIF-001], [REQ-NOTIF-002]
class NotificationDispatcher
  MAX_DEVICE_TOKENS = 20

  # [REQ-NOTIF-001] Pre-condition: user and event_key present.
  # Post-condition: returns the in-app Notification when in_app enabled, else nil.
  def self.dispatch!(user:, event_key:, title:, body: nil, payload: {})
    raise ArgumentError, "user required" if user.nil? || user.discarded?
    raise ArgumentError, "event_key required" if event_key.blank?

    prefs = NotificationPreference.for_user(user).enabled_channels_for(event_key)
    notification = nil

    if prefs["in_app"] != false
      notification = Notification.create!(
        user: user,
        event_key: event_key.to_s,
        title: title,
        body: body,
        payload: payload || {}
      )
    end

    if prefs["email"] != false
      NotificationMailer.event_email(user.id, event_key.to_s, title, body).deliver_later
    end

    # [REQ-NOTIF-002] Push send is no-op in S5; preference is still honored for future S9.
    if prefs["push"] != false
      DeviceToken.where(user_id: user.id).limit(MAX_DEVICE_TOKENS).pluck(:id)
      # Intentionally no FCM network call in Sprint 5 (O1A).
    end

    notification
  end
end
