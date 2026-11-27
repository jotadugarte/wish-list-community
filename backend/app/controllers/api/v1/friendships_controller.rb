# frozen_string_literal: true

module Api
  module V1
    # Manages bidirectional friend requests and accepted friendships while enforcing
    # Pundit FriendshipPolicy and "Block Wins".
    # Traceability: [REQ-SOC-001], [REQ-BLOCK-001]
    class FriendshipsController < BaseController
      skip_after_action :verify_policy_scoped
      rate_limit to: 20, within: 3.minutes, only: %i[create update destroy], with: -> {
        render json: { error: I18n.t("api.v1.errors.rate_limited") }, status: :too_many_requests
      }
      MAX_LIST_LIMIT = 500

      # [REQ-SOC-001] Lists accepted friends, pending incoming requests, and pending outgoing requests.
      def index
        authorize Friendship, :index?

        user_friendships = Friendship.where(requester_id: current_user.id)
                                     .or(Friendship.where(addressee_id: current_user.id))
                                     .includes(:requester, :addressee)
                                     .limit(MAX_LIST_LIMIT)
                                     .select(&:active_participants?)

        accepted = user_friendships.select { |f| f.status == "accepted" }
        incoming = user_friendships.select { |f| f.status == "pending" && f.addressee_id == current_user.id }
        outgoing = user_friendships.select { |f| f.status == "pending" && f.requester_id == current_user.id }

        render json: {
          friends: accepted.map { |f| f.as_api_json(viewer: current_user) },
          incoming_requests: incoming.map { |f| f.as_api_json(viewer: current_user) },
          outgoing_requests: outgoing.map { |f| f.as_api_json(viewer: current_user) }
        }, status: :ok
      end

      # [REQ-SOC-001] [REQ-BLOCK-001] Sends a friend request to an active non-blocked user.
      def create
        target_user = User.kept.find(params[:addressee_id])
        candidate = Friendship.new(requester: current_user, addressee: target_user)
        authorize candidate, :create?

        friendship = Friendship.request!(requester: current_user, addressee: target_user)
        render json: { friendship: friendship.as_api_json(viewer: current_user) }, status: :created
      rescue ArgumentError, ActiveRecord::RecordInvalid
        render json: { error: I18n.t("api.v1.errors.friendship_invalid") }, status: :unprocessable_content
      end

      # [REQ-SOC-001] [REQ-BLOCK-001] Accepts a pending incoming friend request.
      def update
        friendship = Friendship.find(params[:id])
        authorize friendship, :update?

        friendship.accept!(actor: current_user)
        render json: { friendship: friendship.as_api_json(viewer: current_user) }, status: :ok
      end

      # [REQ-SOC-001] [REQ-ADM-001] Declines, cancels, or removes a friendship and records an AuditEvent.
      def destroy
        friendship = Friendship.find(params[:id])
        authorize friendship, :destroy?
        other = friendship.requester_id == current_user.id ? friendship.addressee : friendship.requester
        if gifter_open_gift_needs_confirm?(other)
          return render json: { errors: [ I18n.t("gifts.errors.confirm_void_required") ] },
                        status: :unprocessable_content
        end

        friendship.remove!(actor: current_user)
        head :no_content
      end

      private

      # [REQ-GIFT-002] O8D: gifter must confirm before voiding open gifts via unfriend.
      def gifter_open_gift_needs_confirm?(other_user)
        return false if ActiveModel::Type::Boolean.new.cast(params[:confirm_void_gifts])

        GiftRecord.where(status: GiftStatus::OPEN, gifter_id: current_user.id).limit(50).any? do |gift|
          gift.item.wishlist.owner_id == other_user.id
        end
      end
    end
  end
end
