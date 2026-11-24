# frozen_string_literal: true

# Append-only immutable audit trail for critical domain actions (blocks, reservations,
# gifts, and admin moderation).
# Traceability: [REQ-ADM-001]
class AuditEvent < ApplicationRecord
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :auditable, polymorphic: true

  validates :action, presence: true
  validates :auditable_type, presence: true
  validates :auditable_id, presence: true

  before_destroy :prevent_destruction

  # [REQ-ADM-001] Records a new immutable audit event.
  def self.record!(actor:, action:, auditable:, metadata: {})
    raise ArgumentError, "Pre-condition failed: auditable must be present" if auditable.nil?

    event = create!(
      actor: actor,
      action: action.to_s,
      auditable: auditable,
      metadata: metadata || {}
    )

    raise "Post-condition failed: audit event must be persisted" unless event.persisted?

    event
  end

  # [REQ-ADM-001] Enforces strict immutability once persisted.
  def readonly?
    persisted?
  end

  private

  def prevent_destruction
    raise ActiveRecord::ReadOnlyRecord, "AuditEvent records are immutable and cannot be destroyed"
  end
end
