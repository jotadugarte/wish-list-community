# frozen_string_literal: true

# Coordinates wishlist privacy mode changes and Secret Link rotation.
# Traceability: [REQ-WISH-001], [REQ-WISH-002], [REQ-WISH-006]
class WishlistPrivacyService
  # [REQ-WISH-001] [REQ-WISH-002] Applies a PrivacyMode transition for the owner.
  def self.change_mode!(wishlist:, mode:)
    raise ArgumentError, "Pre-condition failed: wishlist required" unless wishlist.is_a?(Wishlist)
    mode_vo = mode.is_a?(PrivacyMode) ? mode : PrivacyMode.new(mode)
    wishlist.switch_privacy_mode!(mode_vo)
  end

  # [REQ-WISH-002] [REQ-WISH-006] Rotates the share_token while remaining shared (O4A).
  def self.rotate_token!(wishlist:)
    raise ArgumentError, "Pre-condition failed: wishlist required" unless wishlist.is_a?(Wishlist)
    wishlist.rotate_share_token!
  end
end
