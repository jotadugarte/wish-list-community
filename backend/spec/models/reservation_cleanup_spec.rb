# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reservation cleanup hooks [REQ-LIFE-001] [REQ-BLOCK-002]" do
  let(:owner) { create(:user) }
  let(:friend) { create(:user) }
  let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }
  let(:item) { create(:item, wishlist: wishlist) }

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
  end

  it "cancels active/grace on item soft-delete and does not resurrect on restore [REQ-LIFE-001]" do
    reservation = Reservation.create!(item: item, user: friend, status: "active", estimated_date: Date.current + 3)
    item.soft_delete!(actor: owner)
    expect(reservation.reload.status).to eq("canceled")

    item.restore!(actor: owner)
    expect(reservation.reload.status).to eq("canceled")
    expect(Reservation.where(item_id: item.id, status: ReservationStatus::ACTIVE_HOLD)).to be_empty
  end

  it "cancels reservations between users on block [REQ-BLOCK-002]" do
    reservation = Reservation.create!(item: item, user: friend, status: "active", estimated_date: Date.current + 3)
    UserBlock.block!(blocker: owner, blocked: friend)
    expect(reservation.reload.status).to eq("canceled")
  end

  it "cancels reservations between users on friendship remove [REQ-BLOCK-002]" do
    reservation = Reservation.create!(item: item, user: friend, status: "active", estimated_date: Date.current + 3)
    friendship = Friendship.between_users(owner, friend).first!
    friendship.remove!(actor: owner)
    expect(reservation.reload.status).to eq("canceled")
  end
end
