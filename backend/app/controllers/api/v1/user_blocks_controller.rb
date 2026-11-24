# frozen_string_literal: true

module Api
  module V1
    # Creates directional user blocks enforcing "Block Wins" and AuditEvent logging.
    # Traceability: [REQ-BLOCK-001], [REQ-BLOCK-002], [REQ-ADM-001], [REQ-ARCH-003]
    class UserBlocksController < BaseController
      # [REQ-BLOCK-001] [REQ-BLOCK-002] Blocks target user by @username.
      def create
        handle_vo = Username.new(params[:blocked_username])
        target_user = User.where(discarded_at: nil).find_by!("LOWER(username) = ?", handle_vo.value)

        authorize target_user, policy_class: UserBlockPolicy
        UserBlock.block!(blocker: current_user, blocked: target_user)

        render json: { blocked_username: target_user.username }, status: :created
      rescue ArgumentError
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end
