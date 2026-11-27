# frozen_string_literal: true

# Hotwire gift actions from Secret Link (O3C parity with Flutter).
# Traceability: [REQ-GIFT-001], [REQ-GIFT-003], [REQ-GIFT-004], [REQ-ITEM-004]
class SecretLinkGiftsController < ApplicationController
  include WebAuthentication
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :render_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  rate_limit to: 20, within: 3.minutes, only: %i[mark_purchased mark_delivered confirm_received mark_received], with: -> {
    redirect_back fallback_location: root_path, alert: I18n.t("api.v1.errors.rate_limited"), status: :too_many_requests
  }

  before_action :require_login!

  # [REQ-GIFT-001] Path 1 mark purchased from Secret Link hold.
  def mark_purchased
    reservation = Reservation.find(params[:reservation_id])
    ensure_secret_link_access!(reservation.item.wishlist)
    authorize reservation, :mark_purchased?
    GiftService.mark_purchased!(
      reservation: reservation,
      actor: current_user,
      purchase_link_ref: params[:purchase_link_ref]
    )
    redirect_to secret_link_path(share_token: reservation.item.wishlist.share_token),
                notice: t("secret_links.marked_purchased")
  rescue GiftService::Error, ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: root_path, alert: e.message
  end

  # [REQ-GIFT-001] Path 1 mark delivered.
  def mark_delivered
    gift = GiftRecord.find(params[:id])
    ensure_secret_link_access!(gift.item.wishlist)
    authorize gift, :mark_delivered?
    GiftService.mark_delivered!(gift: gift, actor: current_user)
    redirect_to secret_link_path(share_token: gift.item.wishlist.share_token),
                notice: t("secret_links.marked_delivered")
  rescue GiftService::Error => e
    redirect_back fallback_location: root_path, alert: e.message
  end

  # [REQ-GIFT-001] [REQ-GIFT-004] Owner confirms delivery.
  def confirm_received
    gift = GiftRecord.find(params[:id])
    ensure_secret_link_access!(gift.item.wishlist)
    authorize gift, :confirm_received?
    GiftService.confirm_received!(
      gift: gift,
      actor: current_user,
      thank_you_note: params[:thank_you_note]
    )
    redirect_to secret_link_path(share_token: gift.item.wishlist.share_token),
                notice: t("secret_links.confirmed_received")
  rescue GiftService::Error, ArgumentError => e
    redirect_back fallback_location: root_path, alert: e.message
  end

  # [REQ-GIFT-003] Path 2 owner mark received.
  def mark_received
    item = Item.kept.find(params[:item_id])
    ensure_secret_link_access!(item.wishlist)
    gift = GiftRecord.new(item: item)
    authorize gift, :owner_mark_received?
    GiftService.owner_mark_received!(
      item: item,
      actor: current_user,
      thank_you_note: params[:thank_you_note]
    )
    redirect_to secret_link_path(share_token: item.wishlist.share_token),
                notice: t("secret_links.marked_received")
  rescue GiftService::Error, ArgumentError => e
    redirect_back fallback_location: root_path, alert: e.message
  end

  private

  def ensure_secret_link_access!(wishlist)
    raise ActiveRecord::RecordNotFound if wishlist.share_token != params[:share_token]
    raise ActiveRecord::RecordNotFound if wishlist.privacy_mode != "shared" || wishlist.discarded?
    return if current_user.id == wishlist.owner_id

    WishlistShare.upsert_secret_link!(wishlist: wishlist, user: current_user)
  end

  def require_login!
    return if logged_in?

    redirect_to new_session_path(return_to: request.fullpath), alert: t("secret_links.login_required", default: "Log in")
  end

  def render_not_found
    head :not_found
  end
end
