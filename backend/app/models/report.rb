# frozen_string_literal: true

# Polymorphic abuse report model supporting User (Sprint 2) and Wishlist (Sprint 7)
# reporting with ReportReason Value Object validation, duplicate pending report
# prevention, and immutable AuditEvent logging.
# Traceability: [REQ-SOC-001], [REQ-DISC-001], [REQ-ADM-001]
class Report < ApplicationRecord
  STATUSES = %w[pending reviewed dismissed].freeze
  MAX_DETAILS_LENGTH = 1000

  belongs_to :reporter, class_name: "User"
  belongs_to :reportable, polymorphic: true

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :reason, presence: true
  validates :details, length: { maximum: MAX_DETAILS_LENGTH }, allow_blank: true
  validate :validate_reason_value_object
  validate :cannot_report_self
  validate :unique_pending_report_for_target, on: :create

  # [REQ-SOC-001] [REQ-DISC-001] Returns the ReportReason Value Object.
  def reason_vo
    ReportReason.new(reason)
  end

  # [REQ-SOC-001] [REQ-DISC-001] [REQ-ADM-001] Submits a new pending abuse report and records an AuditEvent.
  def self.submit!(reporter:, reportable:, reason:, details: nil)
    validate_submit_preconditions!(reporter, reportable)
    reason_vo = ReportReason.new(reason)

    record = nil
    transaction do
      record = create!(
        reporter: reporter,
        reportable: reportable,
        reason: reason_vo.value,
        details: details.to_s.strip.presence,
        status: "pending"
      )
      AuditEvent.record!(
        actor: reporter,
        action: "report.created",
        auditable: record,
        metadata: {
          reportable_type: record.reportable_type,
          reportable_id: record.reportable_id,
          reason: reason_vo.value
        }
      )
    end

    raise "Post-condition failed: report must be persisted as pending" unless record.persisted? && record.status == "pending"

    record
  end

  # [REQ-SOC-001] Serializes the report for API responses.
  def as_api_json
    {
      id: id,
      reportable_type: reportable_type,
      reportable_id: reportable_id,
      reason: reason,
      details: details,
      status: status,
      created_at: created_at
    }
  end

  # [REQ-ADM-001] Reopens a dismissed report to pending (FC1 KEEP); never mutates old AuditEvents.
  def reopen!(actor:)
    validate_triage_actor!(actor)
    raise ArgumentError, "Pre-condition failed: report must be dismissed" unless status == "dismissed"
    ensure_no_other_pending_for_target!

    transaction do
      update!(status: "pending")
      AuditEvent.record!(actor: actor, action: "report.reopened", auditable: self)
    end

    raise "Post-condition failed: report must be pending" unless status == "pending"

    true
  end

  # [REQ-ADM-001] Dismisses a pending report without enforcement; no Notification (O7A).
  def dismiss!(actor:)
    validate_triage_actor!(actor)
    raise ArgumentError, "Pre-condition failed: report must be pending" unless status == "pending"

    transaction do
      update!(status: "dismissed")
      AuditEvent.record!(actor: actor, action: "report.dismissed", auditable: self)
    end

    raise "Post-condition failed: report must be dismissed" unless status == "dismissed"

    true
  end

  # [REQ-ADM-001] Suspends target_user and marks the report reviewed; no Notification (O7A).
  def review_with_suspend!(actor:, target_user:)
    validate_enforcement_target!(actor, target_user)

    transaction do
      target_user.suspend!(actor: actor)
      mark_reviewed!(actor: actor, metadata: { enforcement: "suspend", target_user_id: target_user.id })
    end

    raise "Post-condition failed: report must be reviewed" unless status == "reviewed"
    raise "Post-condition failed: target must be suspended" unless target_user.suspended?

    true
  end

  # [REQ-ADM-001] [REQ-LIFE-001] Soft-deletes target account (30-day SoftDeletable) and reviews report.
  def review_with_soft_delete_user!(actor:, target_user:)
    validate_enforcement_target!(actor, target_user)
    raise ArgumentError, "Pre-condition failed: cannot soft-delete the last remaining admin" if last_unsuspended_admin?(target_user)

    transaction do
      target_user.soft_delete!(actor: actor, admin_enforcement: true)
      mark_reviewed!(actor: actor, metadata: { enforcement: "soft_delete_user", target_user_id: target_user.id })
    end

    raise "Post-condition failed: report must be reviewed" unless status == "reviewed"
    raise "Post-condition failed: target must be discarded" unless target_user.discarded?

    true
  end

  # [REQ-ADM-001] [REQ-DISC-001] [REQ-LIFE-001] Soft-deletes reported wishlist and marks report reviewed.
  def review_with_soft_delete_wishlist!(actor:, wishlist:)
    validate_triage_actor!(actor)
    raise ArgumentError, "Pre-condition failed: wishlist must be persisted" unless wishlist&.persisted?
    raise ArgumentError, "Pre-condition failed: report must be pending" unless status == "pending"
    unless reportable_type == "Wishlist" && reportable_id == wishlist.id
      raise ArgumentError, "Pre-condition failed: wishlist must match reportable"
    end

    transaction do
      wishlist.soft_delete!(actor: actor, admin_enforcement: true)
      mark_reviewed!(actor: actor, metadata: { enforcement: "soft_delete_wishlist", wishlist_id: wishlist.id })
    end

    raise "Post-condition failed: report must be reviewed" unless status == "reviewed"
    raise "Post-condition failed: wishlist must be discarded" unless wishlist.discarded?

    true
  end

  def self.validate_submit_preconditions!(reporter, reportable)
    unless reporter&.persisted? && reportable&.persisted?
      raise ArgumentError, "Pre-condition failed: reporter and reportable must be persisted"
    end
    if reportable.is_a?(User) && reporter.id == reportable.id
      raise ArgumentError, "Pre-condition failed: cannot report yourself"
    end
    return unless reportable.is_a?(Wishlist) && reporter.id == reportable.owner_id

    raise ArgumentError, "Pre-condition failed: cannot report your own wishlist"
  end
  private_class_method :validate_submit_preconditions!

  private

  def validate_triage_actor!(actor)
    raise ArgumentError, "Pre-condition failed: actor must be persisted" unless actor&.persisted?
    raise ArgumentError, "Pre-condition failed: actor must be an admin" unless actor.role == "admin"
  end

  def validate_enforcement_target!(actor, target_user)
    validate_triage_actor!(actor)
    raise ArgumentError, "Pre-condition failed: target_user must be persisted" unless target_user&.persisted?
    raise ArgumentError, "Pre-condition failed: report must be pending" unless status == "pending"
    raise ArgumentError, "Pre-condition failed: cannot enforce against yourself" if actor.id == target_user.id
    raise ArgumentError, "Pre-condition failed: target_user must match reportable" unless target_matches_reportable?(target_user)
  end

  def target_matches_reportable?(target_user)
    if reportable_type == "User"
      reportable_id == target_user.id
    elsif reportable_type == "Wishlist"
      reportable.is_a?(Wishlist) && reportable.owner_id == target_user.id
    else
      false
    end
  end

  def last_unsuspended_admin?(target_user)
    return false unless target_user.role == "admin" && !target_user.suspended?

    User.kept.where(role: "admin").where(suspended_at: nil).where.not(id: target_user.id).limit(1).none?
  end

  def mark_reviewed!(actor:, metadata: {})
    update!(status: "reviewed")
    AuditEvent.record!(
      actor: actor,
      action: "report.reviewed",
      auditable: self,
      metadata: metadata
    )
  end

  def ensure_no_other_pending_for_target!
    conflict = self.class.where(
      reporter_id: reporter_id,
      reportable_type: reportable_type,
      reportable_id: reportable_id,
      status: "pending"
    ).where.not(id: id).exists?
    return unless conflict

    errors.add(:base, I18n.t("admin.errors.pending_report_exists"))
    raise ActiveRecord::RecordInvalid, self
  end

  def validate_reason_value_object
    return if reason.blank?

    ReportReason.new(reason)
  rescue ArgumentError => e
    errors.add(:reason, e.message)
  end

  def cannot_report_self
    if reportable_type == "User" && reporter_id.present? && reporter_id == reportable_id
      errors.add(:reportable_id, "cannot report yourself")
      return
    end
    return unless reportable_type == "Wishlist" && reporter_id.present? && reportable.is_a?(Wishlist)
    return unless reporter_id == reportable.owner_id

    errors.add(:reportable_id, "cannot report your own wishlist")
  end

  def unique_pending_report_for_target
    return if reporter_id.nil? || reportable_type.blank? || reportable_id.nil?

    exists = self.class.where(
      reporter_id: reporter_id,
      reportable_type: reportable_type,
      reportable_id: reportable_id,
      status: "pending"
    ).exists?
    errors.add(:base, I18n.t("admin.errors.pending_report_exists")) if exists
  end
end
