# frozen_string_literal: true

# Minimal Hotwire HTML signup with allowlisted return_to for Secret Link funnel (O1A).
# Traceability: [REQ-AUTH-001], [REQ-AUTH-002], [REQ-AUTH-003], [REQ-WISH-005]
class WebSignupsController < ApplicationController
  include WebAuthentication

  rate_limit to: 10, within: 3.minutes, only: :create

  def new
    @return_to = safe_return_to(params[:return_to])
    @user = User.new
  end

  def create
    @return_to = safe_return_to(params[:return_to])
    unless ActiveModel::Type::Boolean.new.cast(params[:terms_accepted]) == true
      @user = User.new
      @user.errors.add(:base, I18n.t("api.v1.errors.terms_required"))
      return render :new, status: :unprocessable_content
    end

    @user = build_user
    unless @user.errors.empty? && @user.save
      return render :new, status: :unprocessable_content
    end

    establish_web_session!(@user)
    redirect_to(@return_to.presence || root_path)
  end

  private

  def build_user
    email_vo = EmailAddress.new(params[:email_address])
    username_vo = Username.new(params[:username])
    User.new(
      email_address: email_vo.value,
      username: username_vo.value,
      password: params[:password],
      password_confirmation: params[:password_confirmation],
      locale: params[:locale].presence || "es",
      time_zone: params[:time_zone].presence || "UTC",
      terms_accepted_at: Time.current
    )
  rescue ArgumentError
    user = User.new
    user.errors.add(:base, I18n.t("api.v1.errors.signup_invalid"))
    user
  end
end
