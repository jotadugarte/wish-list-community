# frozen_string_literal: true

# Post-draw giver → recipient edge for Secret Santa (never listed wholesale to admins).
# Traceability: [REQ-ACT-001], [REQ-ACT-004]
class ActivityAssignment < ApplicationRecord
  belongs_to :activity
  belongs_to :giver, class_name: "User"
  belongs_to :recipient, class_name: "User"

  validates :giver_id, uniqueness: { scope: :activity_id }
  validates :recipient_id, uniqueness: { scope: :activity_id }
  validate :giver_must_differ_from_recipient

  private

  def giver_must_differ_from_recipient
    return if giver_id.nil? || recipient_id.nil? || giver_id != recipient_id

    errors.add(:recipient_id, "cannot gift self")
  end
end
