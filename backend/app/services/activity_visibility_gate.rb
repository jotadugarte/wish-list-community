# frozen_string_literal: true

# Who may view or reserve on activity-scoped wishlists (O3A).
# Traceability: [REQ-ACT-001], [REQ-BLOCK-001]
# Pre-seal: owners may add items freely (no gate). Reserves require seal.
class ActivityVisibilityGate
  class Error < StandardError; end

  # [REQ-ACT-001] True when viewer may see the owner's activity wishlist.
  def self.can_view_list?(viewer:, owner_wishlist:)
    return false if viewer.nil? || owner_wishlist.nil?
    return false unless owner_wishlist.activity_scoped?

    activity = owner_wishlist.activity
    return false if activity.nil? || activity.cancelled?
    return true if viewer.id == owner_wishlist.owner_id
    return false if UserBlock.blocked_between?(viewer, owner_wishlist.owner)
    return false unless accepted_participant?(activity, viewer)

    may_view_peer?(activity: activity, viewer: viewer, owner_id: owner_wishlist.owner_id)
  end

  # [REQ-ACT-001] True when viewer may reserve the item (view + seal + not own).
  def self.can_reserve?(viewer:, item:)
    return false if viewer.nil? || item.nil? || item.discarded?

    wishlist = item.wishlist
    return false if wishlist.nil? || !wishlist.activity_scoped?
    return false if viewer.id == wishlist.owner_id

    activity = wishlist.activity
    return false if activity.nil? || !activity.sealed?
    return false unless can_view_list?(viewer: viewer, owner_wishlist: wishlist)

    accepted_participant?(activity, viewer)
  end

  # [REQ-ACT-001] Raises when reserve is forbidden (wired into ReservationService).
  def self.assert_may_reserve!(viewer:, item:)
    raise Error, "Pre-condition failed: reserve not allowed" unless can_reserve?(viewer: viewer, item: item)

    true
  end

  def self.accepted_participant?(activity, user)
    activity.participants.where(user_id: user.id, status: "accepted").exists?
  end
  private_class_method :accepted_participant?

  def self.may_view_peer?(activity:, viewer:, owner_id:)
    return true if activity.open_gifting?
    return true if activity.visibility_mode == "all_participants"

    ActivityAssignment.exists?(activity_id: activity.id, giver_id: viewer.id, recipient_id: owner_id)
  end
  private_class_method :may_view_peer?
end
