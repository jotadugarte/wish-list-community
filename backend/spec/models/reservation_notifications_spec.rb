# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reservation event notifications [REQ-RES-003]" do
  let(:owner) { create(:user) }
  let(:friend) { create(:user) }
  let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }
  let(:item) { create(:item, wishlist: wishlist, title: "Libro", specifications: "tapa dura") }

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
    Reservation.create!(item: item, user: friend, status: "active", estimated_date: Date.current + 5)
  end

  it "notifies reserver on critical edit [REQ-RES-003]" do
    item.update!(title: "Libro nuevo")
    Reservation.notify_critical_edit!(item: item)
    expect(friend.notifications.where(event_key: "reservation.item_critical_edit")).to exist
  end

  it "notifies reserver on soft-delete [REQ-RES-003]" do
    item.soft_delete!(actor: owner)
    expect(friend.notifications.where(event_key: "reservation.item_deleted")).to exist
  end
end
