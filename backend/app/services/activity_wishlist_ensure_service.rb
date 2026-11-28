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
    if existing
      existing.restore!(actor: user) if existing.discarded?
      raise "Post-condition failed: activity wishlist must stay activity-scoped" unless existing.activity_id == activity.id
      return existing
    end

    wishlist = Wishlist.create!(
      owner: user,
      activity_id: activity.id,
      title: activity.name,
      privacy_mode: PrivacyMode.new("friends").value,
      share_token: nil
    )
    raise "Post-condition failed: activity_id must match" unless wishlist.activity_id == activity.id
    raise "Post-condition failed: owner must match participant" unless wishlist.owner_id == user.id
    raise "Post-condition failed: share_token must be blank" if wishlist.share_token.present?

    wishlist
  end

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
