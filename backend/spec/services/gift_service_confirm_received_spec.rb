# frozen_string_literal: true

require "rails_helper"

RSpec.describe GiftService, "confirm / owner mark received [REQ-GIFT-001] [REQ-GIFT-003] [REQ-GIFT-004] [REQ-ITEM-004]" do
  include ActiveJob::TestHelper

  let(:owner) { create(:user) }
  let(:gifter) { create(:user, locale: "es") }
  let(:reserver) { create(:user, locale: "en") }
  let(:wishlist) { create(:wishlist, owner: owner) }
  let(:item) { create(:item, wishlist: wishlist, title: "Libro") }

  describe "#confirm_received! Path 1" do
    let!(:gift) do
      GiftRecord.create!(item: item, gifter: gifter, status: "delivered_pending_confirmation")
    end

    it "confirms receipt with optional thank-you to gifter [REQ-GIFT-001] [REQ-GIFT-004]" do
      result = described_class.confirm_received!(
        gift: gift,
        actor: owner,
        thank_you_note: "¡Gracias!"
      )
      expect(result.status).to eq("received_confirmed")
      expect(result.thank_you_note).to eq("¡Gracias!")

      keys = gifter.notifications.order(:id).pluck(:event_key)
      expect(keys).to include("gift.received_confirmed_to_gifter")
      expect(keys).to include("gift.thank_you")
      thank = gifter.notifications.find_by(event_key: "gift.thank_you")
      expect(thank.body).to include("¡Gracias!")
    end

    it "skips thank-you notification when note blank (O5A) [REQ-GIFT-004]" do
      described_class.confirm_received!(gift: gift, actor: owner, thank_you_note: nil)
      expect(gifter.notifications.where(event_key: "gift.thank_you")).to be_empty
      expect(gifter.notifications.where(event_key: "gift.received_confirmed_to_gifter").count).to eq(1)
    end

    it "rejects non-owner [REQ-GIFT-001]" do
      expect {
        described_class.confirm_received!(gift: gift, actor: gifter)
      }.to raise_error(GiftService::Error)
    end
  end

  describe "#owner_mark_received! Path 2" do
    it "closes active hold, creates received_confirmed, notifies reserver [REQ-GIFT-003]" do
      hold = Reservation.create!(
        item: item, user: reserver, status: "active", estimated_date: Date.current + 4
      )
      gift = described_class.owner_mark_received!(
        item: item, actor: owner, thank_you_note: "Thanks"
      )
      expect(gift.status).to eq("received_confirmed")
      expect(gift.gifter_id).to eq(reserver.id)
      expect(gift.thank_you_note).to eq("Thanks")
      expect(hold.reload.status).to eq("completed_by_gift")
      expect(reserver.notifications.pluck(:event_key)).to include(
        "gift.received_confirmed_to_gifter",
        "gift.thank_you"
      )
    end

    it "promotes open purchased_secret gift to received_confirmed [REQ-GIFT-001]" do
      open_gift = GiftRecord.create!(item: item, gifter: gifter, status: "purchased_secret")
      result = described_class.owner_mark_received!(item: item, actor: owner, thank_you_note: nil)
      expect(result.id).to eq(open_gift.id)
      expect(result.status).to eq("received_confirmed")
      expect(gifter.notifications.pluck(:event_key)).to include("gift.received_confirmed_to_gifter")
      expect(gifter.notifications.where(event_key: "gift.thank_you")).to be_empty
    end

    it "FC1: free item with no gifter → received_confirmed, no thank-you [REQ-GIFT-003]" do
      gift = described_class.owner_mark_received!(item: item, actor: owner, thank_you_note: "ignored")
      expect(gift.status).to eq("received_confirmed")
      expect(gift.gifter_id).to be_nil
      expect(gift.thank_you_note).to be_nil
      expect(Notification.where(event_key: "gift.thank_you")).to be_empty
    end
  end
end
