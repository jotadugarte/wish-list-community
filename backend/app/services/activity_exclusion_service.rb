# frozen_string_literal: true

# Pair exclusions and bounded deterministic solvability for Secret Santa graphs.
# Traceability: [REQ-ACT-002], [REQ-ACT-004]
class ActivityExclusionService
  MAX_PARTICIPANTS = 64
  MAX_EXCLUSIONS = 2_048
  MAX_DFS_NODES = 50_000

  class << self
    # [REQ-ACT-002] Adds a directed exclusion (giver cannot gift forbidden_recipient).
    def add!(activity:, actor:, giver:, forbidden_recipient:)
      raise ArgumentError, "Pre-condition failed: activity required" if activity.nil?
      raise ArgumentError, "Pre-condition failed: only secret_santa supports exclusions" unless activity.secret_santa?
      raise ArgumentError, "Pre-condition failed: cannot exclude self" if giver.id == forbidden_recipient.id
      ActivityAdminService.send(:assert_admin!, activity, actor)

      unless accepted?(activity, giver) && accepted?(activity, forbidden_recipient)
        raise ArgumentError, "Pre-condition failed: both users must be accepted participants"
      end

      if ActivityExclusion.exists?(activity: activity, giver: giver, forbidden_recipient: forbidden_recipient)
        raise ArgumentError, "Pre-condition failed: duplicate exclusion already exists"
      end

      exclusion = ActivityExclusion.create!(
        activity: activity,
        giver: giver,
        forbidden_recipient: forbidden_recipient
      )
      raise "Post-condition failed: exclusion must persist" unless exclusion.persisted?

      exclusion
    end

    # [REQ-ACT-002] Removes an exclusion.
    def remove!(activity:, actor:, exclusion:)
      raise ArgumentError, "Pre-condition failed: exclusion mismatch" unless exclusion.activity_id == activity.id
      ActivityAdminService.send(:assert_admin!, activity, actor)

      exclusion.destroy!
      raise "Post-condition failed: exclusion must be gone" if ActivityExclusion.exists?(id: exclusion.id)

      true
    end

    # [REQ-ACT-002] [REQ-ACT-004] Bounded check that a single Hamiltonian cycle exists.
    def solvable?(activity:)
      ids = accepted_ids(activity)
      return false if ids.size < 3
      return false if ids.size > MAX_PARTICIPANTS

      forbidden = forbidden_map(activity, ids)
      find_cycle(ids, forbidden) != nil
    end

    # [REQ-ACT-002] [REQ-ACT-004] Raises when the exclusion graph is not solvable.
    def assert_solvable!(activity:)
      return true if solvable?(activity: activity)

      raise ArgumentError, "Exclusion graph is not solvable for a single Hamiltonian cycle"
    end

    # [REQ-ACT-004] Returns one Hamiltonian cycle as giver=>recipient hash, or nil.
    def find_hamiltonian_cycle(activity:)
      ids = accepted_ids(activity)
      return nil if ids.size < 3 || ids.size > MAX_PARTICIPANTS

      find_cycle(ids, forbidden_map(activity, ids))
    end

    private

    def accepted?(activity, user)
      activity.participants.where(user_id: user.id, status: "accepted").exists?
    end

    def accepted_ids(activity)
      activity.participants.where(status: "accepted").order(:id).limit(MAX_PARTICIPANTS).pluck(:user_id)
    end

    def forbidden_map(activity, ids)
      map = ids.to_h { |id| [ id, Set.new([ id ]) ] }
      ActivityExclusion.where(activity_id: activity.id).limit(MAX_EXCLUSIONS).find_each do |exclusion|
        next unless map.key?(exclusion.giver_id)

        map[exclusion.giver_id] << exclusion.forbidden_recipient_id
      end
      map
    end

    def find_cycle(ids, forbidden)
      start = ids.first
      visited_nodes = 0
      path = [ start ]
      used = { start => true }

      dfs = lambda do
        visited_nodes += 1
        return nil if visited_nodes > MAX_DFS_NODES

        if path.size == ids.size
          return path.dup if !forbidden[path.last].include?(start)

          return nil
        end

        ids.each do |candidate|
          next if used[candidate]
          next if forbidden[path.last].include?(candidate)

          used[candidate] = true
          path << candidate
          found = dfs.call
          return found if found

          path.pop
          used.delete(candidate)
        end
        nil
      end

      cycle_path = dfs.call
      return nil if cycle_path.nil?

      cycle_path.each_with_index.to_h { |giver, index| [ giver, cycle_path[(index + 1) % cycle_path.size] ] }
    end
  end
end
