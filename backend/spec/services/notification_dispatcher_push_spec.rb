# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationDispatcher, "push path [REQ-NOTIF-001] [REQ-NOTIF-002]" do
  let(:user) { create(:user) }
  let(:api_token) { ApiToken.issue_for!(user, fcm_token: "fcm_device_abc").first }
  let(:push_double) { instance_double(PushNotifier::NullAdapter, deliver!: true) }

  before do
    api_token
    allow(PushNotifier).to receive(:adapter).and_return(push_double)
  end

  it "calls push adapter when push enabled and DeviceTokens exist" do
    expect(push_double).to receive(:deliver!).with(
      hash_including(
        tokens: array_including("fcm_device_abc"),
        title: "Push title",
        body: "Push body",
        event_key: "friend.request_received"
      )
    )

    described_class.dispatch!(
      user: user,
      event_key: "friend.request_received",
      title: "Push title",
      body: "Push body"
    )
  end

  it "does not call push adapter when push preference is off" do
    NotificationPreference.create!(
      user: user,
      channels: { "friend.request_received" => { "in_app" => true, "email" => false, "push" => false } }
    )
    expect(push_double).not_to receive(:deliver!)

    described_class.dispatch!(
      user: user,
      event_key: "friend.request_received",
      title: "X"
    )
  end

  it "does not call push adapter when user has no DeviceTokens" do
    DeviceToken.where(user_id: user.id).delete_all
    expect(push_double).not_to receive(:deliver!)

    described_class.dispatch!(
      user: user,
      event_key: "friend.request_received",
      title: "X"
    )
  end

  it "uses NullPushAdapter by default so CI never hits Google" do
    allow(PushNotifier).to receive(:adapter).and_call_original
    expect(PushNotifier.adapter).to be_a(PushNotifier::NullAdapter)
    expect {
      described_class.dispatch!(user: user, event_key: "friend.request_received", title: "X")
    }.not_to raise_error
  end
end
