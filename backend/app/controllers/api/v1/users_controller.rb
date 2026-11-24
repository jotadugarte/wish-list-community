# frozen_string_literal: true

module Api
  module V1
    # Exposes anti-stalking public @username lookup (returns only basic profile card,
    # never personal wishlists or email_address, and returns 404 if blocked).
    # Traceability: [REQ-USER-001], [REQ-BLOCK-001], [REQ-WISH-001]
    class UsersController < BaseController
      # [REQ-USER-001] [REQ-BLOCK-001] Looks up a user by @username Value Object and enforces UserPolicy.
      def show
        handle_vo = Username.new(params[:username])
        target_user = User.find_by("LOWER(username) = ?", handle_vo.value)
        return render json: { error: "Not found" }, status: :not_found if target_user.nil?

        authorize target_user, :show?
        render json: target_user.public_profile_json, status: :ok
      rescue ArgumentError
        skip_authorization
        render json: { error: "Not found" }, status: :not_found
      end
    end
  end
end
