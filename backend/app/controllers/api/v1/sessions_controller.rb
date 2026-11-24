# frozen_string_literal: true

module Api
  module V1
    # Issues and revokes SHA-256 API v1 bearer tokens and unbinds push DeviceTokens on logout.
    # Traceability: [REQ-AUTH-001], [REQ-AUTH-003], [REQ-NOTIF-002]
    class SessionsController < BaseController
      skip_before_action :authenticate_api_token!, only: :create
      rate_limit to: 10, within: 3.minutes, only: :create

      # [REQ-AUTH-001] [REQ-NOTIF-002] Authenticates user and returns raw bearer token once.
      def create
        user = User.authenticate_active(params[:email_address], params[:password])
        unless user
          return render json: { error: "Invalid email or password" }, status: :unauthorized
        end

        _api_token, raw_token = ApiToken.issue_for!(
          user,
          device_name: params[:device_name],
          fcm_token: params[:fcm_token]
        )

        render json: {
          token: raw_token,
          user: user.public_profile_json
        }, status: :created
      end

      # [REQ-AUTH-001] [REQ-NOTIF-002] Revokes the current API token and deletes its bound push DeviceToken.
      def destroy
        current_api_token.revoke!
        head :no_content
      end
    end
  end
end
