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

  def self.validate_submit_preconditions!(reporter, reportable)
    unless reporter&.persisted? && reportable&.persisted?
      raise ArgumentError, "Pre-condition failed: reporter and reportable must be persisted"
    end
    return unless reportable.is_a?(User) && reporter.id == reportable.id

    raise ArgumentError, "Pre-condition failed: cannot report yourself"
  end
  private_class_method :validate_submit_preconditions!

  private

  def validate_reason_value_object
    return if reason.blank?

    ReportReason.new(reason)
  rescue ArgumentError => e
    errors.add(:reason, e.message)
  end

  def cannot_report_self
    return unless reportable_type == "User" && reporter_id.present? && reporter_id == reportable_id

    errors.add(:reportable_id, "cannot report yourself")
  end

  def unique_pending_report_for_target
    return if reporter_id.nil? || reportable_type.blank? || reportable_id.nil?

    exists = self.class.where(
      reporter_id: reporter_id,
      reportable_type: reportable_type,
      reportable_id: reportable_id,
      status: "pending"
    ).exists?
    errors.add(:base, "a pending report already exists for this target") if exists
  end
end
