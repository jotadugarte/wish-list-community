# frozen_string_literal: true

# Manages stateful Web cookie sessions with Rails 8 native rate limiting.
# Traceability: [REQ-AUTH-001], [REQ-AUTH-003]
class SessionsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create

  # [REQ-AUTH-001] Creates a web session and sets an encrypted signed cookie.
  def create
    user = User.authenticate_active(params[:email_address], params[:password])
    if user
      web_session = user.sessions.create!(
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      cookies.signed.permanent[:session_id] = {
        value: web_session.id,
        httponly: true,
        same_site: :lax
      }
      redirect_to root_path
    else
      head :unauthorized
    end
  end

  # [REQ-AUTH-001] Destroys the active web session and clears the session cookie.
  def destroy
    if cookies.signed[:session_id].present?
      Session.where(id: cookies.signed[:session_id]).destroy_all
      cookies.delete(:session_id)
    end
    redirect_to root_path
  end
end
