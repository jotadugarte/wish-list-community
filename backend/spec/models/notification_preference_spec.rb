# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationPreference, type: :model do
  # Sprint 9 O7A + Sprint A/B activity events.
  # Traceability: [REQ-NOTIF-001]
  let(:expected_catalog) do
    %w[
      friend.request_received
      friend.request_accepted
      reservation.grace_started
      reservation.auto_released
      reservation.item_critical_edit
      reservation.item_deleted
      gift.delivered_pending_confirmation
      gift.received_confirmed_to_gifter
      gift.thank_you
      gift.voided_by_owner_delete
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
      activity.item_touched_while_reserved
      activity.reservation_created
      activity.reservation_released
      activity.reservation_grace_started
      activity.reservation_auto_released
      activity.gift_purchased
      activity.gift_delivered
      activity.gift_received
      activity.budget_rejected
    ]
  end

  describe "event catalog [REQ-NOTIF-001]" do
    it "exposes the full defaults_events catalog including friend, gift, and activity keys [REQ-NOTIF-001]" do
      expect(described_class::DEFAULT_EVENTS).to match_array(expected_catalog)
      expected_catalog.each do |key|
        expect(described_class::DEFAULT_EVENTS).to include(key)
      end
    end

    it "defaults every catalog event to in_app/email/push enabled when channels blank [REQ-NOTIF-001]" do
      pref = described_class.new(user: build(:user), channels: {})
      expected_catalog.each do |event_key|
        channels = pref.enabled_channels_for(event_key)
        expect(channels).to eq("in_app" => true, "email" => true, "push" => true),
                            "expected defaults for #{event_key}"
      end
    end

    it "honors per-channel toggles for friend and gift events [REQ-NOTIF-001]" do
      pref = described_class.new(
        user: build(:user),
        channels: {
          "friend.request_received" => { "push" => false, "email" => true, "in_app" => true },
          "gift.thank_you" => { "email" => false }
        }
      )
      expect(pref.enabled_channels_for("friend.request_received")["push"]).to eq(false)
      expect(pref.enabled_channels_for("gift.thank_you")["email"]).to eq(false)
      expect(pref.enabled_channels_for("gift.thank_you")["in_app"]).to eq(true)
    end
  end
end
