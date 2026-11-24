# frozen_string_literal: true

module Api
  module V1
    # Returns the authenticated user's profile on /api/v1/me.
    # Traceability: [REQ-AUTH-001], [REQ-USER-001]
    class ProfilesController < BaseController
      # [REQ-AUTH-001] Returns current user profile.
      def show
        authorize current_user, :show?
        render json: current_user.public_profile_json, status: :ok
      end
    end
  end
end
