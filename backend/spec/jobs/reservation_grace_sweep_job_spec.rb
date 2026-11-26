# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReservationGraceSweepJob do
  let(:owner) { create(:user) }
  let(:friend) { create(:user, time_zone: "UTC") }
  let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }
  let(:item) { create(:item, wishlist: wishlist) }

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
  end

  it "moves due active reservations into expired_grace and notifies [REQ-RES-006]" do
    reservation = Reservation.create!(
      item: item, user: friend, status: "active", estimated_date: Date.yesterday
    )

    described_class.perform_now

    expect(reservation.reload.status).to eq("expired_grace")
    expect(reservation.grace_expires_at).to be_present
    expect(friend.notifications.where(event_key: "reservation.grace_started")).to exist
  end

  it "auto-releases due grace reservations and notifies [REQ-RES-006]" do
    reservation = Reservation.create!(
      item: item, user: friend, status: "expired_grace",
      estimated_date: Date.yesterday, grace_expires_at: 1.minute.ago
    )

    described_class.perform_now

    expect(reservation.reload.status).to eq("auto_released")
    expect(friend.notifications.where(event_key: "reservation.auto_released")).to exist
  end

  it "cancels holds for discarded reservers without aborting the batch [REQ-RES-006]" do
    discarded = create(:user, time_zone: "UTC")
    Friendship.request!(requester: owner, addressee: discarded).accept!(actor: discarded)
    other_item = create(:item, wishlist: wishlist, title: "Otro")
    dead_hold = Reservation.create!(
      item: item, user: discarded, status: "active", estimated_date: Date.yesterday
    )
    live_hold = Reservation.create!(
      item: other_item, user: friend, status: "active", estimated_date: Date.yesterday
    )
    discarded.update_columns(discarded_at: Time.current)

    described_class.perform_now

    expect(dead_hold.reload.status).to eq("canceled")
    expect(live_hold.reload.status).to eq("expired_grace")
  end
end
