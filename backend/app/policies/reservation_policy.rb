# frozen_string_literal: true

# Pundit policy for secret reservations — create requires wishlist access; mutations reserver-only.
# Traceability: [REQ-RES-001], [REQ-RES-004], [REQ-WISH-002], [REQ-BLOCK-001]
class ReservationPolicy < ApplicationPolicy
  # [REQ-RES-001] [REQ-WISH-002] [REQ-BLOCK-001] Create when viewer may see the item wishlist and is not the owner.
  def create?
    return false if user.nil? || user.discarded?
    return false if record.item.blank? || record.item.discarded?
    return false if record.item.wishlist.blank? || record.item.wishlist.discarded?
    return false if record.item.wishlist.owner_id == user.id
    return false if blocked_between?(record.item.wishlist.owner)

    WishlistPolicy.new(user, record.item.wishlist).show?
  end

  # [REQ-RES-001] Only the reserver may extend note/date.
  def update?
    reserver_active_hold?
  end

  # [REQ-RES-001] Only the reserver may voluntarily cancel.
  def destroy?
    reserver_active_hold?
  end

  # [REQ-RES-004] Show own reservation rows.
  def show?
    user.present? && !user.discarded? && record.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    MAX_SCOPE_ROWS = 500

    # [REQ-RES-004] Current user's active/grace reservations only.
    def resolve
      return scope.none if user.nil? || user.discarded?

      scope.where(user_id: user.id, status: ReservationStatus::ACTIVE_HOLD).limit(MAX_SCOPE_ROWS)
    end
  end

  private

  def reserver_active_hold?
    user.present? && !user.discarded? && record.present? && record.user_id == user.id &&
      ReservationStatus::ACTIVE_HOLD.include?(record.status)
  end
end
