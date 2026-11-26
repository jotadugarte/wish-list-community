# frozen_string_literal: true

module Api
  module V1
    # Base controller for /api/v1 enforcing SHA-256 Bearer token authentication,
    # Pundit default-deny verify_authorized, and deterministic 409 Conflict handling.
    # Traceability: [REQ-ARCH-001], [REQ-AUTH-001], [REQ-BLOCK-001], [REQ-ARCH-003]
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods
      include Pundit::Authorization

      before_action :authenticate_api_token!
      before_action :set_user_locale
      after_action :verify_authorized
      after_action :verify_policy_scoped

      rescue_from ActiveRecord::RecordNotUnique, with: :handle_record_not_unique
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from Pundit::NotAuthorizedError, with: :handle_not_authorized

      attr_reader :current_api_token, :current_user

      private

      # [REQ-USER-002] Sets I18n.locale for the request (including rescue_from handlers) to the user's preferred locale.
      def set_user_locale
        locale = current_user&.locale&.to_sym
        I18n.locale = I18n.available_locales.include?(locale) ? locale : I18n.default_locale
      end

      # [REQ-AUTH-001] Validates Authorization: Bearer <raw_token> header against ApiToken SHA-256 digests.
      def authenticate_api_token!
        authenticate_with_http_token do |raw_token, _options|
          @current_api_token = ApiToken.authenticate(raw_token)
          @current_user = @current_api_token&.user
        end

        render json: { error: I18n.t("api.v1.errors.unauthorized") }, status: :unauthorized unless @current_user
      end

      # [REQ-ARCH-003] Prevents 500 errors on concurrent mobile double-taps.
      def handle_record_not_unique
        skip_policy_scope
        render json: { error: I18n.t("api.v1.errors.conflict") }, status: :conflict
      end

      # [REQ-BLOCK-001] Returns 404 Not Found when a target record does not exist.
      def handle_not_found
        skip_authorization
        skip_policy_scope
        render json: { error: I18n.t("api.v1.errors.not_found") }, status: :not_found
      end

      # [REQ-BLOCK-001] Returns 404 Not Found on unauthorized/blocked resources to prevent existence leaks.
      def handle_not_authorized
        skip_policy_scope
        render json: { error: I18n.t("api.v1.errors.not_found") }, status: :not_found
      end
    end
  end
end
