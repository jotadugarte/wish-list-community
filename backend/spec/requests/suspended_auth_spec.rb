# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Suspended account authentication [REQ-ADM-001] [REQ-AUTH-001]", type: :request do
  let(:admin) { create(:user, role: "admin", username: "admin_auth", email_address: "admin_auth@example.com") }
  let!(:member) do
    create(
      :user,
      username: "member_auth",
      email_address: "member_auth@example.com",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!"
    )
  end
  let(:password) { "SecurePassword123!" }

  def invalid_credentials_message
    I18n.t("api.v1.errors.invalid_credentials")
  end

  describe "web session create (FC2 GENERIC)" do
    it "rejects a suspended user with the same generic failure as bad credentials [REQ-ADM-001] [REQ-AUTH-001]" do
      post "/session", params: { email_address: member.email_address, password: "wrong-password" }
      expect(response).to have_http_status(:unauthorized)
      bad_password_alert = flash[:alert]
      expect(bad_password_alert).to eq(invalid_credentials_message)

      member.suspend!(actor: admin)

      post "/session", params: { email_address: member.email_address, password: password }
      expect(response).to have_http_status(:unauthorized)
      expect(flash[:alert]).to eq(bad_password_alert)
      expect(flash[:alert]).not_to match(/suspend/i)
      expect(Session.where(user: member).count).to eq(0)
    end
  end

  describe "API login (FC2 GENERIC)" do
    it "rejects a suspended user with the same generic JSON error as bad credentials [REQ-ADM-001] [REQ-AUTH-001]" do
      post "/api/v1/session", params: {
        email_address: member.email_address,
        password: "wrong-password"
      }, as: :json
      expect(response).to have_http_status(:unauthorized)
      bad_password_body = response.parsed_body

      member.suspend!(actor: admin)

      post "/api/v1/session", params: {
        email_address: member.email_address,
        password: password
      }, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(bad_password_body)
      expect(response.parsed_body["error"]).to eq(invalid_credentials_message)
      expect(response.parsed_body["error"]).not_to match(/suspend/i)
    end
  end

  describe "API token auth" do
    it "rejects bearer tokens for suspended users with generic unauthorized [REQ-ADM-001] [REQ-AUTH-001]" do
      _token, raw = ApiToken.issue_for!(member)
      # Simulate a lingering token + suspended flag (R1 normally deletes tokens).
      member.update_columns(suspended_at: Time.current)

      get "/api/v1/me", headers: { "Authorization" => "Bearer #{raw}" }
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq(I18n.t("api.v1.errors.unauthorized"))
      expect(response.parsed_body["error"]).not_to match(/suspend/i)
    end
  end

  describe "discarded soft-delete auth paths unchanged" do
    it "still authenticates discarded users for restore via authenticate_discarded [REQ-LIFE-002]" do
      member.soft_delete!(actor: member)
      expect(User.authenticate_active(member.email_address, password)).to be_nil
      expect(User.authenticate_discarded(member.email_address, password)).to eq(member)
    end
  end
end
