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
  end
end
