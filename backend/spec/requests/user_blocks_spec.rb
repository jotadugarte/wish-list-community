# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 User Blocks, Anti-Stalking Profile Lookup & RecordNotUnique Idempotency", type: :request do
  let!(:alice) do
    User.create!(
      email_address: "alice_req@example.com",
      username: "alice_req",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      locale: "es",
      time_zone: "UTC",
      terms_accepted_at: Time.current
    )
  end

  let!(:bob) do
    User.create!(
      email_address: "bob_req@example.com",
      username: "bob_req",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      locale: "es",
      time_zone: "UTC",
      terms_accepted_at: Time.current
    )
  end

  let(:alice_token) { ApiToken.issue_for!(alice).last }
  let(:bob_token) { ApiToken.issue_for!(bob).last }

  describe "GET /api/v1/users/:username and POST /api/v1/user_blocks [REQ-BLOCK-001] [REQ-BLOCK-002] [REQ-ARCH-003]" do
    it "shows basic public @username profile before blocking, and cuts access in both directions after blocking [REQ-BLOCK-001] [REQ-BLOCK-002]" do
      get "/api/v1/users/bob_req", headers: { "Authorization" => "Bearer #{alice_token}" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["username"]).to eq("bob_req")
      expect(response.parsed_body).not_to have_key("email_address")

      post "/api/v1/user_blocks",
           params: { blocked_username: "bob_req" },
           headers: { "Authorization" => "Bearer #{alice_token}" },
           as: :json
      expect(response).to have_http_status(:created)

      # Both blocker and blocked user immediately lose access ("block wins")
      get "/api/v1/users/bob_req", headers: { "Authorization" => "Bearer #{alice_token}" }
      expect(response).to have_http_status(:not_found)

      get "/api/v1/users/alice_req", headers: { "Authorization" => "Bearer #{bob_token}" }
      expect(response).to have_http_status(:not_found)
    end

    it "returns 409 Conflict when a concurrent double-tap triggers ActiveRecord::RecordNotUnique [REQ-ARCH-003]" do
      allow(UserBlock).to receive(:block!).and_raise(ActiveRecord::RecordNotUnique.new("duplicate key"))

      post "/api/v1/user_blocks",
           params: { blocked_username: "bob_req" },
           headers: { "Authorization" => "Bearer #{alice_token}" },
           as: :json

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error"]).to match(/conflict|duplicate/i)
    end
  end
end
