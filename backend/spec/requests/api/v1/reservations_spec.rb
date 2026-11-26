# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Reservations", type: :request do
  let(:owner) { create(:user, username: "res_owner") }
  let(:friend) { create(:user, username: "res_friend", time_zone: "America/Costa_Rica") }
  let(:other) { create(:user, username: "res_other") }
  let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }
  let(:item) { create(:item, wishlist: wishlist, title: "Libro") }
  let(:friend_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(friend).last}" } }
  let(:other_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(other).last}" } }

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
    Friendship.request!(requester: owner, addressee: other).accept!(actor: other)
  end

  describe "create extend cancel [REQ-RES-001] [REQ-RES-005] [REQ-ARCH-003]" do
    it "creates extends and cancels a reservation [REQ-RES-001] [REQ-RES-006]" do
      post "/api/v1/items/#{item.id}/reservations",
           params: { reservation: { estimated_date: (Date.current + 10).iso8601, private_note: "junio" } },
           headers: friend_headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body["reservation"]
      expect(body["status"]).to eq("active")
      expect(body["private_note"]).to eq("junio")
      expect(body["item_id"]).to eq(item.id)
      id = body["id"]

      patch "/api/v1/reservations/#{id}",
            params: { reservation: { estimated_date: (Date.current + 20).iso8601 } },
            headers: friend_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["reservation"]["estimated_date"]).to eq((Date.current + 20).iso8601)

      Reservation.find(id).update_columns(status: "expired_grace", grace_expires_at: 1.day.from_now)
      patch "/api/v1/reservations/#{id}",
            params: { reservation: { estimated_date: (Date.current + 30).iso8601 } },
            headers: friend_headers
      expect(response.parsed_body["reservation"]["status"]).to eq("active")
      expect(Reservation.find(id).grace_expires_at).to be_nil

      delete "/api/v1/reservations/#{id}", headers: friend_headers
      expect(response).to have_http_status(:no_content)
      expect(Reservation.find(id).status).to eq("canceled")
    end

    it "returns 409 when a second user races for the same item [REQ-ARCH-003]" do
      post "/api/v1/items/#{item.id}/reservations",
           params: { reservation: { estimated_date: (Date.current + 5).iso8601 } },
           headers: friend_headers
      expect(response).to have_http_status(:created)

      post "/api/v1/items/#{item.id}/reservations",
           params: { reservation: { estimated_date: (Date.current + 5).iso8601 } },
           headers: other_headers
      expect(response).to have_http_status(:conflict)
    end

    it "enforces max_reservations_per_user [REQ-RES-005]" do
      wishlist.update!(max_reservations_per_user: 1)
      second_item = create(:item, wishlist: wishlist, title: "Otro")

      post "/api/v1/items/#{item.id}/reservations",
           params: { reservation: { estimated_date: (Date.current + 5).iso8601 } },
           headers: friend_headers
      expect(response).to have_http_status(:created)

      post "/api/v1/items/#{second_item.id}/reservations",
           params: { reservation: { estimated_date: (Date.current + 5).iso8601 } },
           headers: friend_headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
