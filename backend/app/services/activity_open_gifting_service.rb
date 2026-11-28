# frozen_string_literal: true

# Open gifting Arrancar / cerrar altas seal (no assignments).
# Traceability: [REQ-ACT-001]
class ActivityOpenGiftingService
  class << self
    # [REQ-ACT-001] Seals open_gifting participation when >= 2 accepted (FC3A).
    def arrancar!(activity:, actor:)
      raise ArgumentError, "Pre-condition failed: activity required" if activity.nil?
      raise ArgumentError, "Pre-condition failed: must be open_gifting" unless activity.open_gifting?
      raise ArgumentError, "Pre-condition failed: already sealed" if activity.sealed?
      ActivityAdminService.send(:assert_admin!, activity, actor)

      count = activity.accepted_participants.limit(ActivityExclusionService::MAX_PARTICIPANTS).count
      raise ArgumentError, "Pre-condition failed: minimum 2 accepted participants required" if count < 2

      activity.transaction do
        ActivityParticipant.expire_pending_invites!(activity)
        activity.update!(status: "sealed", sealed_at: Time.current, needs_dropout_recovery: false)
        AuditEvent.record!(
          actor: actor,
          action: "activity.arrancar",
          auditable: activity,
          metadata: { participant_count: count }
        )
      end

      raise "Post-condition failed: activity must be sealed" unless activity.reload.sealed?
      raise "Post-condition failed: open_gifting must not create assignments" if ActivityAssignment.where(activity: activity).exists?
      ActivityNotifier.arrancar!(activity: activity)

      activity
    end
  end
end
