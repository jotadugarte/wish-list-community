# frozen_string_literal: true

module Member
  # Hotwire my-reservations + create/cancel + mark purchased.
  # Traceability: [REQ-RES-001], [REQ-RES-004], [REQ-GIFT-001]
  class ReservationsController < BaseController
    rate_limit to: 20, within: 3.minutes, only: %i[create destroy mark_purchased],
               name: "member_reservations_write",
               by: -> { current_user&.id || request.remote_ip },
               with: -> {
                 redirect_back fallback_location: member_reservations_path,
                               alert: I18n.t("api.v1.errors.rate_limited"),
                               status: :see_other
               }

    def index
      authorize Reservation, :index?
      @reservations = policy_scope(Reservation).includes(item: :wishlist).order(updated_at: :desc).limit(200)
      @open_gifts = GiftRecordPolicy::Scope.new(current_user, GiftRecord)
                                           .resolve
                                           .includes(item: :wishlist)
                                           .where(status: GiftStatus::OPEN)
                                           .order(updated_at: :desc)
                                           .limit(200)
      # Owner Path-1 confirm UI: GiftRecordPolicy::Scope is gifter-only; load
      # delivered_pending_confirmation for wishlists the current user owns.
      @pending_confirm_gifts = GiftRecord.joins(item: :wishlist)
                                         .includes(item: :wishlist)
                                         .where(
                                           wishlists: { owner_id: current_user.id },
                                           status: GiftStatus::DELIVERED_PENDING_CONFIRMATION
                                         )
                                         .order(updated_at: :desc)
                                         .limit(200)
    end

    def create
      item = Item.kept.find(params[:item_id])
      reservation = Reservation.new(item: item, user: current_user)
      authorize reservation, :create?
      ReservationService.create!(
        item: item,
        user: current_user,
        estimated_date: params.require(:estimated_date),
        private_note: params[:private_note]
      )
      redirect_to after_reservation_path(item.wishlist),
                  notice: I18n.t("member.reservations.created"),
                  status: :see_other
    rescue ReservationService::Error => e
      redirect_back fallback_location: member_reservations_path, alert: e.message, status: :see_other
    rescue ArgumentError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      redirect_back fallback_location: member_reservations_path, alert: I18n.t("member.errors.action_failed"), status: :see_other
    end

    # [REQ-RES-006] Extend estimated_date (including grace → active) for Hotwire.
    def update
      reservation = Reservation.find(params[:id])
      authorize reservation, :update?
      ReservationService.extend!(
        reservation: reservation,
        estimated_date: params.require(:estimated_date),
        private_note: params.key?(:private_note) ? params[:private_note] : :unchanged
      )
      redirect_to after_reservation_path(reservation.item.wishlist),
                  notice: I18n.t("member.reservations.extended"),
                  status: :see_other
    rescue ReservationService::Error => e
      redirect_back fallback_location: member_reservations_path, alert: e.message, status: :see_other
    rescue ArgumentError, ActiveRecord::RecordInvalid
      redirect_back fallback_location: member_reservations_path,
                    alert: I18n.t("member.errors.action_failed"),
                    status: :see_other
    end

    def destroy
      reservation = Reservation.find(params[:id])
      authorize reservation, :destroy?
      wishlist = reservation.item.wishlist
      ReservationService.cancel!(reservation: reservation, actor: current_user)
      redirect_to after_reservation_path(wishlist),
                  notice: I18n.t("member.reservations.canceled"),
                  status: :see_other
    rescue ReservationService::Error => e
      redirect_to member_reservations_path, alert: e.message, status: :see_other
    end

    def mark_purchased
      reservation = Reservation.find(params[:id])
      authorize reservation, :mark_purchased?
      GiftService.mark_purchased!(reservation: reservation, actor: current_user)
      redirect_to after_reservation_path(reservation.item.wishlist),
                  notice: I18n.t("member.gifts.purchased"),
                  status: :see_other
    rescue GiftService::Error => e
      redirect_to member_reservations_path, alert: e.message, status: :see_other
    rescue ArgumentError
      redirect_to member_reservations_path, alert: I18n.t("member.errors.action_failed"), status: :see_other
    end

    private

    # [REQ-ACT-001] Activity holds return to the board; personal holds stay on My Reservations.
    def after_reservation_path(wishlist)
      if wishlist&.activity_scoped?
        member_activity_path(wishlist.activity_id)
      else
        member_reservations_path
      end
    end
  end
end
