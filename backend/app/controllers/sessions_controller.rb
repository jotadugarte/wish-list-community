# frozen_string_literal: true

# Manages stateful Web cookie sessions with Rails 8 native rate limiting and return_to.
# Traceability: [REQ-AUTH-001], [REQ-AUTH-003], [REQ-WISH-005]
class SessionsController < ApplicationController
  include WebAuthentication

  rate_limit to: 10, within: 3.minutes, only: :create

  # [REQ-AUTH-001] [REQ-WISH-005] Renders HTML login with optional allowlisted return_to.
  def new
    @return_to = safe_return_to(params[:return_to])
  end

  # [REQ-AUTH-001] [REQ-WISH-005] Creates a web session and redirects to safe return_to or root.
  def create
    @return_to = safe_return_to(params[:return_to])
    user = User.authenticate_active(params[:email_address], params[:password])
    if user
      establish_web_session!(user)
      redirect_to(@return_to.presence || root_path)
    else
      flash.now[:alert] = I18n.t("api.v1.errors.invalid_credentials")
      render :new, status: :unauthorized
    end
  end

  # [REQ-AUTH-001] Destroys the active web session and clears the session cookie.
  def destroy
    if cookies.signed[:session_id].present?
      Session.where(id: cookies.signed[:session_id]).destroy_all
      clear_web_session_cookie!
    end
    redirect_to root_path
  end
end
