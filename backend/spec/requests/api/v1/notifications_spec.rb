# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Notifications", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(user).last}" } }

  it "lists notifications and marks read [REQ-NOTIF-001]" do
    note = Notification.create!(user: user, event_key: "reservation.grace_started", title: "Grace", body: "x")
    get "/api/v1/notifications", headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["notifications"].map { |n| n["id"] }).to include(note.id)

    post "/api/v1/notifications/#{note.id}/mark_read", headers: headers
    expect(response).to have_http_status(:ok)
    expect(note.reload.read_at).to be_present
  end

  it "shows and updates notification preferences [REQ-NOTIF-001]" do
    get "/api/v1/notification_preferences", headers: headers
    expect(response).to have_http_status(:ok)

    patch "/api/v1/notification_preferences",
          params: { notification_preference: { channels: { "reservation.grace_started" => { "email" => false } } } },
          headers: headers
    expect(response).to have_http_status(:ok)
    pref = NotificationPreference.find_by!(user_id: user.id)
    expect(pref.enabled_channels_for("reservation.grace_started")["email"]).to eq(false)
  end
end
