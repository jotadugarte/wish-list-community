# frozen_string_literal: true

# Sets and freezes max_reservations_per_user on activity wishlists (O5A / FC3A).
# Traceability: [REQ-RES-005]
class ActivityReservationLimitService
  DEFAULT_MAX = 1
  MAX_WISHLISTS = 500

  # [REQ-RES-005] O5A: admin sets open_gifting N on all activity wishlists pre-seal.
  def self.set!(activity:, actor:, max:)
    raise ArgumentError, "Pre-condition failed: activity required" if activity.nil?
    raise ArgumentError, "Pre-condition failed: actor required" if actor.nil?
    raise ArgumentError, "Pre-condition failed: activity is sealed" if activity.sealed?
    raise ArgumentError, "Pre-condition failed: open_gifting only" unless activity.open_gifting?
    raise ArgumentError, "Pre-condition failed: max must be a positive integer" unless max.is_a?(Integer) && max >= 1

    ActivityAdminService.send(:assert_admin!, activity, actor)
    apply_max!(activity: activity, max: max)
    raise "Post-condition failed: wishlists must carry max #{max}" unless all_match_max?(activity, max)

    max
  end

  # [REQ-RES-005] FC3A: after draw/Arrancar, stamp any missing max (no-op when already set).
  def self.freeze_at_seal!(activity:)
    raise ArgumentError, "Pre-condition failed: activity required" if activity.nil?
    raise ArgumentError, "Pre-condition failed: activity must be sealed" unless activity.sealed?

    default = DEFAULT_MAX
    Wishlist.where(activity_id: activity.id, max_reservations_per_user: nil)
            .kept
            .limit(MAX_WISHLISTS)
            .find_each do |wishlist|
      wishlist.update!(max_reservations_per_user: default)
    end
    raise "Post-condition failed: sealed activity wishlists need a max" if nil_max_exists?(activity)

    true
  end

  # [REQ-RES-005] Default max for a newly ensured activity wishlist.
  def self.default_max_for(activity)
    raise ArgumentError, "Pre-condition failed: activity required" if activity.nil?
    return DEFAULT_MAX if activity.secret_santa?

    existing = Wishlist.where(activity_id: activity.id)
                       .where.not(max_reservations_per_user: nil)
                       .limit(1)
                       .pick(:max_reservations_per_user)
    existing.presence || DEFAULT_MAX
  end

  def self.apply_max!(activity:, max:)
    Wishlist.where(activity_id: activity.id).kept.limit(MAX_WISHLISTS).find_each do |wishlist|
      wishlist.update!(max_reservations_per_user: max)
    end
  end
  private_class_method :apply_max!

  def self.all_match_max?(activity, max)
    Wishlist.where(activity_id: activity.id).kept.limit(MAX_WISHLISTS).all? do |wishlist|
      wishlist.max_reservations_per_user == max
    end
  end
  private_class_method :all_match_max?

  def self.nil_max_exists?(activity)
    Wishlist.where(activity_id: activity.id, max_reservations_per_user: nil).kept.exists?
  end
  private_class_method :nil_max_exists?
end
