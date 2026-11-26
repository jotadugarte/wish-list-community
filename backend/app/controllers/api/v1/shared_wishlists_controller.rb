# frozen_string_literal: true

module Api
  module V1
    # "Shared with me" index of wishlists accessible via WishlistShare.
    # Traceability: [REQ-WISH-003], [REQ-WISH-001], [REQ-BLOCK-001]
    class SharedWishlistsController < BaseController
      MAX_INDEX = 100

      # [REQ-WISH-003] Lists wishlists shared with the current user (non-blocked, kept, shared mode).
      def index
        authorize Wishlist, :index?
        share_ids = current_user.wishlist_shares.limit(MAX_INDEX).select(:wishlist_id)
        wishlists = policy_scope(Wishlist.kept.where(id: share_ids, privacy_mode: "shared"))
                      .includes(:owner)
                      .limit(MAX_INDEX)
        render json: { wishlists: wishlists.map { |w| w.as_api_json(viewer: current_user) } }, status: :ok
      end
    end
  end
end
