# frozen_string_literal: true

module Member
  # Hotwire account settings + soft-delete + legal links.
  # Traceability: [REQ-LIFE-001], [REQ-AUTH-002] O8A
  class SettingsController < BaseController
    rate_limit to: 10, within: 3.minutes, only: :destroy_account,
               name: "member_account_destroy",
               by: -> { current_user&.id || request.remote_ip },
               with: -> {
                 redirect_back fallback_location: member_settings_path,
                               alert: I18n.t("api.v1.errors.rate_limited"),
                               status: :see_other
               }

    def show
      skip_authorization
    end

    def destroy_account
      authorize current_user, :destroy?
      current_user.soft_delete!(actor: current_user)
      clear_web_session_cookie!
      redirect_to root_path, notice: I18n.t("member.settings.account_deleted"), status: :see_other
    end
  end
end
