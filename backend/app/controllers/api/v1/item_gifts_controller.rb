# frozen_string_literal: true

module Api
  module V1
    # Path 2: owner marks an item received in one step.
    # Traceability: [REQ-GIFT-003], [REQ-GIFT-004], [REQ-ARCH-003]
    class ItemGiftsController < BaseController
      skip_after_action :verify_policy_scoped, only: %i[create]
      rate_limit to: 20, within: 3.minutes, only: :create, with: -> {
        render json: { error: I18n.t("api.v1.errors.rate_limited") }, status: :too_many_requests
      }

      # [REQ-GIFT-003] Owner Path 2 receive.
      def create
        item = Item.kept.find(params[:item_id])
        gift = GiftRecord.new(item: item)
        authorize gift, :owner_mark_received?
        created = GiftService.owner_mark_received!(
          item: item,
          actor: current_user,
          thank_you_note: gift_params[:thank_you_note]
        )
        render json: { gift: created.as_api_json(viewer: current_user) }, status: :created
      rescue GiftService::Error, ArgumentError, ActiveRecord::RecordInvalid => e
        skip_authorization unless @_pundit_policy_authorized
        render json: { errors: [ e.message ] }, status: :unprocessable_content
      end

      private

      def gift_params
        params.fetch(:gift, {}).permit(:thank_you_note)
      end
    end
  end
end
