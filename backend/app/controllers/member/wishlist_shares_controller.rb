# frozen_string_literal: true

module Member
  # Explicit WishlistShare create/destroy for Hotwire (API parity).
  # Traceability: [REQ-WISH-003]
  class WishlistSharesController < BaseController
    rate_limit to: 20, within: 3.minutes, only: %i[create destroy],
               name: "member_wishlist_shares_write",
               by: -> { current_user&.id || request.remote_ip },
               with: -> {
                 redirect_back fallback_location: member_wishlists_path,
                               alert: I18n.t("api.v1.errors.rate_limited"),
                               status: :see_other
               }

    def create
      wishlist = current_user.wishlists.personal.kept.find(params[:wishlist_id])
      authorize wishlist, :manage_shares?
      friend = User.kept.find(params[:user_id])
      WishlistShare.upsert_explicit!(wishlist: wishlist, user: friend)
      redirect_to member_wishlist_path(wishlist), notice: I18n.t("member.wishlists.share_added"), status: :see_other
    rescue ArgumentError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      redirect_to member_wishlist_path(wishlist), alert: I18n.t("api.v1.errors.wishlist_share_invalid"), status: :see_other
    end

    def destroy
      wishlist = current_user.wishlists.personal.kept.find(params[:wishlist_id])
      authorize wishlist, :manage_shares?
      WishlistShare.where(wishlist: wishlist, user_id: params[:id]).delete_all
      redirect_to member_wishlist_path(wishlist), notice: I18n.t("member.wishlists.share_removed"), status: :see_other
    end
  end
end
