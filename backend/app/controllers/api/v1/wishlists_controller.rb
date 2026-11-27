# frozen_string_literal: true

module Api
  module V1
    # Owner CRUD for personal wishlists (empty shells in Sprint 3).
    # Traceability: [REQ-WISH-001], [REQ-WISH-002], [REQ-WISH-004], [REQ-WISH-006],
    # [REQ-LIFE-001], [REQ-ARCH-003]
    class WishlistsController < BaseController
      skip_after_action :verify_policy_scoped
      rate_limit to: 20, within: 3.minutes, only: %i[create update destroy rotate_share_token restore], name: "api_wishlists_write",
                    by: -> { current_user&.id || request.remote_ip }, with: -> {
        render json: { error: I18n.t("api.v1.errors.rate_limited") }, status: :too_many_requests
      }
      MAX_INDEX = 100

      # [REQ-WISH-001] Lists the current user's kept wishlists.
      def index
        authorize Wishlist, :index?
        wishlists = current_user.wishlists.kept.order(created_at: :desc).limit(MAX_INDEX)
        render json: { wishlists: wishlists.map { |w| w.as_api_json(viewer: current_user) } }, status: :ok
      end

      # [REQ-WISH-001] Creates a wishlist defaulting to privacy_mode=friends (O2A).
      def create
        authorize Wishlist, :create?
        wishlist = current_user.wishlists.create!(create_params.merge(privacy_mode: "friends"))
        raise "Post-condition failed: default friends mode" unless wishlist.privacy_mode == "friends"

        render json: { wishlist: wishlist.as_api_json(viewer: current_user) }, status: :created
      rescue ActiveRecord::RecordInvalid
        render json: { errors: [ I18n.t("api.v1.errors.wishlist_invalid") ] }, status: :unprocessable_content
      end

      # [REQ-WISH-001] Shows a wishlist when authorized by WishlistPolicy.
      def show
        wishlist = find_wishlist_for_show!
        authorize wishlist, :show?
        render json: { wishlist: wishlist.as_api_json(viewer: current_user) }, status: :ok
      end

      # [REQ-WISH-001] [REQ-WISH-002] [REQ-WISH-004] Updates title/event_date/privacy_mode.
      def update
        wishlist = current_user.wishlists.kept.find(params[:id])
        authorize wishlist, :update?
        apply_updates!(wishlist)
        render json: { wishlist: wishlist.reload.as_api_json(viewer: current_user) }, status: :ok
      rescue ArgumentError, ActiveRecord::RecordInvalid
        render json: { errors: [ I18n.t("api.v1.errors.wishlist_invalid") ] }, status: :unprocessable_content
      end

      # [REQ-LIFE-001] Soft-deletes the owner's wishlist.
      def destroy
        wishlist = current_user.wishlists.kept.find(params[:id])
        authorize wishlist, :destroy?
        wishlist.soft_delete!(actor: current_user)
        head :no_content
      end

      # [REQ-LIFE-001] Restores a soft-deleted wishlist within the grace window.
      def restore
        wishlist = current_user.wishlists.discarded.find(params[:id])
        authorize wishlist, :restore?
        unless wishlist.restore!(actor: current_user)
          return render json: { errors: [ I18n.t("api.v1.errors.wishlist_invalid") ] }, status: :unprocessable_content
        end

        render json: { wishlist: wishlist.as_api_json(viewer: current_user) }, status: :ok
      end

      # [REQ-WISH-002] [REQ-WISH-006] Rotates Secret Link token while staying shared (O4A).
      def rotate_share_token
        wishlist = current_user.wishlists.kept.find(params[:id])
        authorize wishlist, :rotate_share_token?
        WishlistPrivacyService.rotate_token!(wishlist: wishlist)
        render json: { wishlist: wishlist.reload.as_api_json(viewer: current_user) }, status: :ok
      rescue ArgumentError
        render json: { errors: [ I18n.t("api.v1.errors.wishlist_invalid") ] }, status: :unprocessable_content
      end

      private

      def create_params
        params.require(:wishlist).permit(:title, :event_date, :max_reservations_per_user)
      end

      def find_wishlist_for_show!
        Wishlist.kept.find(params[:id])
      end

      def apply_updates!(wishlist)
        attrs = params.require(:wishlist).permit(:title, :event_date, :max_reservations_per_user, :privacy_mode)
        wishlist.transaction do
          if attrs.key?(:privacy_mode) && attrs[:privacy_mode].present?
            WishlistPrivacyService.change_mode!(wishlist: wishlist, mode: attrs[:privacy_mode])
          end
          wishlist.update!(attrs.except(:privacy_mode))
        end
      end
    end
  end
end
