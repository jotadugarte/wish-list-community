# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Secret Link reservations (O4B)", type: :request do
  let(:owner) { create(:user, username: "sl_owner") }
  let(:viewer) { create(:user, username: "sl_viewer") }
  let(:wishlist) { create(:wishlist, :shared, owner: owner, title: "Fiesta") }
  let(:item) { create(:item, wishlist: wishlist, title: "Regalo") }

  def login_web!(user)
    post "/session", params: {
      email_address: user.email_address,
      password: "SecurePassword123!"
    }
  end

  it "lets a logged-in sharee reserve extend and cancel [REQ-RES-001] [REQ-WISH-002]" do
    login_web!(viewer)

    post "/s/#{wishlist.share_token}/items/#{item.id}/reservations",
         params: { estimated_date: (Date.current + 7).iso8601 }
    expect(response).to redirect_to("/s/#{wishlist.share_token}")
    reservation = Reservation.find_by!(item: item, user: viewer, status: "active")

    patch "/s/#{wishlist.share_token}/reservations/#{reservation.id}",
          params: { estimated_date: (Date.current + 14).iso8601 }
    expect(response).to redirect_to("/s/#{wishlist.share_token}")
    expect(reservation.reload.estimated_date).to eq(Date.current + 14)

    delete "/s/#{wishlist.share_token}/reservations/#{reservation.id}"
    expect(response).to redirect_to("/s/#{wishlist.share_token}")
    expect(reservation.reload.status).to eq("canceled")
  end

  it "does not show reserve controls to the owner [REQ-RES-002]" do
    create(:item, wishlist: wishlist, title: "Own item")
    login_web!(owner)
    get "/s/#{wishlist.share_token}"
    expect(response.body).not_to include("data-testid=\"reserve-")
    expect(response.body).not_to include("available")
  end

  it "requires login for guests to reserve [REQ-WISH-002]" do
    post "/s/#{wishlist.share_token}/items/#{item.id}/reservations",
         params: { estimated_date: (Date.current + 7).iso8601 }
    expect(response).to redirect_to(%r{/session/new})
  end
end
