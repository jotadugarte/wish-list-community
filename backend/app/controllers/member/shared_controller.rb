# frozen_string_literal: true

module Member
  # Hotwire "Shared with me" wishlist index (phone parity O12A/O2B).
  # Traceability: [REQ-WISH-003], [REQ-WISH-001], [REQ-BLOCK-001]
  class SharedController < BaseController
    MAX_INDEX = 100

    def index
      authorize Wishlist, :index?
      share_ids = current_user.wishlist_shares.limit(MAX_INDEX).select(:wishlist_id)
      @wishlists = policy_scope(Wishlist.kept.where(id: share_ids, privacy_mode: "shared"))
                     .includes(:owner)
                     .order(updated_at: :desc)
                     .limit(MAX_INDEX)
    end
  end
end
