# frozen_string_literal: true

# Leave + Blind Auto-Bridge / Full Redraw recovery for sealed Secret Santa.
# Traceability: [REQ-ACT-003], [REQ-ACT-004]
class ActivityDropoutBridgeService
  class << self
    # [REQ-ACT-003] Participant leave — free pre-seal; post-draw forces cure; post-Arrancar no bridge.
    def leave!(activity:, actor:)
      raise ArgumentError, "Pre-condition failed: activity and actor required" if activity.nil? || actor.nil?

      participant = activity.participants.find_by(user_id: actor.id, status: "accepted")
      raise ArgumentError, "Pre-condition failed: actor must be an accepted participant" if participant.nil?

      if !activity.sealed?
        participant.leave!
      elsif activity.secret_santa?
        participant.force_leave!(require_cure: true)
      else
        participant.force_leave!(require_cure: false)
      end
      ActivityNotifier.left!(activity: activity, actor: actor)

      participant
    end

    # [REQ-ACT-003] [REQ-ACT-004] Blind Auto-Bridge: heal A→B→C into A→C without revealing the map.
    # Returns the first bridged pair for callers; every bridged giver is notified.
    def blind_bridge!(activity:, actor:)
      raise ArgumentError, "Pre-condition failed: sealed secret_santa required" unless activity.sealed? && activity.secret_santa?
      raise ArgumentError, "Pre-condition failed: dropout recovery required" unless activity.needs_dropout_recovery?
      ActivityAdminService.send(:assert_admin!, activity, actor)

      leavers = left_user_ids(activity)
      raise ArgumentError, "Pre-condition failed: no leavers to bridge" if leavers.empty?

      bridged_pairs = []

      activity.transaction do
        leavers.first(ActivityExclusionService::MAX_PARTICIPANTS).each do |leaver_id|
          incoming = ActivityAssignment.find_by(activity: activity, recipient_id: leaver_id)
          outgoing = ActivityAssignment.find_by(activity: activity, giver_id: leaver_id)
          next if incoming.nil? || outgoing.nil?

          new_recipient = outgoing.recipient_id
          if ActivityExclusion.exists?(
            activity: activity,
            giver_id: incoming.giver_id,
            forbidden_recipient_id: new_recipient
          )
            raise ArgumentError, "Blind bridge blocked by exclusion; use Full Redraw or adjust exclusions"
          end

          outgoing.destroy!
          incoming.update!(recipient_id: new_recipient)
          bridged_pairs << { giver_id: incoming.giver_id, recipient_id: new_recipient }
        end

        raise ArgumentError, "Post-condition failed: bridge did not reconnect a giver" if bridged_pairs.empty?

        # Remove any dangling assignment edges for leavers.
        ActivityAssignment.where(activity: activity, giver_id: leavers).limit(500).delete_all
        ActivityAssignment.where(activity: activity, recipient_id: leavers).limit(500).delete_all
        activity.clear_dropout_recovery!
        AuditEvent.record!(
          actor: actor,
          action: "activity.blind_bridged",
          auditable: activity,
          metadata: { bridged_count: bridged_pairs.size }
        )
      end

      results = bridged_pairs.map do |pair|
        BlindBridgeResult.new(notified_giver_id: pair[:giver_id], new_recipient_id: pair[:recipient_id])
      end
      results.each { |result| ActivityNotifier.blind_bridged!(activity: activity, result: result) }
      results.first
    end

    # [REQ-ACT-003] Full Redraw among remaining accepted participants.
    def full_redraw!(activity:, actor:, seed: nil)
      raise ArgumentError, "Pre-condition failed: sealed secret_santa required" unless activity.sealed? && activity.secret_santa?
      raise ArgumentError, "Pre-condition failed: dropout recovery required" unless activity.needs_dropout_recovery?
      ActivityAdminService.send(:assert_admin!, activity, actor)

      remaining = activity.accepted_participants.limit(ActivityExclusionService::MAX_PARTICIPANTS).count
      if remaining < 3
        raise ArgumentError, "Pre-condition failed: minimum 3 accepted participants required to redraw; cancel the activity instead"
      end

      activity.transaction do
        ActivityAssignment.where(activity: activity).limit(2_048).delete_all
        activity.update!(status: "open", sealed_at: nil, needs_dropout_recovery: false)
        ActivityDrawService.draw!(activity: activity, actor: actor, seed: seed)
        AuditEvent.record!(
          actor: actor,
          action: "activity.full_redraw",
          auditable: activity,
          metadata: { seed: seed }
        )
      end

      raise "Post-condition failed: activity must be sealed after redraw" unless activity.reload.sealed?
      raise "Post-condition failed: dropout recovery must be clear" if activity.needs_dropout_recovery?
      ActivityNotifier.full_redraw!(activity: activity)

      activity
    end

    private

    def left_user_ids(activity)
      activity.participants.where(status: "left").limit(ActivityExclusionService::MAX_PARTICIPANTS).pluck(:user_id)
    end
  end
end
