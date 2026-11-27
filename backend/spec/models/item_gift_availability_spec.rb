# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Item gift availability + Received Gifts [REQ-GIFT-002] [REQ-ITEM-004] [REQ-RES-002]" do
  let(:owner) { create(:user) }
  let(:gifter) { create(:user) }
  let(:other) { create(:user) }
  let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }
  let(:item) { create(:item, wishlist: wishlist) }
  let(:received_item) { create(:item, wishlist: wishlist, title: "Recibido") }

  before do
    Friendship.request!(requester: owner, addressee: gifter).accept!(actor: gifter)
    Friendship.request!(requester: owner, addressee: other).accept!(actor: other)
  end

  it "maps open GiftRecord to unavailable for third parties and reserved_by_me for gifter (FC2) [REQ-GIFT-002]" do
    GiftRecord.create!(item: item, gifter: gifter, status: "purchased_secret")

    expect(item.as_api_json(viewer: owner)).not_to have_key(:availability)
    expect(item.as_api_json(viewer: gifter)[:availability]).to eq("reserved_by_me")
    expect(item.as_api_json(viewer: other)[:availability]).to eq("unavailable")
  end

  it "keeps hold-based availability when no open gift [REQ-RES-002]" do
    Reservation.create!(item: item, user: gifter, status: "active", estimated_date: Date.current + 2)
    expect(item.as_api_json(viewer: gifter)[:availability]).to eq("reserved_by_me")
    expect(item.as_api_json(viewer: other)[:availability]).to eq("unavailable")
  end

  it "exposes received_confirmed helpers for Received Gifts section [REQ-ITEM-004]" do
    GiftRecord.create!(item: received_item, gifter: gifter, status: "received_confirmed")
    GiftRecord.create!(item: item, gifter: gifter, status: "purchased_secret")

    expect(Item.received_gift_item_ids_for(wishlist.id)).to contain_exactly(received_item.id)
    expect(received_item.received_confirmed?).to be(true)
    expect(item.received_confirmed?).to be(false)
    payload = received_item.as_api_json(viewer: other)
    expect(payload[:received_gift]).to be(true)
    expect(payload[:availability]).to eq("available")
  end
end
