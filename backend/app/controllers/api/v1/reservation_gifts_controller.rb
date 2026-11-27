# frozen_string_literal: true

module Api
  module V1
    # Path 1 start: mark purchased from an active/grace reservation.
    # Traceability: [REQ-GIFT-001], [REQ-RES-006], [REQ-ADM-001], [REQ-ARCH-003]
    class ReservationGiftsController < BaseController
      skip_after_action :verify_policy_scoped, only: %i[create]
      rate_limit to: 20, within: 3.minutes, only: :create, with: -> {
        render json: { error: I18n.t("api.v1.errors.rate_limited") }, status: :too_many_requests
      }

      # [REQ-GIFT-001] O6A mark purchased → GiftRecord purchased_secret.
      def create
        reservation = Reservation.find(params[:reservation_id])
        authorize reservation, :mark_purchased?
        gift = GiftService.mark_purchased!(
          reservation: reservation,
          actor: current_user,
          purchase_link_ref: gift_params[:purchase_link_ref]
        )
        render json: { gift: gift.as_api_json(viewer: current_user) }, status: :created
      rescue GiftService::ConflictError => e
        render json: { errors: [ e.message ] }, status: :conflict
      rescue GiftService::Error, ArgumentError, ActiveRecord::RecordInvalid => e
        render json: { errors: [ e.message ] }, status: :unprocessable_content
      end

      private

      def gift_params
        params.fetch(:gift, {}).permit(:purchase_link_ref)
      end
    end
  end
end
