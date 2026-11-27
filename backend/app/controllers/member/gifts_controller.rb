# frozen_string_literal: true

module Member
  # Hotwire gift delivered / confirm-received / Path-2 mark-received actions.
  # Traceability: [REQ-GIFT-001], [REQ-GIFT-003]
  class GiftsController < BaseController
    rate_limit to: 20, within: 3.minutes, only: %i[mark_delivered confirm_received mark_received],
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
      redirect_to member_reservations_path, notice: I18n.t("member.gifts.delivered"), status: :see_other
    rescue GiftService::Error => e
      redirect_to member_reservations_path, alert: e.message, status: :see_other
    rescue ArgumentError
      redirect_to member_reservations_path, alert: I18n.t("member.errors.action_failed"), status: :see_other
    end

    def confirm_received
      gift = GiftRecord.find(params[:id])
      authorize gift, :confirm_received?
      GiftService.confirm_received!(
        gift: gift,
        actor: current_user,
        thank_you_note: params[:thank_you_note]
      )
      redirect_to member_wishlists_path, notice: I18n.t("member.gifts.confirmed"), status: :see_other
    rescue GiftService::Error => e
      redirect_back fallback_location: member_wishlists_path, alert: e.message, status: :see_other
    rescue ArgumentError
      redirect_back fallback_location: member_wishlists_path, alert: I18n.t("member.errors.action_failed"), status: :see_other
    end

    # [REQ-GIFT-003] Path 2 — owner marks an item received without a gifter confirm flow.
    def mark_received
      item = Item.kept.find(params[:id])
      gift = GiftRecord.new(item: item)
      authorize gift, :owner_mark_received?
      GiftService.owner_mark_received!(
        item: item,
        actor: current_user,
        thank_you_note: params[:thank_you_note]
      )
      redirect_to member_wishlist_path(item.wishlist),
                  notice: I18n.t("member.gifts.marked_received"),
                  status: :see_other
    rescue GiftService::Error => e
      redirect_back fallback_location: member_wishlists_path, alert: e.message, status: :see_other
    rescue ArgumentError
      redirect_back fallback_location: member_wishlists_path,
                    alert: I18n.t("member.errors.action_failed"),
                    status: :see_other
    end
  end
end
