# frozen_string_literal: true

# Creator/co-organizer administration for Activities (invite, co-org, transfer, cancel).
# Traceability: [REQ-ACT-001], [REQ-ACT-003]
class ActivityAdminService
  class << self
    # [REQ-ACT-001] Creator-only co-organizer appointment (ACCEPT parks).
    def appoint_co_organizer!(activity:, actor:, user:)
      assert_persisted!(activity, actor, user)
      raise ArgumentError, "Pre-condition failed: only the creator may appoint co-organizers" unless actor.id == activity.creator_id

      participant = accepted_participant!(activity, user)
      participant.update!(co_organizer: true)
      raise "Post-condition failed: co_organizer must be true" unless participant.co_organizer?
      ActivityNotifier.co_organizer_appointed!(activity: activity, user: user, actor: actor)

      participant
    end

    # [REQ-ACT-001] Creator-only co-organizer removal.
    def remove_co_organizer!(activity:, actor:, user:)
      assert_persisted!(activity, actor, user)
      raise ArgumentError, "Pre-condition failed: only the creator may remove co-organizers" unless actor.id == activity.creator_id
      raise ArgumentError, "Pre-condition failed: cannot demote the creator" if user.id == activity.creator_id

      participant = accepted_participant!(activity, user)
      participant.update!(co_organizer: false)
      raise "Post-condition failed: co_organizer must be false" if participant.co_organizer?

      participant
    end

    # [REQ-ACT-001] Creator or co-organizer may invite (O3B).
    def invite!(activity:, actor:, user:)
      assert_persisted!(activity, actor, user)
      assert_admin!(activity, actor)
      raise ArgumentError, "Pre-condition failed: blocked users cannot be invited" if UserBlock.blocked_between?(actor, user)
      raise ArgumentError, "Pre-condition failed: blocked with creator" if UserBlock.blocked_between?(activity.creator, user)
      peer_ids = activity.participants.where(status: %w[invited accepted]).limit(500).pluck(:user_id)
      peer_ids << activity.creator_id
      if peer_ids.any? { |uid| uid != user.id && UserBlock.blocked_between?(user, User.new(id: uid)) }
        raise ArgumentError, "Pre-condition failed: blocked with a participant"
      end

      participant = ActivityParticipant.invite!(activity: activity, user: user, actor: actor)
      ActivityNotifier.invite!(activity: activity, recipient: user, actor: actor)
      participant
    end

    # [REQ-ACT-001] FC2C ownership transfer to an accepted co-organizer.
    def transfer_ownership!(activity:, actor:, new_creator:)
      assert_persisted!(activity, actor, new_creator)
      raise ArgumentError, "Pre-condition failed: only the creator may transfer ownership" unless actor.id == activity.creator_id
      raise ArgumentError, "Pre-condition failed: new creator must differ" if new_creator.id == activity.creator_id

      participant = accepted_participant!(activity, new_creator)
      raise ArgumentError, "Pre-condition failed: new creator must be a co-organizer" unless participant.co_organizer?

      activity.transaction do
        activity.update!(creator: new_creator)
        participant.update!(co_organizer: true)
        former = accepted_participant!(activity, actor)
        former.update!(co_organizer: true)
        AuditEvent.record!(
          actor: actor,
          action: "activity.ownership_transferred",
          auditable: activity,
          metadata: { new_creator_id: new_creator.id }
        )
      end

      raise "Post-condition failed: creator must be transferred" unless activity.reload.creator_id == new_creator.id
      ActivityNotifier.ownership_transferred!(activity: activity, new_creator: new_creator, actor: actor)

      activity
    end

    # [REQ-ACT-001] Creator or co-organizer may cancel the activity (FC2C).
    def cancel!(activity:, actor:)
      assert_persisted!(activity, actor)
      assert_admin!(activity, actor)
      raise ArgumentError, "Pre-condition failed: already cancelled" if activity.cancelled?

      activity.transaction do
        activity.update!(status: "cancelled", cancelled_at: Time.current)
        ActivityParticipationCleanup.cleanup_cancelled_activity!(activity: activity, actor: actor)
        AuditEvent.record!(
          actor: actor,
          action: "activity.cancelled",
          auditable: activity,
          metadata: {}
        )
      end

      raise "Post-condition failed: activity must be cancelled" unless activity.reload.cancelled?
      ActivityNotifier.cancelled!(activity: activity, actor: actor)

      activity
    end

    private

    def assert_persisted!(*records)
      records.each do |record|
        raise ArgumentError, "Pre-condition failed: records must be persisted" unless record&.persisted?
      end
    end

    def assert_admin!(activity, actor)
      return if actor.id == activity.creator_id
      return if activity.participants.where(user_id: actor.id, status: "accepted", co_organizer: true).exists?

      raise ArgumentError, "Pre-condition failed: actor must be creator or co-organizer"
    end

    def accepted_participant!(activity, user)
      participant = activity.participants.find_by(user_id: user.id, status: "accepted")
      raise ArgumentError, "Pre-condition failed: user must be an accepted participant" if participant.nil?

      participant
    end
  end
end
