# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationDispatcher do
  include ActiveJob::TestHelper

  let(:user) { create(:user, locale: "es") }

  it "creates in-app notification and enqueues email [REQ-NOTIF-001]" do
    expect {
      note = described_class.dispatch!(
        user: user,
        event_key: "reservation.grace_started",
        title: "Grace",
        body: "Extiende o cancela"
      )
      expect(note).to be_persisted
      expect(note.event_key).to eq("reservation.grace_started")
      expect(user.notifications.count).to eq(1)
    }.to have_enqueued_mail(NotificationMailer, :event_email)
  end

  it "skips in-app when preference disables it [REQ-NOTIF-001]" do
    NotificationPreference.create!(
      user: user,
      channels: { "reservation.grace_started" => { "in_app" => false, "email" => false, "push" => false } }
    )
    expect {
      expect(described_class.dispatch!(user: user, event_key: "reservation.grace_started", title: "X")).to be_nil
    }.not_to have_enqueued_mail
    expect(user.notifications.count).to eq(0)
  end
end
