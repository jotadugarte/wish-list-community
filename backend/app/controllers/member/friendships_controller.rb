# frozen_string_literal: true

module Member
  # Hotwire accept / decline / remove friendship actions.
  # Traceability: [REQ-SOC-001], [REQ-BLOCK-001]
  class FriendshipsController < BaseController
    rate_limit to: 20, within: 3.minutes, only: %i[update destroy],
               name: "member_friendships_write",
               by: -> { current_user&.id || request.remote_ip },
               with: -> {
                 redirect_back fallback_location: member_friends_path,
                               alert: I18n.t("api.v1.errors.rate_limited"),
                               status: :see_other
               }

    def update
      friendship = Friendship.find(params[:id])
      authorize friendship, :update?
      friendship.accept!(actor: current_user)
      redirect_to member_friends_path, notice: I18n.t("member.friends.accepted_notice"), status: :see_other
    rescue ArgumentError, ActiveRecord::RecordInvalid
      redirect_to member_friends_path, alert: I18n.t("api.v1.errors.friendship_invalid"), status: :see_other
    end

    def destroy
      friendship = Friendship.find(params[:id])
      authorize friendship, :destroy?
      friendship.remove!(actor: current_user)
      redirect_to member_friends_path, notice: I18n.t("member.friends.removed_notice"), status: :see_other
    rescue ArgumentError
      redirect_to member_friends_path, alert: I18n.t("api.v1.errors.friendship_invalid"), status: :see_other
    end
  end
end
