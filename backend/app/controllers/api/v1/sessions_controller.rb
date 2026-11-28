# frozen_string_literal: true

module Api
  module V1
    # Issues and revokes SHA-256 API v1 bearer tokens and unbinds push DeviceTokens on logout.
    # Traceability: [REQ-AUTH-001], [REQ-AUTH-003], [REQ-NOTIF-002]
    class SessionsController < BaseController
      skip_before_action :authenticate_api_token!, only: :create
      skip_after_action :verify_authorized
      skip_after_action :verify_policy_scoped
      rate_limit to: 10, within: 3.minutes, only: :create, name: "api_session_create"
      rate_limit to: 20, within: 3.minutes, only: %i[update destroy], name: "api_session_mutate",
                    by: -> { current_user&.id || request.remote_ip }, with: -> {
        render json: { error: I18n.t("api.v1.errors.rate_limited") }, status: :too_many_requests
      }

      # [REQ-AUTH-001] [REQ-NOTIF-002] Authenticates user and returns raw bearer token once.
      def create
        user = User.authenticate_active(params[:email_address], params[:password])
        unless user
          return render json: { error: I18n.t("api.v1.errors.invalid_credentials") }, status: :unauthorized
        end

        _api_token, raw_token = ApiToken.issue_for!(
          user,
          device_name: params[:device_name],
          fcm_token: incoming_fcm_token
        )

        render json: {
          token: raw_token,
          user: user.public_profile_json
        }, status: :created
      end

      # [REQ-NOTIF-002] Rebinds FCM device_token on an existing authenticated session (e.g. restore).
      def update
        current_api_token.bind_device_token!(incoming_fcm_token)
        head :no_content
      end

      # [REQ-AUTH-001] [REQ-NOTIF-002] Revokes the current API token and deletes its bound push DeviceToken.
      def destroy
        current_api_token.revoke!
        head :no_content
      end

      private

      def incoming_fcm_token
        params[:fcm_token].presence || params[:device_token]
      end
    end
  end
end
