# frozen_string_literal: true

# Tracks a 30-day quarantine on a user's previous @username after a handle change
# so third parties cannot immediately claim the old handle to impersonate them.
# Traceability: [REQ-USER-004]
class UsernameReservation < ApplicationRecord
  QUARANTINE_DURATION = 30.days

  belongs_to :previous_user, class_name: "User"

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  # [REQ-USER-004] Checks if a handle is currently quarantined by a different user.
  def self.quarantined_for?(candidate_username, excluding_user_id: nil)
    normalized = candidate_username.to_s.strip.downcase
    scope = active.where("LOWER(username) = ?", normalized)
    scope = scope.where.not(previous_user_id: excluding_user_id) if excluding_user_id.present?
    scope.exists?
  end
end
