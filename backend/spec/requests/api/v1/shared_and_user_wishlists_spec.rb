# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 shared and user wishlists", type: :request do
  let(:owner) { create(:user, username: "list_owner") }
  let(:friend) { create(:user, username: "list_friend") }
  let(:stranger) { create(:user, username: "list_stranger") }
  let(:friend_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(friend).last}" } }
  let(:stranger_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(stranger).last}" } }

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
  end

  describe "GET /api/v1/shared_wishlists [REQ-WISH-003]" do
    it "lists wishlists registered via secret_link share [REQ-WISH-003]" do
      wishlist = create(:wishlist, :shared, owner: owner)
      WishlistShare.upsert_secret_link!(wishlist: wishlist, user: friend)

      get "/api/v1/shared_wishlists", headers: friend_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["wishlists"].map { |w| w["id"] }).to include(wishlist.id)
    end
  end

  describe "GET /api/v1/users/:username/wishlists [REQ-WISH-001] [REQ-BLOCK-001]" do
    it "returns friends-mode lists to accepted friends and empty/deny to strangers [REQ-WISH-001]" do
      friends_list = create(:wishlist, owner: owner, privacy_mode: "friends", title: "Amigos")
      shared_list = create(:wishlist, :shared, owner: owner, title: "Seleccionados")

      get "/api/v1/users/list_owner/wishlists", headers: friend_headers
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["wishlists"].map { |w| w["id"] }
      expect(ids).to include(friends_list.id)
      expect(ids).not_to include(shared_list.id)

      get "/api/v1/users/list_owner/wishlists", headers: stranger_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["wishlists"]).to eq([])
    end

    it "returns 404 when a block exists either direction [REQ-BLOCK-001]" do
      create(:wishlist, owner: owner, privacy_mode: "friends")
      UserBlock.block!(blocker: owner, blocked: friend)

      get "/api/v1/users/list_owner/wishlists", headers: friend_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
