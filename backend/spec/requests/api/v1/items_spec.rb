# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe "Api::V1::Items", type: :request do
  let(:owner) { create(:user, username: "item_owner") }
  let(:friend) { create(:user, username: "item_friend") }
  let(:stranger) { create(:user, username: "item_stranger") }
  let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }
  let(:headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(owner).last}" } }
  let(:friend_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(friend).last}" } }

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
  end

  describe "CRUD [REQ-ITEM-001] [REQ-ITEM-003] [REQ-ARCH-002] [REQ-LIFE-001]" do
    it "creates lists shows updates soft-deletes and restores [REQ-ITEM-001] [REQ-LIFE-001]" do
      post "/api/v1/wishlists/#{wishlist.id}/items",
           params: {
             item: {
               title: "Auriculares",
               specifications: "Negro",
               priority: "high",
               price_cents: 5000,
               currency: "USD",
               links: [ { url: "https://shop.example/a" } ]
             }
           },
           headers: headers

      expect(response).to have_http_status(:created)
      item = response.parsed_body["item"]
      expect(item["title"]).to eq("Auriculares")
      expect(item["priority"]).to eq("high")
      expect(item["price_cents"]).to eq(5000)
      expect(item["links"].first["url"]).to eq("https://shop.example/a")
      id = item["id"]

      get "/api/v1/wishlists/#{wishlist.id}/items", headers: friend_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["items"].map { |i| i["id"] }).to include(id)

      get "/api/v1/wishlists/#{wishlist.id}/items",
          headers: { "Authorization" => "Bearer #{ApiToken.issue_for!(stranger).last}" }
      expect(response).to have_http_status(:not_found)

      patch "/api/v1/items/#{id}",
            params: { item: { title: "Auriculares Pro", priority: "must_have" } },
            headers: headers
      expect(response.parsed_body["item"]["title"]).to eq("Auriculares Pro")
      expect(response.parsed_body["item"]["priority"]).to eq("must_have")

      delete "/api/v1/items/#{id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Item.find(id)).to be_discarded

      post "/api/v1/items/#{id}/restore", headers: headers
      expect(response).to have_http_status(:ok)
      expect(Item.find(id)).not_to be_discarded
    end

    it "reorders items by position [REQ-ITEM-001]" do
      a = create(:item, wishlist: wishlist, title: "A")
      b = create(:item, wishlist: wishlist, title: "B")
      c = create(:item, wishlist: wishlist, title: "C")

      patch "/api/v1/wishlists/#{wishlist.id}/items/reorder",
            params: { item_ids: [ c.id, a.id, b.id ] },
            headers: headers

      expect(response).to have_http_status(:ok)
      titles = response.parsed_body["items"].map { |i| i["title"] }
      expect(titles).to eq(%w[C A B])
    end

    it "rejects partial reorder item_ids [REQ-ITEM-001]" do
      a = create(:item, wishlist: wishlist, title: "A")
      create(:item, wishlist: wishlist, title: "B")

      patch "/api/v1/wishlists/#{wishlist.id}/items/reorder",
            params: { item_ids: [ a.id ] },
            headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
