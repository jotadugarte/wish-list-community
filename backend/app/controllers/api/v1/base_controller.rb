# frozen_string_literal: true

module Api
  module V1
    # Base controller for /api/v1 enforcing SHA-256 Bearer token authentication
    # and deterministic 409 Conflict handling on database uniqueness races.
    # Traceability: [REQ-AUTH-001], [REQ-ARCH-003]
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api_token!

      rescue_from ActiveRecord::RecordNotUnique, with: :handle_record_not_unique

      attr_reader :current_api_token, :current_user

      private

      # [REQ-AUTH-001] Validates Authorization: Bearer <raw_token> header against ApiToken SHA-256 digests.
      def authenticate_api_token!
        authenticate_with_http_token do |raw_token, _options|
          @current_api_token = ApiToken.authenticate(raw_token)
          @current_user = @current_api_token&.user
        end

        render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
      end

      # [REQ-ARCH-003] Prevents 500 errors on concurrent mobile double-taps.
      def handle_record_not_unique
        render json: { error: "Resource conflict or duplicate request" }, status: :conflict
      end
    end
  end
end
