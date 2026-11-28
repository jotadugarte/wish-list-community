# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Activity gift Path 1/2 + grace [REQ-GIFT-001] [REQ-RES-006]" do
  let(:creator) { create(:user) }
  let(:giver) { create(:user, time_zone: "UTC", locale: "en") }
  let(:recipient) { create(:user, locale: "es") }

  def sealed_open_activity!
    activity = Activity.create!(
      creator: creator,
      name: "Regalos B",
      currency: "CRC",
      assignment_mode: "open_gifting",
      visibility_mode: "all_participants",
      reservation_visibility: "hidden_from_recipient",
      budget_mode: "none"
    )
    [ giver, recipient ].each do |user|
      ActivityParticipant.invite!(activity: activity, user: user, actor: creator).accept!
    end
    ActivityOpenGiftingService.arrancar!(activity: activity, actor: creator)
    activity
  end

  def activity_item!(activity, owner, title:)
    list = Wishlist.find_by!(activity_id: activity.id, owner_id: owner.id)
    create(:item, wishlist: list, title: title)
  end

  describe "Path 1 on activity-scoped item [REQ-GIFT-001] [REQ-GIFT-004] O1B" do
    it "create reservation → mark_purchased → mark_delivered → confirm_received [REQ-GIFT-001]" do
      activity = sealed_open_activity!
      item = activity_item!(activity, recipient, title: "Libro actividad")
      expect(item.wishlist.activity_scoped?).to eq(true)

      reservation = ReservationService.create!(
        item: item, user: giver, estimated_date: Date.current + 5
      )
      gift = GiftService.mark_purchased!(reservation: reservation, actor: giver)
      expect(gift.status).to eq("purchased_secret")
      expect(reservation.reload.status).to eq("completed_by_gift")

      GiftService.mark_delivered!(gift: gift, actor: giver)
      expect(gift.reload.status).to eq("delivered_pending_confirmation")
      expect(recipient.notifications.where(event_key: "activity.gift_delivered")).to exist

      confirmed = GiftService.confirm_received!(
        gift: gift.reload, actor: recipient, thank_you_note: "¡Gracias!"
      )
      expect(confirmed.status).to eq("received_confirmed")
      expect(confirmed.thank_you_note).to eq("¡Gracias!")
      expect(giver.notifications.pluck(:event_key)).to include(
        "activity.gift_purchased",
        "activity.gift_received",
        "gift.thank_you"
      )
    end
  end

  describe "Path 2 on activity-scoped item [REQ-GIFT-003] O1B" do
    it "owner_mark_received! closes activity hold and confirms [REQ-GIFT-003]" do
      activity = sealed_open_activity!
      item = activity_item!(activity, recipient, title: "Taza")
      hold = ReservationService.create!(
        item: item, user: giver, estimated_date: Date.current + 4
      )

      gift = GiftService.owner_mark_received!(
        item: item, actor: recipient, thank_you_note: "Thanks"
      )
      expect(gift.status).to eq("received_confirmed")
      expect(gift.gifter_id).to eq(giver.id)
      expect(hold.reload.status).to eq("completed_by_gift")
    end
  end

  describe "72h grace on activity holds [REQ-RES-006] O1B" do
    it "enters expired_grace and auto_releases activity-scoped reservations [REQ-RES-006]" do
      activity = sealed_open_activity!
      item = activity_item!(activity, recipient, title: "Grace item")
      expect(item.wishlist.activity_scoped?).to eq(true)
      # Past date via model (service forbids past estimated_date) — same as personal grace specs.
      reservation = Reservation.create!(
        item: item, user: giver, status: "active", estimated_date: Date.yesterday
      )

      ReservationGraceSweepJob.perform_now
      expect(reservation.reload.status).to eq("expired_grace")
      expect(reservation.grace_expires_at).to be_present
      expect(giver.notifications.where(event_key: "activity.reservation_grace_started")).to exist

      reservation.update!(grace_expires_at: 1.minute.ago)
      ReservationGraceSweepJob.perform_now
      expect(reservation.reload.status).to eq("auto_released")
      expect(giver.notifications.where(event_key: "activity.reservation_auto_released")).to exist
    end
  end
end
