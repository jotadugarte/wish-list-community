# frozen_string_literal: true

# Pundit policy for GiftRecord mutations and reads (Sprint 6).
# Traceability: [REQ-GIFT-001], [REQ-GIFT-002], [REQ-GIFT-003], [REQ-BLOCK-001]
class GiftRecordPolicy < ApplicationPolicy
  # [REQ-GIFT-001] Authenticated users may list their own gifts via Scope.
  def index?
    user.present? && !user.discarded?
  end

  # [REQ-GIFT-001] Gifter may mark delivered on their purchased_secret gift.
  def mark_delivered?

    gifter_on_status?("purchased_secret")
  end

  # [REQ-GIFT-001] [REQ-GIFT-003] Owner confirms delivery (Path 1) or marks received (Path 2).
  def confirm_received?
    owner_of_item?
  end

  alias owner_mark_received? confirm_received?

  # [REQ-GIFT-001] Gifter may view their own gift row (never spoilers for owner via this policy).
  def show?
    return false if user.nil? || user.discarded? || record.nil?

    record.gifter_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    MAX_SCOPE_ROWS = 500

    def resolve
      return scope.none if user.nil? || user.discarded?

      scope.where(gifter_id: user.id).limit(MAX_SCOPE_ROWS)
    end
  end

  private

  def gifter_on_status?(status)
    user.present? && !user.discarded? && record.present? &&
      record.gifter_id == user.id && record.status == status
  end

  def owner_of_item?
    return false if user.nil? || user.discarded? || record.nil? || record.item.blank?

    record.item.wishlist.owner_id == user.id
  end
end
