# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Gifts", type: :request do
  let(:owner) { create(:user, username: "gift_owner") }
  let(:friend) { create(:user, username: "gift_friend", time_zone: "America/Costa_Rica") }
  let(:other) { create(:user, username: "gift_other") }
  let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }
  let(:item) { create(:item, wishlist: wishlist, title: "Libro") }
  let(:friend_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(friend).last}" } }
  let(:owner_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(owner).last}" } }
  let(:other_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(other).last}" } }

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
    Friendship.request!(requester: owner, addressee: other).accept!(actor: other)
  end

  def create_hold!
    Reservation.create!(item: item, user: friend, status: "active", estimated_date: Date.current + 7)
  end

  describe "Path 1 mark purchased / delivered / confirm [REQ-GIFT-001] [REQ-ARCH-003]" do
    it "marks purchased, delivers, and confirms with thank-you [REQ-GIFT-001] [REQ-GIFT-004]" do
      hold = create_hold!
      post "/api/v1/reservations/#{hold.id}/mark_purchased",
           params: { gift: { purchase_link_ref: "https://store.example/libro" } },
           headers: friend_headers
      expect(response).to have_http_status(:created)
      gift_body = response.parsed_body["gift"]
      expect(gift_body["status"]).to eq("purchased_secret")
      expect(gift_body).not_to have_key("purchase_link_ref")
      gift_id = gift_body["id"]
      expect(hold.reload.status).to eq("completed_by_gift")

      post "/api/v1/gifts/#{gift_id}/mark_delivered", headers: friend_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["gift"]["status"]).to eq("delivered_pending_confirmation")

      post "/api/v1/gifts/#{gift_id}/confirm_received",
           params: { gift: { thank_you_note: "¡Gracias!" } },
           headers: owner_headers
      expect(response).to have_http_status(:ok)
      confirmed = response.parsed_body["gift"]
      expect(confirmed["status"]).to eq("received_confirmed")
      expect(confirmed).not_to have_key("gifter_id")
      expect(friend.notifications.pluck(:event_key)).to include("gift.thank_you")
    end

    it "returns 409 when open gift already exists [REQ-GIFT-002]" do
      hold = create_hold!
      GiftRecord.create!(item: item, gifter: other, status: "purchased_secret")
      post "/api/v1/reservations/#{hold.id}/mark_purchased", headers: friend_headers
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["errors"]).to be_present
      expect(response.parsed_body).not_to have_key("error")
    end
  end

  describe "Path 2 owner mark received [REQ-GIFT-003]" do
    it "marks free item received without thank-you [REQ-GIFT-003]" do
      post "/api/v1/items/#{item.id}/mark_received",
           params: { gift: { thank_you_note: "ignored" } },
           headers: owner_headers
      expect(response).to have_http_status(:created)
      body = response.parsed_body["gift"]
      expect(body["status"]).to eq("received_confirmed")
      expect(body["gifter_id"]).to be_nil
      expect(body).not_to have_key("purchase_link_ref")
    end
  end

  describe "block/unfriend confirm when open gift [REQ-GIFT-002] [REQ-BLOCK-002]" do
    it "requires confirm_void_gifts when gifter blocks with open gift [REQ-BLOCK-002]" do
      GiftRecord.create!(item: item, gifter: friend, status: "purchased_secret")
      post "/api/v1/user_blocks",
           params: { blocked_username: owner.username },
           headers: friend_headers
      expect(response).to have_http_status(:unprocessable_content)

      post "/api/v1/user_blocks",
           params: { blocked_username: owner.username, confirm_void_gifts: true },
           headers: friend_headers
      expect(response).to have_http_status(:created)
      expect(GiftRecord.last.status).to eq("voided")
    end

    it "requires confirm_void_gifts when gifter unfriends with open gift [REQ-GIFT-002]" do
      GiftRecord.create!(item: item, gifter: friend, status: "purchased_secret")
      friendship = Friendship.between_users(owner, friend).find_by!(status: "accepted")

      delete "/api/v1/friendships/#{friendship.id}", headers: friend_headers
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"].first).to include("confirm_void_gifts")

      delete "/api/v1/friendships/#{friendship.id}",
             params: { confirm_void_gifts: true },
             headers: friend_headers
      expect(response).to have_http_status(:no_content)
      expect(GiftRecord.find_by!(item: item).status).to eq("voided")
    end
  end
end
