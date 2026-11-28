# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Secret Links Hotwire", type: :request do
  let(:owner) { create(:user, username: "og_owner") }
  let(:viewer) { create(:user, username: "link_viewer") }
  let(:wishlist) { create(:wishlist, :shared, owner: owner, title: "Privada") }

  describe "GET /s/:share_token [REQ-WISH-005] [REQ-WISH-002] [REQ-WISH-003]" do
    it "renders OG invitation for guests without item data [REQ-WISH-005]" do
      get "/s/#{wishlist.share_token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Lista de deseos de @og_owner").or include("Wishlist from @og_owner")
      expect(response.body).to include("og:title")
      expect(response.body).to include("return_to=#{CGI.escape("/s/#{wishlist.share_token}")}")
      expect(response.body).not_to include("item")
      expect(response.body).not_to include(wishlist.title)
    end

    it "upserts secret_link share and shows empty shell when logged in [REQ-WISH-003]" do
      login_web!(viewer)

      expect do
        get "/s/#{wishlist.share_token}"
      end.to change { WishlistShare.where(user: viewer, wishlist: wishlist, source: "secret_link").count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(wishlist.title)
      expect(response.body).to include("og_owner")
    end

    it "does not create a self share when the owner opens their own link [REQ-WISH-003]" do
      login_web!(owner)

      expect do
        get "/s/#{wishlist.share_token}"
      end.not_to change(WishlistShare, :count)

      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for invalid, blocked, or discarded wishlists [REQ-WISH-005] [REQ-BLOCK-001] [REQ-LIFE-001]" do
      get "/s/not-a-real-token-value-xxxxx"
      expect(response).to have_http_status(:not_found)

      UserBlock.block!(blocker: owner, blocked: viewer)
      login_web!(viewer)
      get "/s/#{wishlist.share_token}"
      expect(response).to have_http_status(:not_found)

      other = create(:user, username: "after_block", password: "SecurePassword123!", password_confirmation: "SecurePassword123!")
      login_web!(other)
      wishlist.soft_delete!(actor: owner)
      get "/s/#{wishlist.share_token}"
      expect(response).to have_http_status(:not_found)
    end
  end

  def login_web!(user)
    post "/session", params: {
      email_address: user.email_address,
      password: "SecurePassword123!"
    }
    expect(response).to have_http_status(:redirect)
  end
end
