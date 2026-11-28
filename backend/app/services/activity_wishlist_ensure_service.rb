# frozen_string_literal: true

# Ensures one activity-scoped Wishlist per accepted participant.
# Traceability: [REQ-ARCH-002], [REQ-ACT-001]
class ActivityWishlistEnsureService
  MAX_BACKFILL = 500

  # [REQ-ARCH-002] [REQ-ACT-001] Creates or returns the participant's activity wishlist.
  def self.ensure_for_participant!(participant:)
    raise ArgumentError, "Pre-condition failed: participant required" if participant.nil?
    raise ArgumentError, "Pre-condition failed: participant must be accepted" unless participant.status == "accepted"

    activity = participant.activity
    user = participant.user
    raise ArgumentError, "Pre-condition failed: activity required" if activity.nil?
    raise ArgumentError, "Pre-condition failed: user required" if user.nil?

    existing = Wishlist.find_by(activity_id: activity.id, owner_id: user.id)
    return restore_existing_activity_wishlist!(existing, activity, user) if existing

    create_activity_wishlist!(activity: activity, user: user)
  end

  def self.restore_existing_activity_wishlist!(wishlist, activity, user)
    wishlist.restore!(actor: user) if wishlist.discarded?
    if wishlist.max_reservations_per_user.nil?
      wishlist.update!(max_reservations_per_user: ActivityReservationLimitService.default_max_for(activity))
    end
    raise "Post-condition failed: activity wishlist must stay activity-scoped" unless wishlist.activity_id == activity.id

    wishlist
  end
  private_class_method :restore_existing_activity_wishlist!

  def self.create_activity_wishlist!(activity:, user:)
    wishlist = Wishlist.create!(
      owner: user,
      activity_id: activity.id,
      title: activity.name,
      privacy_mode: PrivacyMode.new("friends").value,
      share_token: nil,
      max_reservations_per_user: ActivityReservationLimitService.default_max_for(activity)
    )
    raise "Post-condition failed: activity_id must match" unless wishlist.activity_id == activity.id
    raise "Post-condition failed: owner must match participant" unless wishlist.owner_id == user.id
    raise "Post-condition failed: share_token must be blank" if wishlist.share_token.present?

    wishlist
  end
  private_class_method :create_activity_wishlist!

  # [REQ-ARCH-002] Backfills activity wishlists for every accepted participant.
  def self.backfill_accepted!(activity:)
    raise ArgumentError, "Pre-condition failed: activity required" if activity.nil?

    created = []
    activity.accepted_participants.find_each do |participant|
      break if created.size >= MAX_BACKFILL

      created << ensure_for_participant!(participant: participant)
    end
    accepted_count = [ activity.accepted_participants.limit(MAX_BACKFILL).count, MAX_BACKFILL ].min
    raise "Post-condition failed: backfill must cover accepted participants" if created.size < accepted_count

    created
  end
end
