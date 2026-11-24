# frozen_string_literal: true

# FCM Push Notification device token bound to an active ApiToken session.
# Automatically removed when the user logs out or revokes the ApiToken to prevent
# push notification spoilers on shared mobile devices.
# Traceability: [REQ-NOTIF-002]
class DeviceToken < ApplicationRecord
  belongs_to :user
  belongs_to :api_token

  validates :token, presence: true, uniqueness: true
end
