# frozen_string_literal: true

# Seedable Secret Santa draw producing a single Hamiltonian cycle of assignments.
# Traceability: [REQ-ACT-001], [REQ-ACT-004]
class ActivityDrawService
  MAX_ATTEMPTS = 64

  class << self
    # [REQ-ACT-001] [REQ-ACT-004] Runs the draw, seals the activity, persists assignments.
    def draw!(activity:, actor:, seed: nil)
      raise ArgumentError, "Pre-condition failed: activity required" if activity.nil?
      raise ArgumentError, "Pre-condition failed: must be secret_santa" unless activity.secret_santa?
      raise ArgumentError, "Pre-condition failed: already sealed" if activity.sealed?
      ActivityAdminService.send(:assert_admin!, activity, actor)

      ids = activity.accepted_participants.order(:id).limit(ActivityExclusionService::MAX_PARTICIPANTS).pluck(:user_id)
      raise ArgumentError, "Pre-condition failed: minimum 3 accepted participants required" if ids.size < 3

      ActivityExclusionService.assert_solvable!(activity: activity)
      rng = Random.new(Integer(seed || SecureRandom.random_number(1 << 31)))
      cycle = nil
      attempts = 0
      while cycle.nil? && attempts < MAX_ATTEMPTS
        attempts += 1
        ordered = ids.shuffle(random: rng)
        cycle = cycle_from_order(ordered, activity)
      end
      cycle ||= ActivityExclusionService.find_hamiltonian_cycle(activity: activity)
      raise ArgumentError, "Post-condition failed: could not find Hamiltonian cycle" if cycle.nil?

      activity.transaction do
        ActivityParticipant.expire_pending_invites!(activity)
        cycle.each do |giver_id, recipient_id|
          ActivityAssignment.create!(activity: activity, giver_id: giver_id, recipient_id: recipient_id)
        end
        activity.update!(status: "sealed", sealed_at: Time.current, needs_dropout_recovery: false)
        AuditEvent.record!(
          actor: actor,
          action: "activity.drawn",
          auditable: activity,
          metadata: { participant_count: ids.size, seed: seed }
        )
      end

      raise "Post-condition failed: activity must be sealed" unless activity.reload.sealed?
      raise "Post-condition failed: assignment count mismatch" unless ActivityAssignment.where(activity: activity).count == ids.size
      ActivityNotifier.drawn!(activity: activity)

      cycle
    end

    # [REQ-ACT-004] Returns the viewer's own assignment only.
    def assignment_for(activity:, viewer:)
      raise ArgumentError, "Pre-condition failed: viewer required" if viewer.nil?

      ActivityAssignment.find_by(activity: activity, giver_id: viewer.id)
    end

    # [REQ-ACT-004] Admins never receive the full assignment map.
    def assignments_for_admin(activity:, actor:)
      ActivityAdminService.send(:assert_admin!, activity, actor)
      []
    end

    private

    def cycle_from_order(ordered, activity)
      forbidden = ActivityExclusion.where(activity_id: activity.id)
                                   .limit(ActivityExclusionService::MAX_EXCLUSIONS)
                                   .pluck(:giver_id, :forbidden_recipient_id)
                                   .each_with_object(Hash.new { |h, k| h[k] = Set.new }) do |(g, r), memo|
        memo[g] << r
      end

      map = {}
      ordered.each_with_index do |giver_id, index|
        recipient_id = ordered[(index + 1) % ordered.size]
        return nil if giver_id == recipient_id
        return nil if forbidden[giver_id].include?(recipient_id)

        map[giver_id] = recipient_id
      end
      map
    end
  end
end
