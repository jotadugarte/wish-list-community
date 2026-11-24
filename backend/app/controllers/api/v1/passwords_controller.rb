# frozen_string_literal: true

module Api
  module V1
    # Handles password reset requests with strict anti-enumeration (always generic 200 OK)
    # and Rails 8 native rate limiting.
    # Traceability: [REQ-AUTH-003]
    class PasswordsController < BaseController
      GENERIC_RESET_MESSAGE = "If that email address is in our system, we have sent password reset instructions."

      skip_before_action :authenticate_api_token!, only: :create
      rate_limit to: 5, within: 3.minutes, only: :create

      # [REQ-AUTH-003] Never reveals whether an email address is registered.
      def create
        render json: { message: GENERIC_RESET_MESSAGE }, status: :ok
      end
    end
  end
end
