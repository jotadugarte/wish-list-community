# frozen_string_literal: true

module Member
  # Authenticated Hotwire shell for member surfaces (phone parity O12A/O2B).
  # Traceability: [REQ-AUTH-001], [REQ-WISH-001]
  class BaseController < ApplicationController
    include WebAuthentication

    layout "member"
    before_action :require_member_login!

    private

    # [REQ-AUTH-001] Guests are sent to web login before member pages.
    def require_member_login!
      return if logged_in?

      redirect_to new_session_path
    end
  end
end
