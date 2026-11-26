# frozen_string_literal: true

module Api
  module V1
    # Manages explicit friend shares on shared-mode wishlists.
    # Traceability: [REQ-WISH-003], [REQ-WISH-001]
    class WishlistSharesController < BaseController
      # [REQ-WISH-003] Creates an explicit share for an accepted friend.
      def create
        wishlist = current_user.wishlists.kept.find(params[:wishlist_id])
        authorize wishlist, :manage_shares?
        target = User.kept.find(params[:user_id])
        share = WishlistShare.upsert_explicit!(wishlist: wishlist, user: target)
        render json: { share: share.as_api_json }, status: :created
      rescue ArgumentError, ActiveRecord::RecordInvalid
        render json: { errors: [ I18n.t("api.v1.errors.wishlist_share_invalid") ] }, status: :unprocessable_content
      end

      # [REQ-WISH-003] Removes an explicit (or any) share for a user.
      def destroy
        wishlist = current_user.wishlists.kept.find(params[:wishlist_id])
        authorize wishlist, :manage_shares?
        share = wishlist.wishlist_shares.find_by!(user_id: params[:id])
        share.destroy!
        head :no_content
      end
    end
  end
end
