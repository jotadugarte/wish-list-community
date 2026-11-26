# frozen_string_literal: true

# Pundit policy for Item access — visibility follows WishlistPolicy; mutations owner-only.
# Traceability: [REQ-ITEM-001], [REQ-WISH-001], [REQ-BLOCK-001], [REQ-LIFE-001]
class ItemPolicy < ApplicationPolicy
  # [REQ-ITEM-001] [REQ-WISH-001] Index when the parent wishlist is visible to the viewer.
  def index?
    wishlist_visible?
  end

  # [REQ-ITEM-001] [REQ-WISH-001] [REQ-BLOCK-001] Show when wishlist show is allowed and item kept (or owner restore path).
  def show?
    return false if record.nil?
    return false if record.discarded? && !owner_of_item?
    wishlist_visible?
  end

  # [REQ-ITEM-001] Only the wishlist owner may create items.
  def create?
    owner_of_wishlist_active?
  end

  # [REQ-ITEM-001] Only the wishlist owner may update items.
  def update?
    owner_of_item_active?
  end

  # [REQ-LIFE-001] Only the wishlist owner may soft-delete items.
  def destroy?
    owner_of_item_active?
  end

  # [REQ-LIFE-001] Only the wishlist owner may restore within grace.
  def restore?
    owner_of_item? && record.discarded?
  end

  # [REQ-ITEM-001] Reorder and image detach are owner mutations.
  def reorder?
    owner_of_wishlist_active?
  end

  def manage_images?
    owner_of_item_active?
  end

  class Scope < ApplicationPolicy::Scope
    MAX_SCOPE_ROWS = 500

    # [REQ-WISH-001] Items whose parent wishlist the viewer may show.
    def resolve
      return scope.none if user.nil? || user.discarded?

      visible_wishlist_ids = WishlistPolicy::Scope.new(user, Wishlist).resolve.limit(MAX_SCOPE_ROWS).select(:id)
      scope.kept.where(wishlist_id: visible_wishlist_ids).limit(MAX_SCOPE_ROWS)
    end
  end

  private

  def wishlist_record
    record.is_a?(Wishlist) ? record : record.wishlist
  end

  def wishlist_visible?
    WishlistPolicy.new(user, wishlist_record).show?
  end

  def owner_of_wishlist_active?
    user.present? && !user.discarded? && wishlist_record.present? && !wishlist_record.discarded? &&
      wishlist_record.owner_id == user.id
  end

  def owner_of_item?
    user.present? && !user.discarded? && record.present? && record.wishlist.owner_id == user.id
  end

  def owner_of_item_active?
    owner_of_item? && !record.discarded? && !record.wishlist.discarded?
  end
end
