# frozen_string_literal: true

# Hotwire reservation actions from Secret Link (O4B parity with Flutter).
# Traceability: [REQ-RES-001], [REQ-WISH-002]
class SecretLinkReservationsController < ApplicationController
  include WebAuthentication
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :render_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  rate_limit to: 20, within: 3.minutes, only: %i[create update destroy], name: "secret_link_reservations_write",
                by: -> { current_user&.id || request.remote_ip }, with: -> {
    redirect_back fallback_location: root_path, alert: I18n.t("api.v1.errors.rate_limited"), status: :see_other
  }

  before_action :require_login!

  # [REQ-RES-001] Creates a reservation from the Secret Link item row.
  def create
    item = Item.kept.find(params[:item_id])
    ensure_secret_link_access!(item.wishlist)
    reservation = Reservation.new(item: item, user: current_user)
    authorize reservation, :create?
    ReservationService.create!(
      item: item,
      user: current_user,
      estimated_date: params.require(:estimated_date),
      private_note: params[:private_note]
    )
    redirect_to secret_link_path(share_token: item.wishlist.share_token), notice: t("secret_links.reserved", default: "Reserved")
  rescue Pundit::NotAuthorizedError, ActiveRecord::RecordNotFound
    raise ActiveRecord::RecordNotFound
  rescue ReservationService::Error, ArgumentError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    redirect_to secret_link_path(share_token: Item.find(params[:item_id]).wishlist.share_token),
                alert: e.message
  end

  # [REQ-RES-006] Extends estimated_date from Secret Link.
  def update
    reservation = Reservation.find(params[:id])
    authorize reservation, :update?
    ReservationService.extend!(reservation: reservation, estimated_date: params.require(:estimated_date))
    redirect_to secret_link_path(share_token: reservation.item.wishlist.share_token), notice: t("secret_links.extended", default: "Extended")
  rescue Pundit::NotAuthorizedError, ActiveRecord::RecordNotFound
    raise ActiveRecord::RecordNotFound
  rescue ReservationService::Error, ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: root_path, alert: e.message
  end

  # [REQ-RES-001] Cancels from Secret Link.
  def destroy
    reservation = Reservation.find(params[:id])
    authorize reservation, :destroy?
    token = reservation.item.wishlist.share_token
    ReservationService.cancel!(reservation: reservation, actor: current_user)
    redirect_to secret_link_path(share_token: token), notice: t("secret_links.canceled", default: "Canceled")
  rescue Pundit::NotAuthorizedError, ActiveRecord::RecordNotFound
    raise ActiveRecord::RecordNotFound
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

    redirect_to new_session_path(return_to: request.fullpath), alert: t("secret_links.login_required", default: "Log in to reserve")
  end

  def render_not_found
    head :not_found
  end
end
