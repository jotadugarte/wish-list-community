# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Friendship notification dispatch [REQ-NOTIF-001] [REQ-SOC-001]" do
  let(:alice) { create(:user, username: "alice_s9") }
  let(:bob) { create(:user, username: "bob_s9") }

  it "notifies addressee on request! with friend.request_received" do
    expect do
      Friendship.request!(requester: alice, addressee: bob)
    end.to change { bob.notifications.where(event_key: "friend.request_received").count }.by(1)

    note = bob.notifications.find_by!(event_key: "friend.request_received")
    expect(note.title).to be_present
    expect(alice.notifications.where(event_key: "friend.request_received")).to be_empty
  end

  it "notifies requester on accept! with friend.request_accepted" do
    friendship = Friendship.request!(requester: alice, addressee: bob)
    expect do
      friendship.accept!(actor: bob)
    end.to change { alice.notifications.where(event_key: "friend.request_accepted").count }.by(1)

    note = alice.notifications.find_by!(event_key: "friend.request_accepted")
    expect(note.title).to be_present
    expect(bob.notifications.where(event_key: "friend.request_accepted")).to be_empty
  end

  it "honors prefs: skipped when all channels off for friend.request_received" do
    NotificationPreference.create!(
      user: bob,
      channels: { "friend.request_received" => { "in_app" => false, "email" => false, "push" => false } }
    )
    expect do
      Friendship.request!(requester: alice, addressee: bob)
    end.not_to change { bob.notifications.count }
  end

  it "uses bilingual I18n titles for friend events" do
    I18n.with_locale(:es) do
      Friendship.request!(requester: alice, addressee: bob)
      note = bob.notifications.find_by!(event_key: "friend.request_received")
      expect(note.title).to eq(I18n.t("notifications.friend.request_received.title"))
    end
  end
end
