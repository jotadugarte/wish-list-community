# frozen_string_literal: true

module Api
  module V1
    # Activity-scoped wishlist index/show (FC1A — not personal My Wishlists).
    # Traceability: [REQ-ACT-001], [REQ-ACT-005], [REQ-ARCH-001], [REQ-ARCH-002]
    class ActivityWishlistsController < BaseController
      skip_after_action :verify_policy_scoped
      MAX_INDEX = 200

      # [REQ-ACT-001] [REQ-ARCH-002] Lists activity wishlists the viewer may see.
      def index
        activity = find_activity!
        authorize activity, :show?
        lists = Wishlist.kept.where(activity_id: activity.id).includes(:owner).limit(MAX_INDEX).select do |wishlist|
          ActivityVisibilityGate.can_view_list?(viewer: current_user, owner_wishlist: wishlist)
        end
        render json: {
          wishlists: lists.first(MAX_INDEX).map { |w| activity_wishlist_json(w) }
        }, status: :ok
      end

      # [REQ-ACT-001] [REQ-ARCH-001] Shows one activity wishlist when the gate allows.
      def show
        activity = find_activity!
        authorize activity, :show?
        wishlist = Wishlist.kept.find_by!(id: params[:id], activity_id: activity.id)
        unless ActivityVisibilityGate.can_view_list?(viewer: current_user, owner_wishlist: wishlist)
          raise Pundit::NotAuthorizedError
        end

        render json: { wishlist: activity_wishlist_json(wishlist) }, status: :ok
      end

      private

      def find_activity!
        Activity.find(params[:activity_id])
      end

      def activity_wishlist_json(wishlist)
        payload = wishlist.as_api_json(viewer: current_user)
        payload[:activity_id] = wishlist.activity_id
        payload[:viewer_is_owner] = wishlist.owner_id == current_user.id
        payload.delete(:share_token)
        payload
      end
    end
  end
end
