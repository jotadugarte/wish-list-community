# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Item availability [REQ-RES-002]" do
  let(:owner) { create(:user) }
  let(:friend) { create(:user) }
  let(:other) { create(:user) }
  let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }
  let(:item) { create(:item, wishlist: wishlist) }

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
    Friendship.request!(requester: owner, addressee: other).accept!(actor: other)
  end

  it "omits availability for the owner and includes viewer-relative values for friends [REQ-RES-002]" do
    expect(item.as_api_json(viewer: owner)).not_to have_key(:availability)
    expect(item.as_api_json(viewer: friend)[:availability]).to eq("available")

    Reservation.create!(item: item, user: friend, status: "active", estimated_date: Date.current + 3)
    expect(item.as_api_json(viewer: friend)[:availability]).to eq("reserved_by_me")
    expect(item.as_api_json(viewer: other)[:availability]).to eq("unavailable")
    expect(item.as_api_json(viewer: owner)).not_to have_key(:availability)
  end

  it "does not change items.updated_at when reserving [REQ-RES-002]" do
    item.update_columns(updated_at: 3.days.ago)
    before = item.reload.updated_at
    ReservationService.create!(item: item, user: friend, estimated_date: Date.current + 4)
    expect(item.reload.updated_at).to eq(before)
  end
end
