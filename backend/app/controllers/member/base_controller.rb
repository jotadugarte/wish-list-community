# frozen_string_literal: true

module Member
  # Authenticated Hotwire shell for member surfaces (phone parity O12A/O2B).
  # Traceability: [REQ-AUTH-001], [REQ-WISH-001]
  class BaseController < ApplicationController
    include WebAuthentication
    include Pundit::Authorization

    layout "member"
    before_action :require_member_login!
    after_action :verify_authorized
    rescue_from Pundit::NotAuthorizedError, with: :hide_member_resource

    private

    # [REQ-AUTH-001] Guests are sent to web login before member pages.
    def require_member_login!
      return if logged_in?

      skip_authorization
      redirect_to new_session_path
    end

    def hide_member_resource
      skip_authorization
      redirect_to member_wishlists_path, alert: I18n.t("member.errors.not_found"), status: :see_other
    end
  end
end
