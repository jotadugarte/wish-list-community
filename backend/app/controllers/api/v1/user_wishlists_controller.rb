# frozen_string_literal: true

module Api
  module V1
    # Policy-scoped wishlists for a username (O3A friend discovery).
    # Traceability: [REQ-WISH-001], [REQ-BLOCK-001]
    class UserWishlistsController < BaseController
      MAX_INDEX = 100

      # [REQ-WISH-001] [REQ-BLOCK-001] Returns accessible wishlists for @username; 404 on block/missing.
      def index
        target = User.kept.find_by!("LOWER(username) = ?", params[:username].to_s.downcase)
        authorize target, :show?
        if UserBlock.blocked_between?(current_user, target)
          raise ActiveRecord::RecordNotFound
        end

        wishlists = policy_scope(Wishlist.kept.personal.where(owner_id: target.id))
                      .limit(MAX_INDEX)
        render json: { wishlists: wishlists.map { |w| w.as_api_json(viewer: current_user) } }, status: :ok
      end
    end
  end
end
