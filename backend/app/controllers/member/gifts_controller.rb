# frozen_string_literal: true

module Member
  # Hotwire gift delivered / confirm-received (thank-you) actions.
  # Traceability: [REQ-GIFT-001]
  class GiftsController < BaseController
    rate_limit to: 20, within: 3.minutes, only: %i[mark_delivered confirm_received],
               name: "member_gifts_write",
               by: -> { current_user&.id || request.remote_ip },
               with: -> {
                 redirect_back fallback_location: member_reservations_path,
                               alert: I18n.t("api.v1.errors.rate_limited"),
                               status: :see_other
               }

    def mark_delivered
      gift = GiftRecord.find(params[:id])
      authorize gift, :mark_delivered?
      GiftService.mark_delivered!(gift: gift, actor: current_user)
      redirect_to member_reservations_path, notice: I18n.t("member.gifts.delivered")
    rescue GiftService::Error => e
      redirect_to member_reservations_path, alert: e.message
    rescue ArgumentError
      redirect_to member_reservations_path, alert: I18n.t("member.errors.action_failed")
    end

    def confirm_received
      gift = GiftRecord.find(params[:id])
      authorize gift, :confirm_received?
      GiftService.confirm_received!(
        gift: gift,
        actor: current_user,
        thank_you_note: params[:thank_you_note]
      )
      redirect_to member_wishlists_path, notice: I18n.t("member.gifts.confirmed")
    rescue GiftService::Error => e
      redirect_back fallback_location: member_wishlists_path, alert: e.message
    rescue ArgumentError
      redirect_back fallback_location: member_wishlists_path, alert: I18n.t("member.errors.action_failed")
    end
  end
end
