# frozen_string_literal: true

module Api
  module V1
    # In-app notification inbox for the current user.
    # Traceability: [REQ-NOTIF-001]
    class NotificationsController < BaseController
      skip_after_action :verify_policy_scoped, only: %i[mark_read]

      def index
        authorize Notification, :index?
        notes = policy_scope(Notification).order(created_at: :desc).limit(100)
        render json: { notifications: notes.map(&:as_api_json) }, status: :ok
      end

      def mark_read
        note = current_user.notifications.find(params[:id])
        authorize note, :update?
        note.mark_read!
        render json: { notification: note.as_api_json }, status: :ok
      end
    end
  end
end
