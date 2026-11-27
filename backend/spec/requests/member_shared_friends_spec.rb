# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Hotwire shared and friends shells [REQ-WISH-003] [REQ-SOC-001]", type: :request do
  let(:viewer) { create(:user, username: "viewer_s9") }
  let(:owner) { create(:user, username: "owner_s9") }

  def login_web!(user)
    post "/session", params: { email_address: user.email_address, password: "SecurePassword123!" }
  end

  before { login_web!(viewer) }

  it "lists shared wishlists on /app/shared" do
    Friendship.request!(requester: owner, addressee: viewer).accept!(actor: viewer)
    wishlist = create(:wishlist, :shared, owner: owner, title: "Regalos compartidos")
    WishlistShare.create!(wishlist: wishlist, user: viewer)

    get "/app/shared"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Regalos compartidos")
    expect(response.body).to include("@owner_s9")
  end

  it "lists friends and incoming requests on /app/friends" do
    friend = create(:user, username: "amigo_s9")
    requester = create(:user, username: "pide_s9")
    Friendship.request!(requester: viewer, addressee: friend).accept!(actor: friend)
    Friendship.request!(requester: requester, addressee: viewer)

    get "/app/friends"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("@amigo_s9")
    expect(response.body).to include("@pide_s9")
    expect(response.body).to include("Accept").or include("Aceptar")
    expect(response.body).to include("Decline").or include("Rechazar")
  end

  it "shows reserve form for non-owner on a shared wishlist [REQ-RES-001]" do
    Friendship.request!(requester: owner, addressee: viewer).accept!(actor: viewer)
    wishlist = create(:wishlist, :shared, owner: owner, title: "Para reservar")
    WishlistShare.create!(wishlist: wishlist, user: viewer)
    create(:item, wishlist: wishlist, title: "Libro")

    get "/app/wishlists/#{wishlist.id}"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Libro")
    expect(response.body).to include("estimated_date")
    expect(response.body).to include("Reserve").or include("Reservar")
  end
end

