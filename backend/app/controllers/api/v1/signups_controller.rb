# frozen_string_literal: true

module Api
  module V1
    # Registers new users with mandatory UGC terms acceptance and issues an API bearer token.
    # Traceability: [REQ-AUTH-001], [REQ-AUTH-002], [REQ-AUTH-003], [REQ-USER-001], [REQ-USER-002], [REQ-USER-003]
    class SignupsController < BaseController
      skip_before_action :authenticate_api_token!, only: :create
      skip_after_action :verify_authorized
      skip_after_action :verify_policy_scoped
      rate_limit to: 10, within: 3.minutes, only: :create

      # [REQ-AUTH-001] [REQ-AUTH-002] Creates a user when terms are accepted and returns a raw bearer token once.
      def create
        return render_terms_required unless terms_accepted?

        user = build_user_from_params
        unless user.errors.empty? && user.save
          return render json: { errors: user.errors.full_messages }, status: :unprocessable_content
        end

        raw_token = issue_token_for!(user)
        raise "Post-condition failed: terms_accepted_at must be present" if user.terms_accepted_at.blank?
        raise "Post-condition failed: raw token must be issued" if raw_token.blank?

        render json: { token: raw_token, user: user.public_profile_json }, status: :created
      end

      private

      def terms_accepted?
        ActiveModel::Type::Boolean.new.cast(params[:terms_accepted]) == true
      end

      def render_terms_required
        render json: { errors: [ I18n.t("api.v1.errors.terms_required") ] }, status: :unprocessable_content
      end

      # [REQ-USER-001] [REQ-USER-002] [REQ-USER-003] Builds a User from EmailAddress / Username VOs.
      def build_user_from_params
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
      rescue ArgumentError => e
        user = User.new
        user.errors.add(:base, e.message)
        user
      end

      # [REQ-AUTH-001] [REQ-NOTIF-002] Issues SHA-256 API token and optional FCM binding.
      def issue_token_for!(user)
        raise ArgumentError, "Pre-condition failed: user must be persisted" unless user&.persisted?

        _api_token, raw_token = ApiToken.issue_for!(
          user,
          device_name: params[:device_name],
          fcm_token: params[:fcm_token].presence || params[:device_token]
        )
        raw_token
      end
    end
  end
end
