# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Wishlists", type: :request do
  let(:owner) { create(:user, username: "owner_lists") }
  let(:friend) { create(:user, username: "friend_viewer") }
  let(:owner_token) { ApiToken.issue_for!(owner).last }
  let(:headers) { { "Authorization" => "Bearer #{owner_token}" } }

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
  end

  describe "POST /api/v1/wishlists [REQ-WISH-001]" do
    it "creates a wishlist with privacy_mode friends and nil share_token [REQ-WISH-001]" do
      post "/api/v1/wishlists", params: { wishlist: { title: "Cumpleaños" } }, headers: headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body["wishlist"]
      expect(body["title"]).to eq("Cumpleaños")
      expect(body["privacy_mode"]).to eq("friends")
      expect(body["share_token"]).to be_nil
    end
  end

  describe "GET /api/v1/wishlists and show/update/delete [REQ-WISH-001] [REQ-LIFE-001]" do
    it "lists, shows, updates privacy, soft-deletes, and restores [REQ-WISH-001] [REQ-WISH-002] [REQ-LIFE-001]" do
      post "/api/v1/wishlists", params: { wishlist: { title: "Navidad" } }, headers: headers
      id = response.parsed_body["wishlist"]["id"]

      get "/api/v1/wishlists", headers: headers
      expect(response.parsed_body["wishlists"].map { |w| w["id"] }).to include(id)

      get "/api/v1/wishlists/#{id}", headers: headers
      expect(response).to have_http_status(:ok)

      patch "/api/v1/wishlists/#{id}",
            params: { wishlist: { privacy_mode: "shared", event_date: "2026-12-25" } },
            headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["wishlist"]["privacy_mode"]).to eq("shared")
      expect(response.parsed_body["wishlist"]["share_token"]).to be_present
      expect(response.parsed_body["wishlist"]["event_date"]).to eq("2026-12-25")

      delete "/api/v1/wishlists/#{id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Wishlist.find(id)).to be_discarded

      post "/api/v1/wishlists/#{id}/restore", headers: headers
      expect(response).to have_http_status(:ok)
      expect(Wishlist.find(id)).not_to be_discarded
    end
  end

  describe "GET show share_token visibility [REQ-WISH-006]" do
    it "omits share_token for non-owner viewers [REQ-WISH-006]" do
      wishlist = create(:wishlist, :shared, owner: owner)
      WishlistShare.upsert_explicit!(wishlist: wishlist, user: friend)
      friend_headers = { "Authorization" => "Bearer #{ApiToken.issue_for!(friend).last}" }

      get "/api/v1/wishlists/#{wishlist.id}", headers: friend_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["wishlist"]).not_to have_key("share_token")

      get "/api/v1/wishlists/#{wishlist.id}", headers: headers
      expect(response.parsed_body["wishlist"]["share_token"]).to eq(wishlist.share_token)
    end

    it "returns 404 when updating a soft-deleted wishlist [REQ-LIFE-001]" do
      wishlist = create(:wishlist, owner: owner)
      wishlist.soft_delete!(actor: owner)

      patch "/api/v1/wishlists/#{wishlist.id}",
            params: { wishlist: { title: "Nope" } },
            headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST share_token/rotate and shares [REQ-WISH-002] [REQ-WISH-003] [REQ-WISH-006]" do
    it "rotates the token and manages explicit shares [REQ-WISH-002] [REQ-WISH-003] [REQ-WISH-006]" do
      wishlist = create(:wishlist, :shared, owner: owner)
      old_token = wishlist.share_token
      secret_viewer = create(:user)
      WishlistShare.upsert_secret_link!(wishlist: wishlist, user: secret_viewer)

      post "/api/v1/wishlists/#{wishlist.id}/share_token/rotate", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["wishlist"]["share_token"]).not_to eq(old_token)
      expect(WishlistShare.where(wishlist: wishlist, user: secret_viewer)).not_to exist

      post "/api/v1/wishlists/#{wishlist.id}/shares", params: { user_id: friend.id }, headers: headers
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["share"]["source"]).to eq("explicit")

      delete "/api/v1/wishlists/#{wishlist.id}/shares/#{friend.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(WishlistShare.where(wishlist: wishlist, user: friend)).not_to exist
    end
  end
end
