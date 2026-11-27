# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Hotwire reservations and gifts [REQ-RES-001] [REQ-RES-004] [REQ-GIFT-001]", type: :request do
  let(:owner) { create(:user, username: "gift_owner") }
  let(:friend) { create(:user, username: "gift_friend") }
  let(:wishlist) { create(:wishlist, :shared, owner: owner, title: "Lista regalos") }
  let(:item) { create(:item, wishlist: wishlist, title: "Auriculares") }

  def login_web!(user)
    post "/session", params: { email_address: user.email_address, password: "SecurePassword123!" }
  end

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
    WishlistShare.upsert_explicit!(wishlist: wishlist, user: friend)
  end

  it "lists my reservations shell with active holds" do
    login_web!(friend)
    ReservationService.create!(item: item, user: friend, estimated_date: Date.current + 7)
    get "/app/reservations"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Auriculares")
  end

  it "reserves an item from a shared wishlist and cancels it" do
    login_web!(friend)
    post "/app/items/#{item.id}/reservations", params: { estimated_date: (Date.current + 10).to_s }
    expect(response).to be_redirect
    reservation = Reservation.find_by!(item: item, user: friend)
    expect(reservation.status).to eq("active")

    delete "/app/reservations/#{reservation.id}"
    expect(reservation.reload.status).to eq("canceled")
  end

  it "marks purchased then delivered then owner confirms with thank-you [REQ-GIFT-001] [REQ-GIFT-004]" do
    login_web!(friend)
    reservation = ReservationService.create!(item: item, user: friend, estimated_date: Date.current + 5)
    post "/app/reservations/#{reservation.id}/mark_purchased"
    gift = GiftRecord.find_by!(item: item, gifter: friend)
    expect(gift.status).to eq("purchased_secret")

    post "/app/gifts/#{gift.id}/mark_delivered"
    expect(gift.reload.status).to eq("delivered_pending_confirmation")

    login_web!(owner)
    get "/app/reservations"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Auriculares")
    expect(response.body).to include("confirm_received").or include("Confirm").or include("Confirmar")

    post "/app/gifts/#{gift.id}/confirm_received", params: { thank_you_note: "¡Gracias!" }
    expect(gift.reload.status).to eq("received_confirmed")
    expect(gift.thank_you_note).to eq("¡Gracias!")
  end

  it "lets the owner Path-2 mark received from wishlist show [REQ-GIFT-003]" do
    free_item = create(:item, wishlist: wishlist, title: "Libre")
    login_web!(owner)
    get "/app/wishlists/#{wishlist.id}"
    expect(response.body).to include("mark_received").or include("Ya recibí").or include("already received")

    post "/app/items/#{free_item.id}/mark_received", params: { thank_you_note: "ok" }
    expect(response).to redirect_to(member_wishlist_path(wishlist))
    gift = GiftRecord.find_by!(item: free_item)
    expect(gift.status).to eq("received_confirmed")
  end
end
