# frozen_string_literal: true

# Policy governing abuse Report submission.
# Traceability: [REQ-SOC-001], [REQ-DISC-001]
class ReportPolicy < ApplicationPolicy
  # [REQ-SOC-001] [REQ-DISC-001] Permits an active user to report another entity (except themselves).
  def create?
    return false if user.nil? || user.discarded? || record.nil? || record.reportable.nil?
    return false if record.reporter_id != user.id
    return false if record.reportable.is_a?(User) && record.reportable.id == user.id

    true
  end
end
