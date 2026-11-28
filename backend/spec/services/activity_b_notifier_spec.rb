# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Activity B notification catalog O6A [REQ-NOTIF-001]" do
  let(:creator) { create(:user, locale: "en") }
  let(:giver) { create(:user, locale: "en", time_zone: "UTC") }
  let(:recipient) { create(:user, locale: "es") }

  def sealed_open_activity!
    activity = Activity.create!(
      creator: creator,
      name: "Avisos B",
      currency: "CRC",
      assignment_mode: "open_gifting",
      visibility_mode: "all_participants",
      reservation_visibility: "visible_to_recipient",
      budget_mode: "none"
    )
    [ giver, recipient ].each do |user|
      ActivityParticipant.invite!(activity: activity, user: user, actor: creator).accept!
    end
    ActivityOpenGiftingService.arrancar!(activity: activity, actor: creator)
    activity
  end

  def activity_item!(activity, owner, title:, price_cents: nil)
    list = Wishlist.find_by!(activity_id: activity.id, owner_id: owner.id)
    attrs = { wishlist: list, title: title }
    attrs[:price_cents] = price_cents if price_cents
    attrs[:currency] = activity.currency if price_cents
    create(:item, **attrs)
  end

  describe "preference catalog keys [REQ-NOTIF-001] O6A" do
    it "includes Sprint B activity event keys in DEFAULT_EVENTS [REQ-NOTIF-001]" do
      expected = %w[
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
      expect(NotificationPreference::DEFAULT_EVENTS).to include(*expected)
    end
  end

  describe "ActivityNotifier B methods [REQ-NOTIF-001] O6A" do
    it "notifies reserver when reserved activity item is critically edited [REQ-NOTIF-001]" do
      activity = sealed_open_activity!
      item = activity_item!(activity, recipient, title: "Libro")
      ReservationService.create!(item: item, user: giver, estimated_date: Date.current + 5)

      item.update!(title: "Libro editado")
      Reservation.notify_critical_edit!(item: item)

      expect(giver.notifications.where(event_key: "activity.item_touched_while_reserved")).to exist
      expect(giver.notifications.where(event_key: "reservation.item_critical_edit")).not_to exist
    end

    it "notifies item owner on activity reserve when reservation_visibility is visible [REQ-NOTIF-001]" do
      activity = sealed_open_activity!
      item = activity_item!(activity, recipient, title: "Taza")

      ReservationService.create!(item: item, user: giver, estimated_date: Date.current + 4)

      expect(recipient.notifications.where(event_key: "activity.reservation_created")).to exist
    end

    it "notifies item owner on activity voluntary release [REQ-NOTIF-001]" do
      activity = sealed_open_activity!
      item = activity_item!(activity, recipient, title: "Bufanda")
      hold = ReservationService.create!(item: item, user: giver, estimated_date: Date.current + 4)
      recipient.notifications.where(event_key: "activity.reservation_created").delete_all

      ReservationService.cancel!(reservation: hold, actor: giver)

      expect(recipient.notifications.where(event_key: "activity.reservation_released")).to exist
    end

    it "notifies reserver with activity grace and auto-release keys [REQ-NOTIF-001]" do
      activity = sealed_open_activity!
      item = activity_item!(activity, recipient, title: "Grace")
      reservation = Reservation.create!(
        item: item, user: giver, status: "active", estimated_date: Date.yesterday
      )

      ReservationGraceSweepJob.perform_now
      expect(giver.notifications.where(event_key: "activity.reservation_grace_started")).to exist
      expect(giver.notifications.where(event_key: "reservation.grace_started")).not_to exist

      reservation.reload.update!(grace_expires_at: 1.minute.ago)
      ReservationGraceSweepJob.perform_now
      expect(giver.notifications.where(event_key: "activity.reservation_auto_released")).to exist
      expect(giver.notifications.where(event_key: "reservation.auto_released")).not_to exist
    end

    it "notifies with activity gift purchased/delivered/received keys [REQ-NOTIF-001]" do
      activity = sealed_open_activity!
      item = activity_item!(activity, recipient, title: "Regalo")
      hold = ReservationService.create!(item: item, user: giver, estimated_date: Date.current + 5)

      gift = GiftService.mark_purchased!(reservation: hold, actor: giver)
      expect(giver.notifications.where(event_key: "activity.gift_purchased")).to exist

      GiftService.mark_delivered!(gift: gift, actor: giver)
      expect(recipient.notifications.where(event_key: "activity.gift_delivered")).to exist
      expect(recipient.notifications.where(event_key: "gift.delivered_pending_confirmation")).not_to exist

      GiftService.confirm_received!(gift: gift.reload, actor: recipient, thank_you_note: "Thanks")
      expect(giver.notifications.where(event_key: "activity.gift_received")).to exist
      expect(giver.notifications.where(event_key: "gift.received_confirmed_to_gifter")).not_to exist
    end

    it "notifies item owner when activity reserve is rejected for budget [REQ-NOTIF-001]" do
      activity = Activity.create!(
        creator: creator,
        name: "Presupuesto",
        currency: "CRC",
        assignment_mode: "open_gifting",
        visibility_mode: "all_participants",
        reservation_visibility: "visible_to_recipient",
        budget_mode: "fixed",
        budget_amount_cents: 1000
      )
      [ giver, recipient ].each do |user|
        ActivityParticipant.invite!(activity: activity, user: user, actor: creator).accept!
      end
      ActivityOpenGiftingService.arrancar!(activity: activity, actor: creator)
      item = activity_item!(activity, recipient, title: "Caro", price_cents: 1000)
      item.update_columns(price_cents: 2500)

      expect {
        ReservationService.create!(item: item, user: giver, estimated_date: Date.current + 3)
      }.to raise_error(ArgumentError, /budget|fixed|price/i)

      expect(recipient.notifications.where(event_key: "activity.budget_rejected")).to exist
    end
  end
end
