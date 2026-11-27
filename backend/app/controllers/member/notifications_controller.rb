# frozen_string_literal: true

module Member
  # Hotwire notification inbox.
  # Traceability: [REQ-NOTIF-001]
  class NotificationsController < BaseController
    rate_limit to: 20, within: 3.minutes, only: :mark_read,
               name: "member_notifications_mark_read",
               by: -> { current_user&.id || request.remote_ip },
               with: -> {
                 redirect_back fallback_location: member_notifications_path,
                               alert: I18n.t("api.v1.errors.rate_limited"),
                               status: :see_other
               }

    def index
      authorize Notification, :index?
      @notifications = policy_scope(Notification).order(created_at: :desc).limit(100)
    end

    def mark_read
      note = current_user.notifications.find(params[:id])
      authorize note, :update?
      note.mark_read!
      redirect_to member_notifications_path, notice: I18n.t("member.notifications.marked_read")
    end
  end
end
