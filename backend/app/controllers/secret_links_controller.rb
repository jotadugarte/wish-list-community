# frozen_string_literal: true

# Hotwire Secret Link landing: OG-safe invitation for guests; Shared-with-me upsert when logged in.
# Traceability: [REQ-WISH-002], [REQ-WISH-003], [REQ-WISH-005], [REQ-WISH-006], [REQ-BLOCK-001]
class SecretLinksController < ApplicationController
  include WebAuthentication

  # [REQ-WISH-005] [REQ-WISH-002] [REQ-WISH-003] Renders invitation or empty shell; 404 on invalid/blocked/discarded.
  def show
    wishlist = find_shared_wishlist!
    if logged_in?
      register_share_if_needed!(wishlist)
      @wishlist = wishlist
      render :show_authenticated
    else
      @wishlist = wishlist
      @return_to = secret_link_path(share_token: wishlist.share_token)
      @og_title = invitation_title(wishlist)
      render :show_guest
    end
  end

  private

  def find_shared_wishlist!
    token_vo = ShareToken.new(params[:share_token])
    wishlist = Wishlist.kept.find_by(share_token: token_vo.value, privacy_mode: "shared")
    raise ActiveRecord::RecordNotFound if wishlist.nil?
    if logged_in? && UserBlock.blocked_between?(current_user, wishlist.owner)
      raise ActiveRecord::RecordNotFound
    end

    wishlist
  rescue ArgumentError
    raise ActiveRecord::RecordNotFound
  end

  def register_share_if_needed!(wishlist)
    return if current_user.id == wishlist.owner_id

    WishlistShare.upsert_secret_link!(wishlist: wishlist, user: current_user)
  end

  def invitation_title(wishlist)
    I18n.t("secret_links.invitation_title", username: wishlist.owner.username)
  end
end
