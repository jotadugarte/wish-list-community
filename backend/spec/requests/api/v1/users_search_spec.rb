# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users Search & Anti-Stalking Profile Lookup", type: :request do
  let(:viewer) { create(:user, username: "viewer_one") }
  let(:raw_token) { ApiToken.issue_for!(viewer).last }
  let(:auth_headers) { { "Authorization" => "Bearer #{raw_token}" } }

  describe "GET /api/v1/users/search [REQ-SOC-001] [REQ-WISH-001] [REQ-BLOCK-001]" do
    let!(:friend_user) { create(:user, username: "nata_friend") }
    let!(:stranger_user) { create(:user, username: "nata_stranger") }
    let!(:blocked_by_viewer) { create(:user, username: "nata_blocked") }
    let!(:blocker_of_viewer) { create(:user, username: "nata_blocker") }
    let!(:discarded_user) { create(:user, username: "nata_deleted") }

    before do
      Friendship.request!(requester: viewer, addressee: friend_user).accept!(actor: friend_user)
      UserBlock.block!(blocker: viewer, blocked: blocked_by_viewer)
      UserBlock.block!(blocker: blocker_of_viewer, blocked: viewer)
      discarded_user.soft_delete!
    end

    it "returns prefix-matched active non-blocked users with friendship_status and zero email/wishlist leaks" do
      get "/api/v1/users/search", params: { q: "@Nata_" }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      usernames = body["users"].map { |u| u["username"] }

      expect(usernames).to contain_exactly("nata_friend", "nata_stranger")
      friend_entry = body["users"].find { |u| u["username"] == "nata_friend" }
      stranger_entry = body["users"].find { |u| u["username"] == "nata_stranger" }

      expect(friend_entry["friendship_status"]).to eq("accepted")
      expect(stranger_entry["friendship_status"]).to eq("none")
      expect(friend_entry.keys).to contain_exactly("id", "username", "friendship_status", "created_at")
    end

    it "returns 422 Unprocessable Entity when search query is shorter than 2 characters" do
      get "/api/v1/users/search", params: { q: "@" }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /api/v1/users/:username [REQ-SOC-001] [REQ-WISH-001] [REQ-BLOCK-001]" do
    let!(:target_user) { create(:user, username: "ceci_nata") }

    it "includes friendship_status in the public profile card without exposing email_address" do
      Friendship.request!(requester: viewer, addressee: target_user)

      get "/api/v1/users/ceci_nata", headers: auth_headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["username"]).to eq("ceci_nata")
      expect(body["friendship_status"]).to eq("pending_outgoing")
      expect(body).not_to have_key("email_address")
    end
  end
end
