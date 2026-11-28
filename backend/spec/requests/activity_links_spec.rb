# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Activity link Hotwire [REQ-ACT-001] [REQ-WISH-001]", type: :request do
  let(:creator) { create(:user, username: "host_act") }
  let(:activity) do
    Activity.create!(
      creator: creator,
      name: "Intercambio",
      currency: "CRC",
      assignment_mode: "secret_santa",
      visibility_mode: "recipient_only",
      reservation_visibility: "hidden_from_recipient",
      budget_mode: "none"
    )
  end

  describe "GET /a/:share_token [REQ-ACT-001]" do
    it "renders a safe public preview without roster [REQ-ACT-001]" do
      get "/a/#{activity.share_token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Intercambio")
      expect(response.body).not_to include(creator.username)
      expect(response.body).not_to include("@host_act")
    end

    it "redirects accepted participants to the member board [REQ-ACT-001]" do
      friend = create(:user, password: "SecurePassword123!", password_confirmation: "SecurePassword123!")
      ActivityParticipant.invite!(activity: activity, user: friend, actor: creator).accept!
      post session_path, params: { email_address: friend.email_address, password: "SecurePassword123!" }

      get "/a/#{activity.share_token}"
      expect(response).to redirect_to(member_activity_path(activity))
    end

    it "returns 404 for invalid tokens [REQ-ACT-001]" do
      get "/a/not-a-real-token-value-xxxxxx"
      expect(response).to have_http_status(:not_found)
    end
  end
end
