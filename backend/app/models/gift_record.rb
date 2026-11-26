# frozen_string_literal: true

# Dual-path gift fulfillment + optional thank-you + admin purchase link (Sprint 6).
# Traceability: [REQ-GIFT-001], [REQ-GIFT-002], [REQ-GIFT-003], [REQ-GIFT-004], [REQ-ADM-001], [REQ-RES-002]
class GiftRecord < ApplicationRecord
  belongs_to :item
  belongs_to :gifter, class_name: "User", optional: true

  validates :status, presence: true
  validate :status_must_be_allowed
  validate :thank_you_note_must_be_valid
  validate :purchase_link_ref_must_be_valid

  # [REQ-GIFT-001] Status Value Object for the stored lifecycle status.
  def status_vo
    GiftStatus.new(status)
  end

  # [REQ-GIFT-002] Open gifts that block availability for third parties.
  def self.open_for_item(item_id)
    where(item_id: item_id, status: GiftStatus::OPEN).limit(5)
  end

  private

  def status_must_be_allowed
    GiftStatus.new(status)
  rescue ArgumentError
    errors.add(:status, "is not included in the list")
  end

  def thank_you_note_must_be_valid
    return if thank_you_note.blank?

    ThankYouNote.new(thank_you_note)
  rescue ArgumentError
    errors.add(:thank_you_note, "is invalid")
  end

  def purchase_link_ref_must_be_valid
    return if purchase_link_ref.blank?

    PurchaseLinkRef.new(purchase_link_ref)
  rescue ArgumentError
    errors.add(:purchase_link_ref, "is invalid")
  end
end
