# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Secret Links item list (O1A)", type: :request do
  let(:owner) { create(:user, username: "list_owner") }
  let(:viewer) { create(:user, username: "list_viewer") }
  let(:wishlist) { create(:wishlist, :shared, owner: owner, title: "Fiesta") }

  def login_web!(user)
    post "/session", params: {
      email_address: user.email_address,
      password: "SecurePassword123!"
    }
  end

  describe "GET /s/:share_token with items [REQ-WISH-005] [REQ-ITEM-001]" do
    it "keeps guest OG invitation free of item titles and images [REQ-WISH-005]" do
      create(:item, wishlist: wishlist, title: "Secret Gadget XYZ", specifications: "Red")

      get "/s/#{wishlist.share_token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Lista de deseos de @list_owner")
      expect(response.body).not_to include("Secret Gadget XYZ")
      expect(response.body).not_to include("specifications")
    end

    it "shows item list with reservation actions to authorized logged-in viewers [REQ-ITEM-001] [REQ-RES-001]" do
      create(:item, wishlist: wishlist, title: "Secret Gadget XYZ", specifications: "Talla M", priority: "high")
      create(:item_link, item: Item.last, url: "https://shop.example/g")

      login_web!(viewer)
      get "/s/#{wishlist.share_token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Secret Gadget XYZ")
      expect(response.body).to include("Talla M")
      expect(response.body).to include("https://shop.example/g")
      expect(response.body).to include('data-availability="available"')
      expect(response.body).to include("Reservar").or include("Reserve")
      expect(response.body).to include("Disponible").or include("Available")
    end
  end
end
