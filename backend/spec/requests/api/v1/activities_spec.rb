# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Activities", type: :request do
  let(:creator) { create(:user, username: "act_creator") }
  let(:friend) { create(:user, username: "act_friend") }
  let(:other) { create(:user, username: "act_other") }
  let(:creator_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(creator).last}" } }
  let(:friend_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(friend).last}" } }

  describe "CRUD + participants [REQ-ACT-001] [REQ-ACT-005]" do
    it "creates, lists, shows, invites, and accepts [REQ-ACT-001] [REQ-ACT-005]" do
      post "/api/v1/activities",
           params: {
             activity: {
               name: "Navidad",
               currency: "CRC",
               assignment_mode: "secret_santa",
               visibility_mode: "recipient_only",
               reservation_visibility: "hidden_from_recipient",
               budget_mode: "none"
             }
           },
           headers: creator_headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body["activity"]
      expect(body["name"]).to eq("Navidad")
      expect(body["share_token"]).to be_present
      id = body["id"]

      get "/api/v1/activities", headers: creator_headers
      expect(response.parsed_body["activities"].map { |a| a["id"] }).to include(id)

      post "/api/v1/activities/#{id}/participants",
           params: { user_id: friend.id },
           headers: creator_headers
      expect(response).to have_http_status(:created)

      post "/api/v1/activities/#{id}/participants/accept", headers: friend_headers
      expect(response).to have_http_status(:ok)

      get "/api/v1/activities/#{id}", headers: friend_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["activity"]["share_token"]).to be_nil
    end
  end

  describe "exclusions, draw, assignment privacy [REQ-ACT-001] [REQ-ACT-002] [REQ-ACT-004]" do
    it "draws and returns assignment only to the giver [REQ-ACT-001] [REQ-ACT-004]" do
      activity = Activity.create!(
        creator: creator,
        name: "Sorteo",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
      ActivityParticipant.invite!(activity: activity, user: friend, actor: creator).accept!
      ActivityParticipant.invite!(activity: activity, user: other, actor: creator).accept!

      post "/api/v1/activities/#{activity.id}/exclusions",
           params: { giver_id: friend.id, forbidden_recipient_id: other.id },
           headers: creator_headers
      expect(response).to have_http_status(:created)

      post "/api/v1/activities/#{activity.id}/draw",
           params: { seed: 21 },
           headers: creator_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["activity"]["status"]).to eq("sealed")
      expect(response.parsed_body).not_to have_key("assignments")

      get "/api/v1/activities/#{activity.id}/my_assignment", headers: friend_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["assignment"]["giver_id"]).to eq(friend.id)
      expect(response.parsed_body["assignment"]["recipient_id"]).to be_present

      get "/api/v1/activities/#{activity.id}/my_assignment", headers: creator_headers
      expect(response.parsed_body["assignment"]["giver_id"]).to eq(creator.id)
    end
  end

  describe "Arrancar, leave, bridge, cancel, transfer [REQ-ACT-001] [REQ-ACT-003]" do
    it "arranca open_gifting and leaves without cure [REQ-ACT-001]" do
      post "/api/v1/activities",
           params: {
             activity: {
               name: "Abiertos",
               currency: "USD",
               assignment_mode: "open_gifting",
               visibility_mode: "all_participants",
               reservation_visibility: "visible_to_recipient",
               budget_mode: "fixed",
               budget_amount_cents: 2000
             }
           },
           headers: creator_headers
      id = response.parsed_body["activity"]["id"]

      post "/api/v1/activities/#{id}/participants", params: { user_id: friend.id }, headers: creator_headers
      post "/api/v1/activities/#{id}/participants/accept", headers: friend_headers

      post "/api/v1/activities/#{id}/arrancar", headers: creator_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["activity"]["status"]).to eq("sealed")

      delete "/api/v1/activities/#{id}/participants/me", headers: friend_headers
      expect(response).to have_http_status(:ok)
      expect(Activity.find(id).needs_dropout_recovery?).to eq(false)
    end

    it "bridges after leave and supports cancel/transfer [REQ-ACT-003] [REQ-ACT-001]" do
      activity = Activity.create!(
        creator: creator,
        name: "Sorteo",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
      ActivityParticipant.invite!(activity: activity, user: friend, actor: creator).accept!
      ActivityParticipant.invite!(activity: activity, user: other, actor: creator).accept!
      ActivityDrawService.draw!(activity: activity, actor: creator, seed: 8)

      delete "/api/v1/activities/#{activity.id}/participants/me", headers: friend_headers
      expect(response).to have_http_status(:ok)
      expect(activity.reload.needs_dropout_recovery?).to eq(true)

      post "/api/v1/activities/#{activity.id}/blind_bridge", headers: creator_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["blind_bridge"]["revealed_full_map"]).to eq(false)
      expect(activity.reload.needs_dropout_recovery?).to eq(false)

      # transfer + cancel on a fresh activity
      fresh = Activity.create!(
        creator: creator,
        name: "Transfer",
        currency: "CRC",
        assignment_mode: "open_gifting",
        visibility_mode: "all_participants",
        reservation_visibility: "visible_to_recipient",
        budget_mode: "none"
      )
      ActivityParticipant.invite!(activity: fresh, user: friend, actor: creator).accept!
      post "/api/v1/activities/#{fresh.id}/co_organizers",
           params: { user_id: friend.id },
           headers: creator_headers
      expect(response).to have_http_status(:ok)

      post "/api/v1/activities/#{fresh.id}/transfer",
           params: { new_creator_id: friend.id },
           headers: creator_headers
      expect(response).to have_http_status(:ok)
      expect(fresh.reload.creator_id).to eq(friend.id)

      post "/api/v1/activities/#{fresh.id}/cancel", headers: friend_headers
      expect(response).to have_http_status(:ok)
      expect(fresh.reload.cancelled?).to eq(true)
    end
  end
end
