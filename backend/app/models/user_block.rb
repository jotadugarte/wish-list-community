# frozen_string_literal: true

# Directional user block enforcing the "Block Wins" invariant across the platform
# and executing transactional cascading cleanup hooks (destroying friendships,
# shares, and active reservations between the two users).
# Traceability: [REQ-BLOCK-001], [REQ-BLOCK-002], [REQ-ADM-001]
class UserBlock < ApplicationRecord
  MAX_CLEANUP_HOOKS = 20

  belongs_to :blocker, class_name: "User"
  belongs_to :blocked, class_name: "User"

  validates :blocker_id, uniqueness: { scope: :blocked_id }
  validate :cannot_block_self

  class << self
    # [REQ-BLOCK-002] Registry for cross-module cleanup callbacks executed when a block occurs.
    def cleanup_hooks
      @cleanup_hooks ||= {}
    end

    # [REQ-BLOCK-002] Registers a bounded cleanup hook (e.g., Friendship, WishlistShare, Reservation).
    def register_cleanup_hook(name, &block)
      raise ArgumentError, "Hook block required" unless block_given?
      raise "Max cleanup hooks (#{MAX_CLEANUP_HOOKS}) exceeded" if cleanup_hooks.size >= MAX_CLEANUP_HOOKS

      cleanup_hooks[name.to_sym] = block
    end

    # [REQ-BLOCK-002] Removes a registered cleanup hook.
    def unregister_cleanup_hook(name)
      cleanup_hooks.delete(name.to_sym)
    end

    # [REQ-BLOCK-001] Returns true if a block exists in EITHER direction between user_a and user_b.
    def blocked_between?(user_a, user_b)
      return false if user_a.nil? || user_b.nil?

      where(blocker_id: user_a.id, blocked_id: user_b.id)
        .or(where(blocker_id: user_b.id, blocked_id: user_a.id))
        .exists?
    end

    # [REQ-BLOCK-001] [REQ-BLOCK-002] [REQ-ADM-001] Transactionally blocks a user, runs cascading
    # cleanup hooks, and records an immutable AuditEvent.
    def block!(blocker:, blocked:)
      raise ArgumentError, "Pre-condition failed: both users must be persisted" unless blocker&.persisted? && blocked&.persisted?

      record = nil
      transaction do
        record = find_or_initialize_by(blocker: blocker, blocked: blocked)
        record.save!
        execute_cleanup_hooks!(blocker, blocked)
        AuditEvent.record!(
          actor: blocker,
          action: "user.blocked",
          auditable: record,
          metadata: { blocked_user_id: blocked.id }
        )
      end

      raise "Post-condition failed: block must be active" unless blocked_between?(blocker, blocked)

      record
    end

    private

    def execute_cleanup_hooks!(blocker, blocked)
      Friendship
      WishlistShare
      Reservation
      hooks = cleanup_hooks.values.first(MAX_CLEANUP_HOOKS)
      hooks.each do |hook|
        hook.call(blocker, blocked)
      end
    end
  end

  private

  def cannot_block_self
    return if blocker_id.nil? || blocker_id != blocked_id

    errors.add(:blocked_id, "cannot block yourself")
  end
end
