# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Web Cookie & API v1 Token Authentication", type: :request do
  let!(:user) do
    User.create!(
      email_address: "jader@example.com",
      username: "jader_user",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      locale: "es",
      time_zone: "America/Bogota",
      terms_accepted_at: Time.current
    )
  end

  describe "API v1 Bearer Token Auth & DeviceToken Unbinding [REQ-AUTH-001] [REQ-NOTIF-002]" do
    it "issues a bearer token on POST /api/v1/session, authenticates /api/v1/me, and unbinds device_token on DELETE /api/v1/session [REQ-AUTH-001] [REQ-NOTIF-002]" do
      post "/api/v1/session", params: {
        email_address: "JADER@example.com",
        password: "SecurePassword123!",
        device_name: "Pixel 9 Pro",
        fcm_token: "fcm_token_pixel_9_xyz"
      }, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      raw_token = body["token"]
      expect(raw_token).to be_present
      expect(body.dig("user", "username")).to eq("jader_user")
      expect(DeviceToken.count).to eq(1)

      get "/api/v1/me", headers: { "Authorization" => "Bearer #{raw_token}" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["username"]).to eq("jader_user")

      delete "/api/v1/session", headers: { "Authorization" => "Bearer #{raw_token}" }
      expect(response).to have_http_status(:no_content)
      expect(DeviceToken.count).to eq(0)

      get "/api/v1/me", headers: { "Authorization" => "Bearer #{raw_token}" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "Web Cookie Session Auth [REQ-AUTH-001]" do
    it "creates and destroys a stateful cookie session via POST /session and DELETE /session [REQ-AUTH-001]" do
      post "/session", params: {
        email_address: "jader@example.com",
        password: "SecurePassword123!"
      }

      expect(response).to have_http_status(:found)
      expect(Session.where(user: user).count).to eq(1)

      delete "/session"
      expect(response).to have_http_status(:found)
      expect(Session.where(user: user).count).to eq(0)
    end
  end

  describe "Password Reset Anti-Enumeration [REQ-AUTH-003]" do
    it "returns identical 200 OK generic responses for both existing and non-existing emails [REQ-AUTH-003]" do
      post "/api/v1/passwords", params: { email_address: "jader@example.com" }, as: :json
      expect(response).to have_http_status(:ok)
      existing_message = response.parsed_body["message"]

      post "/api/v1/passwords", params: { email_address: "ghost_stranger@example.com" }, as: :json
      expect(response).to have_http_status(:ok)
      non_existing_message = response.parsed_body["message"]

      expect(existing_message).to be_present
      expect(existing_message).to eq(non_existing_message)
    end
  end
end
