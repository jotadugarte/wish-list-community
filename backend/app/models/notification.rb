# frozen_string_literal: true

# In-app notification row created by NotificationDispatcher.
# Traceability: [REQ-NOTIF-001]
class Notification < ApplicationRecord
  belongs_to :user

  validates :event_key, :title, presence: true

  scope :unread, -> { where(read_at: nil) }

  # [REQ-NOTIF-001] Marks the notification as read.
  def mark_read!
    update!(read_at: Time.current) if read_at.nil?
    self
  end

  def as_api_json
    {
      id: id,
      event_key: event_key,
      title: title,
      body: body,
      payload: payload,
      read_at: read_at,
      created_at: created_at
    }
  end
end
