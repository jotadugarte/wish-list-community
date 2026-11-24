# frozen_string_literal: true

# Solid Queue background job that permanently anonymizes PII for user accounts
# soft-deleted more than 30 days ago (App Store & Google Play account deletion compliance).
# Traceability: [REQ-LIFE-002]
class PiiPurgeJob < ApplicationJob
  MAX_PURGE_BATCH = 500

  queue_as :default

  # [REQ-LIFE-002] Purges expired soft-deleted accounts with an explicit execution bound.
  def perform
    expired_scope = User.discarded
                        .where("discarded_at < ?", SoftDeletable::RESTORE_GRACE_WINDOW.ago)
                        .where.not("email_address LIKE ?", "purged_%")
                        .limit(MAX_PURGE_BATCH)

    purged_count = 0
    expired_scope.each do |user|
      user.anonymize_pii!
      purged_count += 1
    end

    raise "Post-condition failed: batch bound exceeded" if purged_count > MAX_PURGE_BATCH

    purged_count
  end
end
