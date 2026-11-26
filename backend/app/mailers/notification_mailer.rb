# frozen_string_literal: true

# Localized notification emails enqueued by NotificationDispatcher.
# Traceability: [REQ-NOTIF-001], [REQ-USER-002]
class NotificationMailer < ApplicationMailer
  # [REQ-NOTIF-001] Delivers a generic event email to the user.
  def event_email(user_id, event_key, title, body)
    @user = User.find(user_id)
    @event_key = event_key
    @title = title
    @body = body
    I18n.with_locale(@user.locale.presence || I18n.default_locale) do
      mail(to: @user.email_address, subject: title)
    end
  end
end
