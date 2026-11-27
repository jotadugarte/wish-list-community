# frozen_string_literal: true

# Reusable soft-delete concern enforcing the 30-day restoration window and bounded
# lifecycle callbacks (on_soft_delete / on_restore) so soft-deleting a Wishlist or Item
# permanently cancels active reservations and restoring never resurrects ghost reservations.
# Traceability: [REQ-LIFE-001], [REQ-LIFE-002]
module SoftDeletable
  extend ActiveSupport::Concern

  RESTORE_GRACE_WINDOW = 30.days
  MAX_LIFECYCLE_HOOKS = 20

  included do
    scope :kept, -> { where(discarded_at: nil) }
    scope :discarded, -> { where.not(discarded_at: nil) }
  end

  class_methods do
    # [REQ-LIFE-001] Bounded registry of hooks executed inside the soft_delete! transaction.
    def soft_delete_hooks
      @soft_delete_hooks ||= {}
    end

    # [REQ-LIFE-001] Bounded registry of hooks executed inside the restore! transaction.
    def restore_hooks
      @restore_hooks ||= {}
    end

    # [REQ-LIFE-001] Registers a soft-delete callback (e.g., permanently canceling active reservations).
    def register_soft_delete_hook(name, &block)
      raise ArgumentError, "Hook block required" unless block_given?
      raise "Max lifecycle hooks (#{MAX_LIFECYCLE_HOOKS}) exceeded" if soft_delete_hooks.size >= MAX_LIFECYCLE_HOOKS

      soft_delete_hooks[name.to_sym] = block
    end

    def unregister_soft_delete_hook(name)
      soft_delete_hooks.delete(name.to_sym)
    end

    # [REQ-LIFE-001] Registers a restore callback (e.g., restoring child items without touching reservations).
    def register_restore_hook(name, &block)
      raise ArgumentError, "Hook block required" unless block_given?
      raise "Max lifecycle hooks (#{MAX_LIFECYCLE_HOOKS}) exceeded" if restore_hooks.size >= MAX_LIFECYCLE_HOOKS

      restore_hooks[name.to_sym] = block
    end

    def unregister_restore_hook(name)
      restore_hooks.delete(name.to_sym)
    end
  end

  # [REQ-LIFE-001] Returns true if the record is currently soft-deleted.
  def discarded?
    discarded_at.present?
  end

  # [REQ-LIFE-001] [REQ-LIFE-002] Soft-deletes the record, runs registered on_soft_delete hooks,
  # and logs an immutable AuditEvent (hooks may contribute metadata via merge_soft_delete_audit_metadata!).
  def soft_delete!(actor: nil)
    raise ArgumentError, "Pre-condition failed: record must be persisted" unless persisted?

    transaction do
      @soft_delete_audit_metadata = {}
      update!(discarded_at: Time.current)
      run_lifecycle_hooks!(self.class.soft_delete_hooks)
      AuditEvent.record!(
        actor: actor || (is_a?(User) ? self : nil),
        action: "#{model_name.singular}.soft_deleted",
        auditable: self,
        metadata: soft_delete_audit_metadata
      )
    end

    raise "Post-condition failed: discarded_at must be present" unless discarded?

    true
  end

  # [REQ-LIFE-002] Lets soft-delete hooks attach bounded metadata (e.g. cascaded wishlist ids).
  def merge_soft_delete_audit_metadata!(extra)
    raise ArgumentError, "Pre-condition failed: metadata must be a Hash" unless extra.is_a?(Hash)

    @soft_delete_audit_metadata = soft_delete_audit_metadata.merge(extra)
  end

  # [REQ-LIFE-001] [REQ-LIFE-002] Restores a soft-deleted record within the 30-day restoration window,
  # runs registered on_restore hooks (which leave reservations untouched), and logs an AuditEvent.
  # [REQ-ADM-001] Member actors cannot restore a soft-delete whose latest AuditEvent actor was an admin (O4A).
  def restore!(actor: nil)
    raise ArgumentError, "Pre-condition failed: record must be persisted" unless persisted?

    unless discarded?
      errors.add(:base, "Record is not soft-deleted")
      return false
    end

    unless restorable?
      errors.add(:base, "Restoration window of 30 days has expired")
      return false
    end

    if soft_deleted_by_admin? && !admin_actor?(actor)
      errors.add(:base, "Admin soft-delete can only be restored by an admin")
      return false
    end

    transaction do
      update!(discarded_at: nil)
      run_lifecycle_hooks!(self.class.restore_hooks)
      AuditEvent.record!(
        actor: actor || (is_a?(User) ? self : nil),
        action: "#{model_name.singular}.restored",
        auditable: self
      )
    end

    raise "Post-condition failed: discarded_at must be nil" if discarded?

    true
  end

  # [REQ-LIFE-002] Returns true if the record is discarded and within the 30-day grace window.
  def restorable?
    discarded? && discarded_at >= RESTORE_GRACE_WINDOW.ago
  end

  # [REQ-ADM-001] True when the latest soft_deleted AuditEvent was performed by an admin.
  def soft_deleted_by_admin?
    event = latest_soft_delete_event
    event&.actor&.role == "admin"
  end

  private

  def soft_delete_audit_metadata
    @soft_delete_audit_metadata || {}
  end

  def latest_soft_delete_event
    AuditEvent.where(auditable_type: self.class.name, auditable_id: id, action: "#{model_name.singular}.soft_deleted")
              .order(created_at: :desc, id: :desc)
              .limit(1)
              .first
  end

  def admin_actor?(actor)
    actor.present? && actor.respond_to?(:role) && actor.role == "admin"
  end

  def run_lifecycle_hooks!(registry)
    hooks = registry.values.first(MAX_LIFECYCLE_HOOKS)
    hooks.each do |hook|
      hook.call(self)
    end
  end
end
