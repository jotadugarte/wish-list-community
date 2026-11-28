# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API session device_token binding [REQ-AUTH-001] [REQ-NOTIF-002]", type: :request do
  let(:user) { create(:user, password: "SecurePassword123!") }

  it "accepts device_token on login (alias of fcm_token)" do
    expect {
      post "/api/v1/session", params: {
        email_address: user.email_address,
        password: "SecurePassword123!",
        device_token: "fcm_from_mobile_login"
      }
    }.to change { DeviceToken.where(token: "fcm_from_mobile_login").count }.by(1)

    expect(response).to have_http_status(:created)
  end

  it "rebinds device_token on PATCH /api/v1/session for restore flows" do
    _token, raw = ApiToken.issue_for!(user)
    headers = { "Authorization" => "Bearer #{raw}" }

    patch "/api/v1/session", params: { device_token: "fcm_restored" }, headers: headers
    expect(response).to have_http_status(:no_content)
    expect(DeviceToken.find_by!(token: "fcm_restored").user_id).to eq(user.id)
  end
end
