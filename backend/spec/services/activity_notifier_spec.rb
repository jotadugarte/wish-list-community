# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityNotifier do
  let(:creator) { create(:user) }
  let(:invitee) { create(:user) }
  let(:activity) do
    Activity.create!(
      creator: creator,
      name: "Grupo",
      currency: "CRC",
      assignment_mode: "secret_santa",
      visibility_mode: "recipient_only",
      reservation_visibility: "hidden_from_recipient",
      budget_mode: "none"
    )
  end

  describe "catalog + prefs [REQ-NOTIF-001] [REQ-NOTIF-002]" do
    it "includes Sprint A activity event keys in the preference catalog [REQ-NOTIF-001]" do
      expected = %w[
        activity.invite
        activity.accepted
        activity.declined
        activity.co_organizer_appointed
        activity.drawn
        activity.arrancar
        activity.left
        activity.dropout_needs_cure
        activity.blind_bridged
        activity.full_redraw
        activity.cancelled
        activity.ownership_transferred
      ]
      expect(NotificationPreference::DEFAULT_EVENTS).to include(*expected)
    end

    it "dispatches invite notifications respecting prefs [REQ-NOTIF-001]" do
      preference = NotificationPreference.create!(
        user: invitee,
        channels: {
          "activity.invite" => { "in_app" => true, "email" => false, "push" => false }
        }
      )
      expect(preference.enabled_channels_for("activity.invite")["in_app"]).to eq(true)

      described_class.invite!(activity: activity, recipient: invitee, actor: creator)
      expect(Notification.where(user: invitee, event_key: "activity.invite")).to exist
    end

    it "dispatches private draw notice to each giver without revealing others [REQ-NOTIF-001]" do
      a = create(:user)
      b = create(:user)
      [ a, b ].each { |u| ActivityParticipant.invite!(activity: activity, user: u, actor: creator).accept! }
      ActivityDrawService.draw!(activity: activity, actor: creator, seed: 12)
      described_class.drawn!(activity: activity)

      [ creator, a, b ].each do |user|
        note = Notification.find_by(user: user, event_key: "activity.drawn")
        expect(note).to be_present
        expect(note.payload["recipient_username"]).to be_present
        expect(note.payload).not_to have_key("assignments")
      end
    end
  end
end
