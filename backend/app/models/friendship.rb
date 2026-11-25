# frozen_string_literal: true

# Bidirectional friendship model enforcing unordered unique pair integrity,
# 20 pending outgoing requests anti-spam cap, "Block Wins" checks, and
# transactional cleanup when either user blocks the other.
# Traceability: [REQ-SOC-001], [REQ-BLOCK-001], [REQ-BLOCK-002], [REQ-ADM-001]
class Friendship < ApplicationRecord
  STATUSES = %w[pending accepted].freeze
  MAX_PENDING_OUTGOING = 20

  belongs_to :requester, class_name: "User"
  belongs_to :addressee, class_name: "User"

  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :cannot_befriend_self
  validate :unordered_pair_must_be_unique, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }

  # [REQ-SOC-001] Returns the Friendship record (if any) between user_a and user_b in either direction.
  def self.between_users(user_a, user_b)
    return none if user_a.nil? || user_b.nil?

    where(requester_id: user_a.id, addressee_id: user_b.id)
      .or(where(requester_id: user_b.id, addressee_id: user_a.id))
  end

  # [REQ-SOC-001] Returns friendship status from viewer's perspective:
  # "none", "pending_outgoing", "pending_incoming", or "accepted".
  def self.status_between(viewer, target)
    return "none" if viewer.nil? || target.nil? || viewer.id == target.id

    record = between_users(viewer, target).first
    return "none" if record.nil?
    return "accepted" if record.status == "accepted"

    record.requester_id == viewer.id ? "pending_outgoing" : "pending_incoming"
  end

  # [REQ-SOC-001] [REQ-BLOCK-001] Creates a pending friend request enforcing all Pre-conditions.
  def self.request!(requester:, addressee:)
    validate_request_preconditions!(requester, addressee)

    record = create!(
      requester: requester,
      addressee: addressee,
      status: "pending"
    )

    raise "Post-condition failed: friendship must be pending" unless record.persisted? && record.status == "pending"

    record
  end

  # [REQ-SOC-001] [REQ-BLOCK-001] [REQ-ADM-001] Accepts a pending friend request as the addressee.
  def accept!(actor:)
    validate_accept_preconditions!(actor)

    transaction do
      update!(status: "accepted")
      AuditEvent.record!(
        actor: actor,
        action: "friendship.accepted",
        auditable: self,
        metadata: { requester_id: requester_id, addressee_id: addressee_id }
      )
    end

    raise "Post-condition failed: friendship must be accepted" unless status == "accepted"

    self
  end

  # [REQ-SOC-001] [REQ-ADM-001] Declines, cancels, or removes a friendship and records an AuditEvent.
  def remove!(actor:)
    raise ArgumentError, "Pre-condition failed: friendship must be persisted" unless persisted?
    unless actor && (actor.id == requester_id || actor.id == addressee_id)
      raise ArgumentError, "Pre-condition failed: actor must be a participant"
    end

    transaction do
      AuditEvent.record!(
        actor: actor,
        action: "friendship.removed",
        auditable: self,
        metadata: { requester_id: requester_id, addressee_id: addressee_id, previous_status: status }
      )
      destroy!
    end

    raise "Post-condition failed: friendship must be destroyed" unless destroyed?

    true
  end

  # [REQ-SOC-001] Returns true when both participants are active (non-discarded).
  def active_participants?
    !requester.discarded? && !addressee.discarded?
  end

  # [REQ-SOC-001] Serializes the friendship relative to the given viewer.
  def as_api_json(viewer:)
    other = requester_id == viewer.id ? addressee : requester
    {
      id: id,
      status: status,
      direction: requester_id == viewer.id ? "outgoing" : "incoming",
      friend: other.public_profile_json,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  def self.validate_request_preconditions!(requester, addressee)
    unless requester&.persisted? && addressee&.persisted? && !requester.discarded? && !addressee.discarded?
      raise ArgumentError, "Pre-condition failed: both users must be active and persisted"
    end
    raise ArgumentError, "Pre-condition failed: cannot befriend yourself" if requester.id == addressee.id
    raise ArgumentError, "Pre-condition failed: user is blocked" if UserBlock.blocked_between?(requester, addressee)

    outgoing_count = where(requester_id: requester.id, status: "pending").limit(MAX_PENDING_OUTGOING + 1).count
    return unless outgoing_count >= MAX_PENDING_OUTGOING

    raise ArgumentError, "Pre-condition failed: pending outgoing requests limit (#{MAX_PENDING_OUTGOING}) reached"
  end
  private_class_method :validate_request_preconditions!

  private

  def validate_accept_preconditions!(actor)
    raise ArgumentError, "Pre-condition failed: friendship must be pending" unless persisted? && status == "pending"
    raise ArgumentError, "Pre-condition failed: only addressee can accept" if actor.nil? || actor.id != addressee_id
    raise ArgumentError, "Pre-condition failed: user is blocked" if UserBlock.blocked_between?(requester, addressee)
  end

  def cannot_befriend_self
    return if requester_id.nil? || requester_id != addressee_id

    errors.add(:addressee_id, "cannot send a friend request to yourself")
  end

  def unordered_pair_must_be_unique
    return if requester_id.nil? || addressee_id.nil?

    exists = self.class.where(requester_id: requester_id, addressee_id: addressee_id)
                 .or(self.class.where(requester_id: addressee_id, addressee_id: requester_id))
                 .exists?
    errors.add(:base, "friendship or pending request already exists between these users") if exists
  end
end

UserBlock.register_cleanup_hook(:destroy_friendships) do |blocker, blocked|
  Friendship.between_users(blocker, blocked).delete_all
end
