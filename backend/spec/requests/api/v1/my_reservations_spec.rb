# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::MyReservations", type: :request do
  let(:owner) { create(:user) }
  let(:friend) { create(:user) }
  let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }
  let(:item) { create(:item, wishlist: wishlist, title: "Libro") }
  let(:headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(friend).last}" } }

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
  end

  it "lists active and grace reservations for the current user [REQ-RES-004]" do
    active = Reservation.create!(item: item, user: friend, status: "active", estimated_date: Date.current + 3)
    other_item = create(:item, wishlist: wishlist, title: "Otro")
    grace = Reservation.create!(
      item: other_item, user: friend, status: "expired_grace",
      estimated_date: Date.current - 1, grace_expires_at: 2.days.from_now
    )
    canceled_item = create(:item, wishlist: wishlist, title: "Cancelado")
    Reservation.create!(item: canceled_item, user: friend, status: "canceled", estimated_date: Date.current + 1)

    get "/api/v1/my_reservations", headers: headers
    expect(response).to have_http_status(:ok)
    ids = response.parsed_body["reservations"].map { |r| r["id"] }
    expect(ids).to contain_exactly(active.id, grace.id)
    row = response.parsed_body["reservations"].find { |r| r["id"] == active.id }
    expect(row["item_title"]).to eq("Libro")
    expect(row["wishlist_title"]).to eq(wishlist.title)
  end
end
