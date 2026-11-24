# frozen_string_literal: true

module Api
  module V1
    # Manages in-app account soft-delete and 30-day restoration window.
    # Traceability: [REQ-LIFE-001], [REQ-LIFE-002]
    class AccountsController < BaseController
      skip_before_action :authenticate_api_token!, only: :restore
      skip_after_action :verify_authorized, only: :restore
      rate_limit to: 5, within: 3.minutes, only: :restore

      # [REQ-LIFE-002] Soft-deletes the current user's account and revokes all active tokens.
      def destroy
        authorize current_user, :destroy?
        current_user.soft_delete!(actor: current_user)
        head :no_content
      end

      # [REQ-LIFE-002] Restores a soft-deleted account within the 30-day grace window.
      def restore
        user = User.authenticate_discarded(params[:email_address], params[:password])
        return render json: { error: I18n.t("api.v1.errors.invalid_credentials") }, status: :unauthorized if user.nil?

        if user.restore!(actor: user)
          _api_token, raw_token = ApiToken.issue_for!(user, device_name: params[:device_name])
          render json: { token: raw_token, user: user.public_profile_json }, status: :ok
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_content
        end
      end
    end
  end
end
