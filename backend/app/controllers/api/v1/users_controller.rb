# frozen_string_literal: true

module Api
  module V1
    # Exposes anti-stalking public @username lookup (returns only basic profile card,
    # never personal wishlists or email_address, and returns 404 if blocked).
    # Traceability: [REQ-USER-001], [REQ-BLOCK-001], [REQ-WISH-001]
    class UsersController < BaseController
      # [REQ-SOC-001] [REQ-WISH-001] [REQ-BLOCK-001] Anti-stalking @username prefix search.
      def search
        authorize User, :search?
        query_vo = SearchQuery.new(params[:q])
        matches = User.search_by_username(query_vo, viewer: current_user)

        render json: {
          users: matches.map { |u| u.public_profile_json(viewer: current_user) }
        }, status: :ok
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_content
      end

      # [REQ-USER-001] [REQ-BLOCK-001] Looks up a user by @username Value Object and enforces UserPolicy.
      def show
        handle_vo = Username.new(params[:username])
        target_user = User.find_by!("LOWER(username) = ?", handle_vo.value)

        authorize target_user, :show?
        render json: target_user.public_profile_json(viewer: current_user), status: :ok
      rescue ArgumentError
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end
