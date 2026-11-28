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

  it "deep-merges per-channel patches so sibling opt-outs stick [REQ-NOTIF-001]" do
    patch "/api/v1/notification_preferences",
          params: { notification_preference: { channels: { "friend.request_received" => { "email" => false } } } },
          headers: headers, as: :json
    expect(response).to have_http_status(:ok)

    patch "/api/v1/notification_preferences",
          params: { notification_preference: { channels: { "friend.request_received" => { "push" => false } } } },
          headers: headers, as: :json
    expect(response).to have_http_status(:ok)

    pref = NotificationPreference.find_by!(user_id: user.id)
    channels = pref.enabled_channels_for("friend.request_received")
    expect(channels["email"]).to eq(false)
    expect(channels["push"]).to eq(false)
    expect(channels["in_app"]).to eq(true)
    expect(pref.channels["friend.request_received"]).to include("email" => false, "push" => false)
  end

  it "returns O7A defaults_events catalog with friend + gift keys [REQ-NOTIF-001]" do
    get "/api/v1/notification_preferences", headers: headers
    expect(response).to have_http_status(:ok)
    defaults = response.parsed_body.fetch("notification_preference").fetch("defaults_events")
    expect(defaults).to include(
      "friend.request_received",
      "friend.request_accepted",
      "gift.delivered_pending_confirmation",
      "gift.received_confirmed_to_gifter",
      "gift.thank_you",
      "gift.voided_by_owner_delete",
      "reservation.grace_started"
    )
  end
end
