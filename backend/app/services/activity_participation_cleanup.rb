# frozen_string_literal: true

# FC2A: cancel holds/gifts and archive activity wishlists on leave/cancel/block.
# Traceability: [REQ-ACT-003], [REQ-BLOCK-001], [REQ-LIFE-001]
class ActivityParticipationCleanup
  MAX_ROWS = 500

  # [REQ-ACT-003] [REQ-LIFE-001] Cleanup for one leaving participant (leave / force_leave / Block).
  def self.cleanup_leaving_participant!(activity:, user:, actor:)
    raise ArgumentError, "Pre-condition failed: activity required" if activity.nil?
    raise ArgumentError, "Pre-condition failed: user required" if user.nil?
    raise ArgumentError, "Pre-condition failed: actor required" if actor.nil?

    cancel_reserver_holds!(activity: activity, user: user)
    void_gifter_open_gifts!(activity: activity, user: user, actor: actor)
    archive_activity_wishlist!(activity: activity, user: user, actor: actor)
    true
  end

  # [REQ-ACT-003] [REQ-LIFE-001] Cascade archive all activity wishlists on cancel.
  def self.cleanup_cancelled_activity!(activity:, actor:)
    raise ArgumentError, "Pre-condition failed: activity required" if activity.nil?
    raise ArgumentError, "Pre-condition failed: actor required" if actor.nil?

    Wishlist.where(activity_id: activity.id).kept.limit(MAX_ROWS).find_each do |wishlist|
      wishlist.soft_delete!(actor: actor)
    end
    raise "Post-condition failed: activity wishlists must be archived" if Wishlist.where(activity_id: activity.id).kept.exists?

    true
  end

  def self.cancel_reserver_holds!(activity:, user:)
    Reservation.joins(item: :wishlist)
               .where(
                 user_id: user.id,
                 status: ReservationStatus::ACTIVE_HOLD,
                 wishlists: { activity_id: activity.id }
               )
               .limit(MAX_ROWS)
               .find_each do |reservation|
      reservation.update!(status: "canceled", grace_expires_at: nil)
      # [REQ-NOTIF-001] O6A: notify owners when a visible activity hold is released.
      ActivityNotifier.reservation_released!(reservation: reservation)
    end
  end
  private_class_method :cancel_reserver_holds!

  def self.void_gifter_open_gifts!(activity:, user:, actor:)
    GiftRecord.joins(item: :wishlist)
              .where(
                gifter_id: user.id,
                status: GiftStatus::OPEN,
                wishlists: { activity_id: activity.id }
              )
              .limit(MAX_ROWS)
              .find_each do |gift|
      GiftRecord.void_open_for_item!(gift.item_id, notify_gifter: true, actor: actor)
    end
  end
  private_class_method :void_gifter_open_gifts!

  def self.archive_activity_wishlist!(activity:, user:, actor:)
    wishlist = Wishlist.find_by(activity_id: activity.id, owner_id: user.id)
    return if wishlist.nil? || wishlist.discarded?

    wishlist.soft_delete!(actor: actor)
  end
  private_class_method :archive_activity_wishlist!
end
