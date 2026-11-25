# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Friendships", type: :request do
  let(:alice) { create(:user, username: "alice_wishes") }
  let(:bob) { create(:user, username: "bob_gifts") }
  let(:charlie) { create(:user, username: "charlie_peer") }
  let(:alice_token) { ApiToken.issue_for!(alice).last }
  let(:bob_token) { ApiToken.issue_for!(bob).last }
  let(:alice_headers) { { "Authorization" => "Bearer #{alice_token}" } }
  let(:bob_headers) { { "Authorization" => "Bearer #{bob_token}" } }

  describe "GET /api/v1/friendships [REQ-SOC-001]" do
    it "lists accepted friends, pending incoming requests, and pending outgoing requests" do
      accepted = Friendship.request!(requester: alice, addressee: bob)
      accepted.accept!(actor: bob)
      Friendship.request!(requester: charlie, addressee: alice)

      get "/api/v1/friendships", headers: alice_headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["friends"].map { |f| f["friend"]["username"] }).to eq([ "bob_gifts" ])
      expect(body["incoming_requests"].map { |f| f["friend"]["username"] }).to eq([ "charlie_peer" ])
      expect(body["outgoing_requests"]).to be_empty
    end
  end

  describe "POST /api/v1/friendships [REQ-SOC-001] [REQ-BLOCK-001]" do
    it "creates a pending friend request to an active non-blocked user" do
      expect do
        post "/api/v1/friendships", params: { addressee_id: bob.id }, headers: alice_headers
      end.to change(Friendship, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["friendship"]["status"]).to eq("pending")
      expect(body["friendship"]["friend"]["username"]).to eq("bob_gifts")
    end

    it "returns 404 Not Found when attempting to send a friend request to a blocked user" do
      UserBlock.block!(blocker: bob, blocked: alice)

      post "/api/v1/friendships", params: { addressee_id: bob.id }, headers: alice_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/friendships/:id [REQ-SOC-001] [REQ-BLOCK-001]" do
    it "allows the addressee to accept a pending friend request" do
      friendship = Friendship.request!(requester: alice, addressee: bob)

      patch "/api/v1/friendships/#{friendship.id}", headers: bob_headers

      expect(response).to have_http_status(:ok)
      expect(friendship.reload.status).to eq("accepted")
    end

    it "returns 404 Not Found if the requester tries to accept their own outgoing request" do
      friendship = Friendship.request!(requester: alice, addressee: bob)

      patch "/api/v1/friendships/#{friendship.id}", headers: alice_headers

      expect(response).to have_http_status(:not_found)
      expect(friendship.reload.status).to eq("pending")
    end
  end

  describe "DELETE /api/v1/friendships/:id [REQ-SOC-001]" do
    it "allows either participant to decline, cancel, or remove a friendship" do
      friendship = Friendship.request!(requester: alice, addressee: bob)

      expect do
        delete "/api/v1/friendships/#{friendship.id}", headers: bob_headers
      end.to change(Friendship, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
