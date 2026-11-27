# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 Account Soft-Delete & 30-Day Restoration", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  after { travel_back }

  let!(:user) do
    User.create!(
      email_address: "nata_acc@example.com",
      username: "nata_account",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      locale: "es",
      time_zone: "America/Bogota",
      terms_accepted_at: Time.current
    )
  end

  describe "DELETE /api/v1/account and POST /api/v1/account/restore [REQ-LIFE-001] [REQ-LIFE-002]" do
    it "soft-deletes the account on DELETE /api/v1/account and restores it within 30 days on POST /api/v1/account/restore [REQ-LIFE-002]" do
      freeze_time
      kept_list = Wishlist.create!(owner: user, title: "Keep me")
      kept_list.switch_privacy_mode!(PrivacyMode.new("shared"))
      intentional = Wishlist.create!(owner: user, title: "Already gone")
      intentional.switch_privacy_mode!(PrivacyMode.new("shared"))
      intentional.soft_delete!(actor: user)
      expect(kept_list.share_token).to be_present
      _api_token, raw_token = ApiToken.issue_for!(user, fcm_token: "fcm_acc_1")

      delete "/api/v1/account", headers: { "Authorization" => "Bearer #{raw_token}" }
      expect(response).to have_http_status(:no_content)
      expect(user.reload.discarded?).to be(true)
      expect(kept_list.reload).to be_discarded
      event = AuditEvent.where(action: "user.soft_deleted", auditable: user).order(created_at: :desc).first
      expect(event.metadata["cascaded_wishlist_ids"]).to contain_exactly(kept_list.id)

      # Token is immediately invalidated
      get "/api/v1/me", headers: { "Authorization" => "Bearer #{raw_token}" }
      expect(response).to have_http_status(:unauthorized)

      # Restoring 10 days later succeeds and issues a new token
      travel 10.days
      post "/api/v1/account/restore", params: {
        email_address: "nata_acc@example.com",
        password: "SecurePassword123!"
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["token"]).to be_present
      expect(user.reload.discarded?).to be(false)
      expect(kept_list.reload).not_to be_discarded
      expect(kept_list.share_token).to be_present
      expect(intentional.reload).to be_discarded
    end

    it "rejects account restoration after the 30-day grace window has elapsed [REQ-LIFE-002]" do
      freeze_time
      user.soft_delete!

      travel 31.days
      post "/api/v1/account/restore", params: {
        email_address: "nata_acc@example.com",
        password: "SecurePassword123!"
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.discarded?).to be(true)
    end
  end

  describe "admin soft-delete restore returns generic credentials [REQ-ADM-001] [REQ-LIFE-002]" do
    it "does not disclose admin enforcement on POST /api/v1/account/restore [REQ-ADM-001]" do
      admin = User.create!(
        email_address: "admin_restore@example.com",
        username: "admin_restore",
        password: "SecurePassword123!",
        password_confirmation: "SecurePassword123!",
        locale: "es",
        time_zone: "UTC",
        terms_accepted_at: Time.current,
        role: "admin"
      )
      user.soft_delete!(actor: admin, admin_enforcement: true)

      post "/api/v1/account/restore", params: {
        email_address: user.email_address,
        password: "SecurePassword123!"
      }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq(I18n.t("api.v1.errors.invalid_credentials"))
      expect(response.parsed_body.to_s).not_to match(/admin|soft-delete|enforcement/i)
      expect(user.reload.discarded?).to be(true)
    end
  end
end
