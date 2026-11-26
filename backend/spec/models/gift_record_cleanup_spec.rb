# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GiftRecord O8D cascades [REQ-LIFE-001] [REQ-BLOCK-002] [REQ-GIFT-002]" do
  include ActiveJob::TestHelper

  let(:owner) { create(:user) }
  let(:gifter) { create(:user) }
  let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }
  let(:item) { create(:item, wishlist: wishlist) }

  before do
    Friendship.request!(requester: owner, addressee: gifter).accept!(actor: gifter)
  end

  def open_gift!(status: "purchased_secret")
    GiftRecord.create!(item: item, gifter: gifter, status: status)
  end

  it "voids open gifts on item soft-delete, notifies gifter, and does not reopen on restore [REQ-LIFE-001]" do
    gift = open_gift!
    expect {
      item.soft_delete!(actor: owner)
    }.to change { gifter.notifications.where(event_key: "gift.voided_by_owner_delete").count }.by(1)
    expect(gift.reload.status).to eq("voided")

    item.restore!(actor: owner)
    expect(gift.reload.status).to eq("voided")
    expect(GiftRecord.where(item_id: item.id, status: GiftStatus::OPEN)).to be_empty
  end

  it "does not void received_confirmed on soft-delete [REQ-GIFT-002]" do
    gift = GiftRecord.create!(item: item, gifter: gifter, status: "received_confirmed")
    item.soft_delete!(actor: owner)
    expect(gift.reload.status).to eq("received_confirmed")
  end

  it "voids open gifts without notifying on owner block [REQ-BLOCK-002]" do
    gift = open_gift!(status: "delivered_pending_confirmation")
    Notification.create!(
      user: owner,
      event_key: "gift.delivered_pending_confirmation",
      title: "pending",
      payload: { gift_id: gift.id, item_id: item.id }
    )

    expect {
      UserBlock.block!(blocker: owner, blocked: gifter)
    }.not_to change { gifter.notifications.where(event_key: "gift.voided_by_owner_delete").count }

    expect(gift.reload.status).to eq("voided")
    expect(owner.notifications.where(event_key: "gift.delivered_pending_confirmation")).to be_empty
  end

  it "voids open gifts on friendship remove without notify [REQ-BLOCK-002]" do
    gift = open_gift!
    friendship = Friendship.between_users(owner, gifter).first!
    friendship.remove!(actor: owner)
    expect(gift.reload.status).to eq("voided")
    expect(gifter.notifications.where(event_key: "gift.voided_by_owner_delete")).to be_empty
  end

  it "reports open gift involvement for gifter confirm UX [REQ-GIFT-002]" do
    open_gift!
    expect(GiftRecord.open_between_users?(owner, gifter)).to be(true)
    expect(GiftRecord.open_between_users?(owner, create(:user))).to be(false)
  end

  it "notifies gifters when owner account soft-deletes (via wishlist/item cascade) [REQ-LIFE-001]" do
    open_gift!
    expect {
      owner.soft_delete!(actor: owner)
    }.to change { gifter.notifications.where(event_key: "gift.voided_by_owner_delete").count }.by(1)
  end
end
