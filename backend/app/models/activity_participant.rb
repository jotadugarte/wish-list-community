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

  # [REQ-ACT-001] Accepts a pending invitation and applies O2B layer-1 freeze when needed.
  def accept!
    raise ArgumentError, "Pre-condition failed: must be invited" unless status == "invited"

    transaction do
      update!(status: "accepted", accepted_at: Time.current)
      freeze_money_settings_if_first_invitee_accept!
    end
    raise "Post-condition failed: status must be accepted" unless status == "accepted"
    ActivityNotifier.accepted!(activity: activity, participant: self, actor: user)

    self
  end

  # [REQ-ACT-001] Declines a pending invitation.
  def decline!
    raise ArgumentError, "Pre-condition failed: must be invited" unless status == "invited"

    update!(status: "declined")
    raise "Post-condition failed: status must be declined" unless status == "declined"
    ActivityNotifier.declined!(activity: activity, actor: user)

    self
  end

  # [REQ-ACT-001] Leaves an accepted participation while the activity is unsealed.
  def leave!
    raise ArgumentError, "Pre-condition failed: must be accepted" unless status == "accepted"
    raise ArgumentError, "Pre-condition failed: activity must be unsealed for free leave" if activity.sealed?

    mark_left!
    self
  end

  # [REQ-BLOCK-001] [REQ-ACT-003] Forced removal (block/dropout) even after seal.
  def force_leave!(require_cure: false)
    return self if status == "left"

    transaction do
      mark_left!
      activity.require_dropout_recovery! if require_cure && activity.sealed? && activity.secret_santa?
    end

    self
  end

  private

  def mark_left!
    update!(status: "left", left_at: Time.current, co_organizer: false)
    raise "Post-condition failed: status must be left" unless status == "left"
  end

  def freeze_money_settings_if_first_invitee_accept!
    return if user_id == activity.creator_id

    activity.freeze_money_settings!
  end
end

# [REQ-BLOCK-001] [REQ-ACT-003] Block Wins removes both users from shared activities (FC1A).
UserBlock.register_cleanup_hook(:activity_block_wins) do |blocker, blocked|
  ::ActivityParticipant
  ::Activity
  max_rows = 500
  participant_rows = ActivityParticipant
                     .where(user_id: [ blocker.id, blocked.id ], status: %w[invited accepted])
                     .limit(max_rows)
                     .to_a
  activity_ids = participant_rows.map(&:activity_id).uniq
  activity_ids.first(max_rows).each do |activity_id|
    activity = Activity.find_by(id: activity_id)
    next if activity.nil? || activity.cancelled?

    affected = ActivityParticipant.where(activity_id: activity_id, user_id: [ blocker.id, blocked.id ])
                                  .where(status: %w[invited accepted])
                                  .limit(max_rows)
    require_cure = activity.sealed? && activity.secret_santa?
    affected.each { |participant| participant.force_leave!(require_cure: require_cure) }
  end
end

