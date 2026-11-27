# frozen_string_literal: true

# Pundit policy for Wishlist anti-stalking visibility (4-actor matrix) and owner mutations.
# Traceability: [REQ-WISH-001], [REQ-BLOCK-001], [REQ-WISH-003]
class WishlistPolicy < ApplicationPolicy
  # [REQ-WISH-001] Authenticated owners can list their own wishlists via controller scoping.
  def index?
    user.present? && !user.discarded?
  end

  # [REQ-WISH-001] [REQ-BLOCK-001] Show when owner, accepted friend on friends mode,
  # or sharee on shared mode — never when blocked either direction.
  def show?
    return false if user.nil? || user.discarded? || record.nil? || record.discarded?
    return false if record.owner.discarded?
    return true if owner?
    return false if blocked_between?(record.owner)

    friends_mode_access? || shared_mode_access?
  end

  # [REQ-WISH-001] Only the owner may create wishlists for themselves.
  def create?
    user.present? && !user.discarded?
  end

  # [REQ-WISH-001] Only the owner may update privacy, title, or event_date.
  def update?
    owner_active?
  end

  # [REQ-LIFE-001] Only the owner may soft-delete.
  def destroy?
    owner_active?
  end

  # [REQ-LIFE-001] [REQ-ADM-001] Owner may restore within grace unless soft-delete was admin-enforced (O4A).
  def restore?
    owner_of_record? && record.discarded? && !record.soft_deleted_by_admin?
  end

  # [REQ-WISH-002] [REQ-WISH-006] Only the owner may rotate the Secret Link token.
  def rotate_share_token?
    owner_active?
  end

  # [REQ-WISH-003] Only the owner may manage explicit shares.
  def manage_shares?
    owner_active?
  end

  class Scope < ApplicationPolicy::Scope
    MAX_SCOPE_ROWS = 500

    # [REQ-WISH-001] [REQ-BLOCK-001] Wishlists the viewer may see: owned, friends-mode of
    # accepted friends (non-blocked), or shared-mode with an explicit/secret_link share.
    def resolve
      return scope.none if user.nil? || user.discarded?

      kept_with_active_owner = scope.kept.where(owner_id: User.kept.select(:id))
      owned = kept_with_active_owner.where(owner_id: user.id)
      friend_ids = accepted_friend_ids
      friends_mode = kept_with_active_owner.where(owner_id: friend_ids, privacy_mode: "friends")
      shared_mode = shared_mode_for_viewer(kept_with_active_owner)

      owned.or(friends_mode).or(shared_mode).limit(MAX_SCOPE_ROWS)
    end

    private

    def accepted_friend_ids
      friendships = Friendship.accepted
                              .where(requester_id: user.id)
                              .or(Friendship.accepted.where(addressee_id: user.id))
                              .limit(MAX_SCOPE_ROWS)
      ids = friendships.map { |f| f.requester_id == user.id ? f.addressee_id : f.requester_id }
      return [] if ids.empty?

      blocked = UserBlock.where(blocker_id: user.id, blocked_id: ids)
                         .or(UserBlock.where(blocked_id: user.id, blocker_id: ids))
                         .limit(MAX_SCOPE_ROWS)
                         .flat_map { |b| [ b.blocker_id, b.blocked_id ] }
                         .uniq
      ids - blocked - [ user.id ]
    end

    def shared_mode_for_viewer(kept_with_active_owner)
      shared_ids = WishlistShare.where(user_id: user.id).limit(MAX_SCOPE_ROWS).select(:wishlist_id)
      relation = kept_with_active_owner.where(id: shared_ids, privacy_mode: "shared")
      owner_ids = relation.limit(MAX_SCOPE_ROWS).distinct.pluck(:owner_id)
      return relation.none if owner_ids.empty?

      blocked_owner_ids = UserBlock.where(blocker_id: user.id, blocked_id: owner_ids)
                                   .or(UserBlock.where(blocked_id: user.id, blocker_id: owner_ids))
                                   .limit(MAX_SCOPE_ROWS)
                                   .flat_map { |b| [ b.blocker_id, b.blocked_id ] }
                                   .uniq - [ user.id ]
      relation.where.not(owner_id: blocked_owner_ids)
    end
  end

  private

  def owner?
    record.owner_id == user.id
  end

  def owner_of_record?
    user.present? && !user.discarded? && record.present? && owner?
  end

  def owner_active?
    owner_of_record? && !record.discarded?
  end

  def friends_mode_access?
    return false unless record.privacy_mode_vo.friends?

    Friendship.status_between(user, record.owner) == "accepted"
  end

  def shared_mode_access?
    return false unless record.privacy_mode_vo.shared?

    WishlistShare.exists?(wishlist_id: record.id, user_id: user.id)
  end
end
