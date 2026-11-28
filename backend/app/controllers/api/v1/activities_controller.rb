# frozen_string_literal: true

module Api
  module V1
    # API surface for Sprint A Activities shell (no activity items/reservations).
    # Traceability: [REQ-ACT-001], [REQ-ACT-002], [REQ-ACT-003], [REQ-ACT-004], [REQ-ACT-005], [REQ-ARCH-001]
    class ActivitiesController < BaseController
      skip_after_action :verify_policy_scoped
      rate_limit to: 30, within: 3.minutes,
                 only: %i[create invite accept decline leave draw arrancar blind_bridge full_redraw
                          cancel transfer appoint_co_organizer add_exclusion reservation_limit],
                 name: "api_activities_write",
                 by: -> { current_user&.id || request.remote_ip },
                 with: -> { render json: { error: I18n.t("api.v1.errors.rate_limited") }, status: :too_many_requests }

      MAX_INDEX = 100

      def index
        authorize Activity, :index?
        activities = policy_scope(Activity).order(created_at: :desc).limit(MAX_INDEX)
        render json: { activities: activities.map { |a| a.as_api_json(viewer: current_user) } }, status: :ok
      end

      def create
        authorize Activity, :create?
        activity = Activity.create!(create_params.merge(creator: current_user))
        render json: { activity: activity.as_api_json(viewer: current_user) }, status: :created
      rescue ActiveRecord::RecordInvalid
        render json: { errors: [ I18n.t("api.v1.errors.unprocessable") ] }, status: :unprocessable_content
      end

      def show
        activity = find_activity!
        authorize activity, :show?
        render json: { activity: activity.as_api_json(viewer: current_user) }, status: :ok
      end

      def invite
        activity = find_activity!
        authorize activity, :invite?
        user = User.kept.find(params.require(:user_id))
        participant = ActivityAdminService.invite!(activity: activity, actor: current_user, user: user)
        render json: { participant: participant_json(participant) }, status: :created
      rescue ArgumentError
        render json: { errors: [ I18n.t("api.v1.errors.unprocessable") ] }, status: :unprocessable_content
      end

      def accept
        activity = find_activity!
        authorize activity, :join?
        participant = activity.participants.find_by!(user: current_user, status: "invited")
        participant.accept!
        render json: { participant: participant_json(participant) }, status: :ok
      rescue ArgumentError
        render json: { errors: [ I18n.t("api.v1.errors.unprocessable") ] }, status: :unprocessable_content
      end

      def decline
        activity = find_activity!
        authorize activity, :join?
        participant = activity.participants.find_by!(user: current_user, status: "invited")
        participant.decline!
        render json: { participant: participant_json(participant) }, status: :ok
      rescue ArgumentError
        render json: { errors: [ I18n.t("api.v1.errors.unprocessable") ] }, status: :unprocessable_content
      end

      def leave
        activity = find_activity!
        authorize activity, :show?
        ActivityDropoutBridgeService.leave!(activity: activity, actor: current_user)
        render json: { activity: activity.reload.as_api_json(viewer: current_user) }, status: :ok
      rescue ArgumentError
        render json: { errors: [ I18n.t("api.v1.errors.unprocessable") ] }, status: :unprocessable_content
      end

      def add_exclusion
        activity = find_activity!
        authorize activity, :manage?
        exclusion = ActivityExclusionService.add!(
          activity: activity,
          actor: current_user,
          giver: User.kept.find(params.require(:giver_id)),
          forbidden_recipient: User.kept.find(params.require(:forbidden_recipient_id))
        )
        render json: {
          exclusion: {
            id: exclusion.id,
            giver_id: exclusion.giver_id,
            forbidden_recipient_id: exclusion.forbidden_recipient_id
          }
        }, status: :created
      rescue ArgumentError
        render json: { errors: [ I18n.t("api.v1.errors.unprocessable") ] }, status: :unprocessable_content
      end

      def draw
        activity = find_activity!
        authorize activity, :draw?
        ActivityDrawService.draw!(activity: activity, actor: current_user, seed: params[:seed])
        render json: { activity: activity.reload.as_api_json(viewer: current_user) }, status: :ok
      rescue ArgumentError
        render json: { errors: [ I18n.t("api.v1.errors.unprocessable") ] }, status: :unprocessable_content
      end

      def arrancar
        activity = find_activity!
        authorize activity, :manage?
        ActivityOpenGiftingService.arrancar!(activity: activity, actor: current_user)
        render json: { activity: activity.reload.as_api_json(viewer: current_user) }, status: :ok
      rescue ArgumentError
        render json: { errors: [ I18n.t("api.v1.errors.unprocessable") ] }, status: :unprocessable_content
      end

      def blind_bridge
        activity = find_activity!
        authorize activity, :recover_dropout?
        ActivityDropoutBridgeService.blind_bridge!(activity: activity, actor: current_user)
        render json: {
          activity: activity.reload.as_api_json(viewer: current_user),
          blind_bridge: { revealed_full_map: false }
        }, status: :ok
      rescue ArgumentError
        render json: { errors: [ I18n.t("api.v1.errors.unprocessable") ] }, status: :unprocessable_content
      end

      def full_redraw
        activity = find_activity!
        authorize activity, :recover_dropout?
        ActivityDropoutBridgeService.full_redraw!(activity: activity, actor: current_user, seed: params[:seed])
        render json: { activity: activity.reload.as_api_json(viewer: current_user) }, status: :ok
      rescue ArgumentError
        render json: { errors: [ I18n.t("api.v1.errors.unprocessable") ] }, status: :unprocessable_content
      end

      def my_assignment
        activity = find_activity!
        authorize activity, :show?
        assignment = ActivityDrawService.assignment_for(activity: activity, viewer: current_user)
        if assignment.nil?
          return render json: { assignment: nil }, status: :ok
        end

        render json: {
          assignment: {
            giver_id: assignment.giver_id,
            recipient_id: assignment.recipient_id,
            recipient: assignment.recipient.public_profile_json
          }
        }, status: :ok
      end

      def appoint_co_organizer
        activity = find_activity!
        authorize activity, :transfer?
        participant = ActivityAdminService.appoint_co_organizer!(
          activity: activity,
          actor: current_user,
          user: User.kept.find(params.require(:user_id))
        )
        render json: { participant: participant_json(participant) }, status: :ok
      rescue ArgumentError
        render json: { errors: [ I18n.t("api.v1.errors.unprocessable") ] }, status: :unprocessable_content
      end

      def transfer
        activity = find_activity!
        authorize activity, :transfer?
        ActivityAdminService.transfer_ownership!(
          activity: activity,
          actor: current_user,
          new_creator: User.kept.find(params.require(:new_creator_id))
        )
        render json: { activity: activity.reload.as_api_json(viewer: current_user) }, status: :ok
      rescue ArgumentError
        render json: { errors: [ I18n.t("api.v1.errors.unprocessable") ] }, status: :unprocessable_content
      end

      def cancel
        activity = find_activity!
        authorize activity, :cancel?
        ActivityAdminService.cancel!(activity: activity, actor: current_user)
        render json: { activity: activity.reload.as_api_json(viewer: current_user) }, status: :ok
      rescue ArgumentError
        render json: { errors: [ I18n.t("api.v1.errors.unprocessable") ] }, status: :unprocessable_content
      end

      # [REQ-RES-005] O5A/FC3A: set open_gifting N on activity wishlists (pre-seal only).
      def reservation_limit
        activity = find_activity!
        authorize activity, :manage?
        max = Integer(params.require(:max_reservations_per_user))
        ActivityReservationLimitService.set!(activity: activity, actor: current_user, max: max)
        render json: { max_reservations_per_user: max }, status: :ok
      rescue ArgumentError, TypeError, ActionController::ParameterMissing => e
        render json: { errors: [ e.message.presence || I18n.t("api.v1.errors.unprocessable") ] },
               status: :unprocessable_content
      end

      private

      def find_activity!
        Activity.find(params[:id])
      end

      def create_params
        params.require(:activity).permit(
          :name, :currency, :assignment_mode, :visibility_mode, :reservation_visibility,
          :budget_mode, :budget_amount_cents, :budget_max_cents, :starts_on, :ends_on
        )
      end

      def participant_json(participant)
        {
          id: participant.id,
          user_id: participant.user_id,
          status: participant.status,
          co_organizer: participant.co_organizer,
          user: participant.user.public_profile_json
        }
      end
    end
  end
end
