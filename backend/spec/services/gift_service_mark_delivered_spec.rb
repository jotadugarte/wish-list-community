# frozen_string_literal: true

require "rails_helper"

RSpec.describe GiftService, "#mark_delivered! [REQ-GIFT-001] [REQ-NOTIF-001]" do
  include ActiveJob::TestHelper

  let(:owner) { create(:user, locale: "es") }
  let(:gifter) { create(:user) }
  let(:other) { create(:user) }
  let(:wishlist) { create(:wishlist, owner: owner) }
  let(:item) { create(:item, wishlist: wishlist, title: "Taza") }
  let!(:gift) do
    GiftRecord.create!(item: item, gifter: gifter, status: "purchased_secret")
  end

  it "moves purchased_secret → delivered_pending_confirmation and notifies owner anonymously [REQ-GIFT-001]" do
    expect {
      result = described_class.mark_delivered!(gift: gift, actor: gifter)
      expect(result.status).to eq("delivered_pending_confirmation")
    }.to change { owner.notifications.count }.by(1)

    note = owner.notifications.order(:id).last
    expect(note.event_key).to eq("gift.delivered_pending_confirmation")
    expect(note.title).not_to match(/#{gifter.username}/i)
    expect(note.body.to_s).not_to match(/#{gifter.username}/i)
    expect(note.payload["gifter_id"]).to be_nil
    expect(note.payload["item_id"]).to eq(item.id)
    expect(AuditEvent.where(action: "gift.mark_delivered", auditable: gift).count).to eq(1)
  end

  it "rejects non-gifter and non-purchased_secret [REQ-GIFT-001]" do
    expect {
      described_class.mark_delivered!(gift: gift, actor: other)
    }.to raise_error(GiftService::Error)

    gift.update_columns(status: "delivered_pending_confirmation")
    expect {
      described_class.mark_delivered!(gift: gift.reload, actor: gifter)
    }.to raise_error(GiftService::Error)
  end
end
