# frozen_string_literal: true

module Api
  module V1
    # Creates directional user blocks enforcing "Block Wins" and AuditEvent logging.
    # Traceability: [REQ-BLOCK-001], [REQ-BLOCK-002], [REQ-ADM-001], [REQ-ARCH-003]
    class UserBlocksController < BaseController
      skip_after_action :verify_policy_scoped
      # [REQ-BLOCK-001] [REQ-BLOCK-002] Blocks target user by @username.
      def create
        handle_vo = Username.new(params[:blocked_username])
        target_user = User.where(discarded_at: nil).find_by!("LOWER(username) = ?", handle_vo.value)

        authorize target_user, policy_class: UserBlockPolicy
        if gifter_open_gift_needs_confirm?(target_user)
          return render json: { errors: [ I18n.t("gifts.errors.confirm_void_required") ] },
                        status: :unprocessable_content
        end
        UserBlock.block!(blocker: current_user, blocked: target_user)

        render json: { blocked_username: target_user.username }, status: :created
      rescue ArgumentError
        raise ActiveRecord::RecordNotFound
      end

      private

      # [REQ-GIFT-002] O8D: gifter must confirm before voiding their open gifts via block.
      def gifter_open_gift_needs_confirm?(target_user)
        return false if ActiveModel::Type::Boolean.new.cast(params[:confirm_void_gifts])

        GiftRecord.where(status: GiftStatus::OPEN, gifter_id: current_user.id).limit(50).any? do |gift|
          gift.item.wishlist.owner_id == target_user.id
        end
      end
    end
  end
end


