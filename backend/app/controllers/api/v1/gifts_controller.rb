# frozen_string_literal: true

module Api
  module V1
    # Gift Path 1 deliver/confirm member actions.
    # Traceability: [REQ-GIFT-001], [REQ-GIFT-004], [REQ-ARCH-003]
    class GiftsController < BaseController
      skip_after_action :verify_policy_scoped, only: %i[mark_delivered confirm_received]

      # [REQ-GIFT-001] Gifter marks purchased_secret → delivered_pending_confirmation.
      def mark_delivered
        gift = GiftRecord.find(params[:id])
        authorize gift, :mark_delivered?
        updated = GiftService.mark_delivered!(gift: gift, actor: current_user)
        render json: { gift: updated.as_api_json(viewer: current_user) }, status: :ok
      rescue GiftService::Error => e
        render json: { errors: [ e.message ] }, status: :unprocessable_content
      end

      # [REQ-GIFT-001] [REQ-GIFT-004] Owner confirms delivery with optional thank-you.
      def confirm_received
        gift = GiftRecord.find(params[:id])
        authorize gift, :confirm_received?
        updated = GiftService.confirm_received!(
          gift: gift,
          actor: current_user,
          thank_you_note: gift_params[:thank_you_note]
        )
        render json: { gift: updated.as_api_json(viewer: current_user) }, status: :ok
      rescue GiftService::Error, ArgumentError => e
        render json: { errors: [ e.message ] }, status: :unprocessable_content
      end

      private

      def gift_params
        params.fetch(:gift, {}).permit(:thank_you_note)
      end
    end
  end
end
