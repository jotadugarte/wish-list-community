# frozen_string_literal: true

# Pair exclusion: giver cannot be assigned forbidden_recipient in Secret Santa.
# Traceability: [REQ-ACT-002]
class ActivityExclusion < ApplicationRecord
  belongs_to :activity
  belongs_to :giver, class_name: "User"
  belongs_to :forbidden_recipient, class_name: "User"

  validates :giver_id, uniqueness: { scope: [ :activity_id, :forbidden_recipient_id ] }
  validate :giver_must_differ_from_recipient

  private

  def giver_must_differ_from_recipient
    return if giver_id.nil? || forbidden_recipient_id.nil? || giver_id != forbidden_recipient_id

    errors.add(:forbidden_recipient_id, "cannot exclude self")
  end
end
