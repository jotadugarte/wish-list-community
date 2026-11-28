# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Activity reservations [REQ-RES-005] [REQ-ACT-005]" do
  let(:creator) { create(:user) }
  let(:giver) { create(:user) }
  let(:recipient) { create(:user) }

  def accept_pair!(activity)
    [ giver, recipient ].each do |user|
      ActivityParticipant.invite!(activity: activity, user: user, actor: creator).accept!
    end
  end

  def wishlist(activity, user)
    Wishlist.find_by!(activity_id: activity.id, owner_id: user.id)
  end

  describe "ensure sets default max [REQ-RES-005] O5A" do
    it "sets max_reservations_per_user=1 for secret_santa wishlists [REQ-RES-005]" do
      activity = Activity.create!(
        creator: creator,
        name: "SS max1",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
      ActivityParticipant.invite!(activity: activity, user: giver, actor: creator).accept!

      expect(wishlist(activity, giver).max_reservations_per_user).to eq(1)
      expect(wishlist(activity, creator).max_reservations_per_user).to eq(1)
    end

    it "sets max_reservations_per_user=1 by default for open_gifting [REQ-RES-005]" do
      activity = Activity.create!(
        creator: creator,
        name: "Open default",
        currency: "CRC",
        assignment_mode: "open_gifting",
        visibility_mode: "all_participants",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
      ActivityParticipant.invite!(activity: activity, user: giver, actor: creator).accept!

      expect(wishlist(activity, giver).max_reservations_per_user).to eq(1)
    end
  end

  describe "SS max 1 enforcement [REQ-RES-005]" do
    let(:activity) do
      Activity.create!(
        creator: creator,
        name: "SS reserve",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
    end

    before do
      accept_pair!(activity)
      ActivityAssignment.create!(activity: activity, giver: giver, recipient: recipient)
      ActivityAssignment.create!(activity: activity, giver: recipient, recipient: creator)
      ActivityAssignment.create!(activity: activity, giver: creator, recipient: giver)
      activity.update!(status: "sealed", sealed_at: Time.current)
    end

    it "allows one active hold then blocks a second on the same wishlist [REQ-RES-005] [REQ-RES-001]" do
      list = wishlist(activity, recipient)
      item_a = create(:item, wishlist: list, title: "A")
      item_b = create(:item, wishlist: list, title: "B")

      ReservationService.create!(item: item_a, user: giver, estimated_date: Date.current + 3)
      expect {
        ReservationService.create!(item: item_b, user: giver, estimated_date: Date.current + 4)
      }.to raise_error(ReservationService::Error, /l[ií]mite|limit/i)
    end

    it "blocks a second hold on another activity wishlist (activity-wide SS cap) [REQ-RES-005]" do
      open_vis = Activity.create!(
        creator: creator,
        name: "SS all-vis",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "all_participants",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
      accept_pair!(open_vis)
      ActivityAssignment.create!(activity: open_vis, giver: giver, recipient: recipient)
      ActivityAssignment.create!(activity: open_vis, giver: recipient, recipient: creator)
      ActivityAssignment.create!(activity: open_vis, giver: creator, recipient: giver)
      open_vis.update!(status: "sealed", sealed_at: Time.current)

      list_a = wishlist(open_vis, recipient)
      list_b = wishlist(open_vis, creator)
      item_a = create(:item, wishlist: list_a, title: "A")
      item_b = create(:item, wishlist: list_b, title: "B")

      ReservationService.create!(item: item_a, user: giver, estimated_date: Date.current + 3)
      expect {
        ReservationService.create!(item: item_b, user: giver, estimated_date: Date.current + 4)
      }.to raise_error(ReservationService::Error, /l[ií]mite|limit/i)
    end
  end

  describe "open_gifting configured N [REQ-RES-005] O5A" do
    let(:activity) do
      Activity.create!(
        creator: creator,
        name: "Open N",
        currency: "CRC",
        assignment_mode: "open_gifting",
        visibility_mode: "all_participants",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
    end

    before { accept_pair!(activity) }

    it "allows N holds after ActivityReservationLimitService.set! [REQ-RES-005]" do
      ActivityReservationLimitService.set!(activity: activity, actor: creator, max: 2)
      ActivityOpenGiftingService.arrancar!(activity: activity, actor: creator)
      list = wishlist(activity, recipient)
      item_a = create(:item, wishlist: list, title: "A")
      item_b = create(:item, wishlist: list, title: "B")
      item_c = create(:item, wishlist: list, title: "C")

      ReservationService.create!(item: item_a, user: giver, estimated_date: Date.current + 3)
      ReservationService.create!(item: item_b, user: giver, estimated_date: Date.current + 4)
      expect {
        ReservationService.create!(item: item_c, user: giver, estimated_date: Date.current + 5)
      }.to raise_error(ReservationService::Error, /l[ií]mite|limit/i)
    end
  end

  describe "freeze N at draw/arrancar [REQ-RES-005] FC3A" do
    it "keeps max on wishlists after arrancar and rejects further set! [REQ-RES-005]" do
      activity = Activity.create!(
        creator: creator,
        name: "Freeze",
        currency: "CRC",
        assignment_mode: "open_gifting",
        visibility_mode: "all_participants",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
      accept_pair!(activity)
      ActivityReservationLimitService.set!(activity: activity, actor: creator, max: 2)
      ActivityOpenGiftingService.arrancar!(activity: activity, actor: creator)

      expect(wishlist(activity, giver).max_reservations_per_user).to eq(2)
      expect {
        ActivityReservationLimitService.set!(activity: activity, actor: creator, max: 4)
      }.to raise_error(ArgumentError, /seal|frozen|sealed/i)
    end
  end

  describe "budget re-check on reserve [REQ-ACT-005] O4A" do
    let(:activity) do
      Activity.create!(
        creator: creator,
        name: "Budget reserve",
        currency: "CRC",
        assignment_mode: "open_gifting",
        visibility_mode: "all_participants",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "fixed",
        budget_amount_cents: 1000
      )
    end

    before do
      accept_pair!(activity)
      ActivityOpenGiftingService.arrancar!(activity: activity, actor: creator)
    end

    it "rejects reserve when item price violates budget_mode [REQ-ACT-005]" do
      list = wishlist(activity, recipient)
      # bypass item create guard to simulate stale/out-of-policy price
      item = create(:item, wishlist: list, title: "Too cheap", price_cents: 1000, currency: "CRC")
      item.update_columns(price_cents: 500)

      expect {
        ReservationService.create!(item: item.reload, user: giver, estimated_date: Date.current + 2)
      }.to raise_error(ReservationService::Error, /budget|fixed|price/i)
    end

    it "allows reserve when price still satisfies budget [REQ-ACT-005]" do
      list = wishlist(activity, recipient)
      item = create(:item, wishlist: list, title: "Ok", price_cents: 1000, currency: "CRC")

      reservation = ReservationService.create!(
        item: item, user: giver, estimated_date: Date.current + 2
      )
      expect(reservation).to be_persisted
      expect(reservation.status).to eq("active")
    end
  end

  describe "ReservationService.create! uses visibility gate [REQ-ACT-001]" do
    it "rejects reserve when viewer cannot see the list [REQ-ACT-001]" do
      activity = Activity.create!(
        creator: creator,
        name: "Gate",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
      accept_pair!(activity)
      ActivityAssignment.create!(activity: activity, giver: giver, recipient: recipient)
      ActivityAssignment.create!(activity: activity, giver: recipient, recipient: creator)
      ActivityAssignment.create!(activity: activity, giver: creator, recipient: giver)
      activity.update!(status: "sealed", sealed_at: Time.current)
      item = create(:item, wishlist: wishlist(activity, recipient), title: "Gift")

      expect {
        ReservationService.create!(item: item, user: creator, estimated_date: Date.current + 2)
      }.to raise_error(ReservationService::Error, /reserve not allowed/i)
    end
  end
end
