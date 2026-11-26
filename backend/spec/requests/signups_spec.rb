# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 Signup Registration", type: :request do
  let(:valid_payload) do
    {
      email_address: "nata@example.com",
      username: "ceci_nata",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      locale: "es",
      time_zone: "America/Costa_Rica",
      terms_accepted: true,
      device_name: "iPhone 16",
      fcm_token: "fcm_signup_token_xyz"
    }
  end

  describe "POST /api/v1/signup [REQ-AUTH-001] [REQ-AUTH-002] [REQ-AUTH-003] [REQ-USER-001] [REQ-USER-002] [REQ-USER-003]" do
    it "creates a user with terms_accepted_at, issues a bearer token, and returns the public profile [REQ-AUTH-001] [REQ-AUTH-002] [REQ-USER-001]" do
      expect {
        post "/api/v1/signup", params: valid_payload, as: :json
      }.to change(User, :count).by(1).and change(ApiToken, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["token"]).to be_present
      expect(body.dig("user", "username")).to eq("ceci_nata")
      expect(body.dig("user", "email_address")).to be_nil

      user = User.find_by!(username: "ceci_nata")
      expect(user.terms_accepted_at).to be_present
      expect(user.locale).to eq("es")
      expect(user.time_zone).to eq("America/Costa_Rica")
      expect(user.email_address).to eq("nata@example.com")
      expect(DeviceToken.count).to eq(1)

      get "/api/v1/me", headers: { "Authorization" => "Bearer #{body['token']}" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["username"]).to eq("ceci_nata")
    end

    it "rejects registration when terms_accepted is missing or false [REQ-AUTH-002]" do
      post "/api/v1/signup", params: valid_payload.merge(terms_accepted: false), as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(User.count).to eq(0)

      post "/api/v1/signup", params: valid_payload.except(:terms_accepted), as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(User.count).to eq(0)
    end

    it "rejects invalid or duplicate identity with 422 and does not issue a token [REQ-USER-001]" do
      User.create!(
        email_address: "nata@example.com",
        username: "taken_user",
        password: "SecurePassword123!",
        password_confirmation: "SecurePassword123!",
        locale: "es",
        time_zone: "UTC",
        terms_accepted_at: Time.current
      )

      post "/api/v1/signup", params: valid_payload, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
      expect(response.parsed_body["token"]).to be_nil
      expect(User.where(username: "ceci_nata").count).to eq(0)
    end

    it "declares Rails 8 rate_limit on create like other auth endpoints [REQ-AUTH-003]" do
      source = File.read(Rails.root.join("app/controllers/api/v1/signups_controller.rb"))
      expect(source).to match(/rate_limit\s+to:\s*\d+,\s*within:/)
      expect(Api::V1::SignupsController).to respond_to(:rate_limit)
    end
  end
end
