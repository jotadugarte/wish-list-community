# frozen_string_literal: true

# Single entrypoint for in-app + email enqueue + push via PushNotifier adapter.
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

    # [REQ-NOTIF-001] [REQ-NOTIF-002] Push via adapter when tokens exist (NullAdapter in CI / O10B).
    deliver_push!(user: user, prefs: prefs, event_key: event_key, title: title, body: body, payload: payload)

    notification
  end

  def self.deliver_push!(user:, prefs:, event_key:, title:, body:, payload:)
    return if prefs["push"] == false

    tokens = DeviceToken.where(user_id: user.id).limit(MAX_DEVICE_TOKENS).pluck(:token)
    return if tokens.blank?

    PushNotifier.deliver!(
      tokens: tokens,
      title: title,
      body: body,
      event_key: event_key,
      payload: payload || {}
    )
  end
  private_class_method :deliver_push!
end
