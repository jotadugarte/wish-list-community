# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Reports", type: :request do
  let(:reporter) { create(:user, username: "reporter_user") }
  let(:target_user) { create(:user, username: "reported_user") }
  let(:raw_token) { ApiToken.issue_for!(reporter).last }
  let(:auth_headers) { { "Authorization" => "Bearer #{raw_token}" } }

  describe "POST /api/v1/reports [REQ-SOC-001] [REQ-DISC-001] [REQ-ADM-001]" do
    it "submits a user abuse report and returns 201 Created" do
      expect do
        post "/api/v1/reports",
             params: {
               reportable_type: "User",
               reportable_id: target_user.id,
               reason: "harassment",
               details: "Unsolicited spam requests"
             },
             headers: auth_headers
      end.to change(Report, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["report"]["reason"]).to eq("harassment")
      expect(body["report"]["status"]).to eq("pending")
    end

    it "returns 422 Unprocessable Content for an invalid report reason" do
      post "/api/v1/reports",
           params: {
             reportable_type: "User",
             reportable_id: target_user.id,
             reason: "not_a_real_reason"
           },
           headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 Unprocessable Content for an unsupported reportable_type without Pundit errors" do
      post "/api/v1/reports",
           params: {
             reportable_type: "UnknownEntity",
             reportable_id: target_user.id,
             reason: "spam"
           },
           headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "declares Rails 8 rate_limit on create [REQ-DISC-001]" do
      source = File.read(Rails.root.join("app/controllers/api/v1/reports_controller.rb"))
      expect(source).to match(/rate_limit\s+to:\s*\d+,\s*within:/)
      expect(Api::V1::ReportsController).to respond_to(:rate_limit)
    end
  end

  describe "POST /api/v1/reports Wishlist [REQ-DISC-001] [REQ-ARCH-003]" do
    let(:owner) { create(:user) }
    let(:friend) { create(:user) }
    let(:stranger) { create(:user) }
    let(:sharee) { create(:user) }
    let(:friend_token) { ApiToken.issue_for!(friend).last }
    let(:friend_headers) { { "Authorization" => "Bearer #{friend_token}" } }

    before do
      Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
      Friendship.request!(requester: owner, addressee: sharee).accept!(actor: sharee)
    end

    it "submits a wishlist report for a friend viewer and matches user report shape [REQ-DISC-001]" do
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")

      expect do
        post "/api/v1/reports",
             params: {
               reportable_type: "Wishlist",
               reportable_id: wishlist.id,
               reason: "spam",
               details: "Suspicious titles"
             },
             headers: friend_headers
      end.to change(Report, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body.fetch("report")
      expect(body["reportable_type"]).to eq("Wishlist")
      expect(body["reportable_id"]).to eq(wishlist.id)
      expect(body["reason"]).to eq("spam")
      expect(body["status"]).to eq("pending")
      expect(body).to include("id", "details", "created_at")
    end

    it "submits a wishlist report for an explicit sharee [REQ-DISC-001]" do
      wishlist = create(:wishlist, :shared, owner: owner)
      WishlistShare.upsert_explicit!(wishlist: wishlist, user: sharee)
      sharee_headers = { "Authorization" => "Bearer #{ApiToken.issue_for!(sharee).last}" }

      post "/api/v1/reports",
           params: {
             reportable_type: "Wishlist",
             reportable_id: wishlist.id,
             reason: "inappropriate_content"
           },
           headers: sharee_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("report", "reportable_type")).to eq("Wishlist")
    end

    it "rejects the wishlist owner with unavailable not_found [REQ-DISC-001]" do
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")
      owner_headers = { "Authorization" => "Bearer #{ApiToken.issue_for!(owner).last}" }

      post "/api/v1/reports",
           params: {
             reportable_type: "Wishlist",
             reportable_id: wishlist.id,
             reason: "spam"
           },
           headers: owner_headers

      expect(response).to have_http_status(:not_found)
      expect(Report.count).to eq(0)
    end

    it "rejects strangers and blocked viewers with unavailable not_found [REQ-DISC-001] [REQ-BLOCK-001]" do
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")
      stranger_headers = { "Authorization" => "Bearer #{ApiToken.issue_for!(stranger).last}" }

      post "/api/v1/reports",
           params: { reportable_type: "Wishlist", reportable_id: wishlist.id, reason: "spam" },
           headers: stranger_headers
      expect(response).to have_http_status(:not_found)

      UserBlock.block!(blocker: owner, blocked: friend)
      post "/api/v1/reports",
           params: { reportable_type: "Wishlist", reportable_id: wishlist.id, reason: "spam" },
           headers: friend_headers
      expect(response).to have_http_status(:not_found)
    end

    it "rejects soft-deleted wishlists as unavailable not_found [REQ-DISC-001]" do
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")
      wishlist.soft_delete!(actor: owner)

      post "/api/v1/reports",
           params: { reportable_type: "Wishlist", reportable_id: wishlist.id, reason: "spam" },
           headers: friend_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 for a duplicate pending wishlist report [REQ-DISC-001]" do
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")
      Report.submit!(reporter: friend, reportable: wishlist, reason: "spam")

      post "/api/v1/reports",
           params: { reportable_type: "Wishlist", reportable_id: wishlist.id, reason: "scam" },
           headers: friend_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to eq(I18n.t("api.v1.errors.report_invalid"))
    end
  end
end
