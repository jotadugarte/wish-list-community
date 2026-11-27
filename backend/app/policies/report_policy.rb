# frozen_string_literal: true

# Policy governing abuse Report submission.
# Traceability: [REQ-SOC-001], [REQ-DISC-001], [REQ-WISH-001], [REQ-BLOCK-001]
class ReportPolicy < ApplicationPolicy
  # [REQ-SOC-001] [REQ-DISC-001] Permits an active user to report another entity
  # (User: not self; Wishlist: currently viewable and not owner — O1A/O4A).
  def create?
    return false if user.nil? || user.discarded? || record.nil? || record.reportable.nil?
    return false if record.reporter_id != user.id

    reportable = record.reportable
    return create_for_user?(reportable) if reportable.is_a?(User)
    return create_for_wishlist?(reportable) if reportable.is_a?(Wishlist)

    false
  end

  private

  def create_for_user?(target)
    target.id != user.id
  end

  def create_for_wishlist?(wishlist)
    return false if wishlist.owner_id == user.id
    return false unless WishlistPolicy.new(user, wishlist).show?

    true
  end
end
