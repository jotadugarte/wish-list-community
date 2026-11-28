# frozen_string_literal: true

# Participant invite/accept/decline/leave record for an Activity.
# Traceability: [REQ-ACT-001]
class ActivityParticipant < ApplicationRecord
  STATUSES = %w[invited accepted declined left].freeze

  belongs_to :activity
  belongs_to :user

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :activity_id }

  # [REQ-ACT-001] Invites a user into the activity as pending.
  def self.invite!(activity:, user:, actor:)
    raise ArgumentError, "Pre-condition failed: activity required" if activity.nil?
    raise ArgumentError, "Pre-condition failed: user required" if user.nil?
    raise ArgumentError, "Pre-condition failed: actor required" if actor.nil?
    raise ArgumentError, "Pre-condition failed: activity must be open" if activity.cancelled? || activity.sealed?

    participant = create!(activity: activity, user: user, status: "invited", co_organizer: false)
    raise "Post-condition failed: invite must be invited" unless participant.status == "invited"

    participant
  end

  # [REQ-ACT-001] Accepts a pending invitation.
  def accept!
    raise ArgumentError, "Pre-condition failed: must be invited" unless status == "invited"

    update!(status: "accepted", accepted_at: Time.current)
    raise "Post-condition failed: status must be accepted" unless status == "accepted"

    self
  end

  # [REQ-ACT-001] Declines a pending invitation.
  def decline!
    raise ArgumentError, "Pre-condition failed: must be invited" unless status == "invited"

    update!(status: "declined")
    raise "Post-condition failed: status must be declined" unless status == "declined"

    self
  end

  # [REQ-ACT-001] Leaves an accepted participation while the activity is unsealed.
  def leave!
    raise ArgumentError, "Pre-condition failed: must be accepted" unless status == "accepted"
    raise ArgumentError, "Pre-condition failed: activity must be unsealed for free leave" if activity.sealed?

    update!(status: "left", left_at: Time.current, co_organizer: false)
    raise "Post-condition failed: status must be left" unless status == "left"

    self
  end
end
