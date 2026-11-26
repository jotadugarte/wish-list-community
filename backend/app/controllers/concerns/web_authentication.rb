# frozen_string_literal: true

# Cookie-session helpers for Hotwire web auth and Secret Link return_to.
# Traceability: [REQ-AUTH-001], [REQ-WISH-005]
module WebAuthentication
  extend ActiveSupport::Concern

  RETURN_TO_PATTERN = %r{\A/s/[A-Za-z0-9\-_]+\z}

  included do
    helper_method :current_user, :logged_in? if respond_to?(:helper_method)
    before_action :set_web_locale
  end

  private

  # [REQ-USER-002] Sets I18n.locale from the signed-in user; guests keep the app default.
  def set_web_locale
    locale = current_user&.locale&.to_sym
    I18n.locale = I18n.available_locales.include?(locale) ? locale : I18n.default_locale
  end

  # [REQ-AUTH-001] Resolves the signed session cookie to an active User.
  def current_user
    return @current_user if defined?(@current_user)

    session_id = cookies.signed[:session_id]
    @current_user = session_id.present? ? Session.find_by(id: session_id)&.user : nil
    @current_user = nil if @current_user&.discarded?
    @current_user
  end

  def logged_in?
    current_user.present?
  end

  # [REQ-AUTH-001] Creates a web Session and signed cookie for the user.
  def establish_web_session!(user)
    raise ArgumentError, "Pre-condition failed: user must be active" unless user&.persisted? && !user.discarded?

    web_session = user.sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    cookies.signed.permanent[:session_id] = session_cookie_options.merge(value: web_session.id)
    @current_user = user
    raise "Post-condition failed: session cookie missing" if cookies.signed[:session_id].blank?

    web_session
  end

  def session_cookie_options
    {
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?
    }
  end

  def clear_web_session_cookie!
    cookies.delete(:session_id, session_cookie_options.except(:value))
  end

  # [REQ-WISH-005] Allowlists same-origin Secret Link return_to paths only.
  def safe_return_to(raw)
    candidate = raw.to_s.strip
    return nil if candidate.blank?
    return nil if candidate.start_with?("//") || candidate.match?(%r{\A[a-zA-Z][a-zA-Z+\-.]*:})
    return candidate if candidate.match?(RETURN_TO_PATTERN)

    nil
  end

  def redirect_after_auth
    destination = safe_return_to(params[:return_to]) || root_path
    redirect_to destination
  end
end
