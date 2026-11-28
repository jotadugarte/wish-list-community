# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 activity B surfaces [REQ-ACT-005] [REQ-RES-004] [REQ-RES-005] [REQ-ARCH-001]", type: :request do
  let(:creator) { create(:user, username: "b_creator") }
  let(:giver) { create(:user, username: "b_giver", time_zone: "UTC") }
  let(:recipient) { create(:user, username: "b_recipient") }
  let(:outsider) { create(:user, username: "b_outsider") }
  let(:creator_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(creator).last}" } }
  let(:giver_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(giver).last}" } }
  let(:recipient_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(recipient).last}" } }
  let(:outsider_headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(outsider).last}" } }

  def sealed_open!(budget_mode: "none", amount: nil)
    activity = Activity.create!(
      creator: creator,
      name: "API B",
      currency: "CRC",
      assignment_mode: "open_gifting",
      visibility_mode: "all_participants",
      reservation_visibility: "visible_to_recipient",
      budget_mode: budget_mode,
      budget_amount_cents: amount
    )
    [ giver, recipient ].each do |user|
      ActivityParticipant.invite!(activity: activity, user: user, actor: creator).accept!
    end
    ActivityOpenGiftingService.arrancar!(activity: activity, actor: creator)
    activity
  end

  def open_unsealed!
    activity = Activity.create!(
      creator: creator,
      name: "Pre-seal",
      currency: "CRC",
      assignment_mode: "open_gifting",
      visibility_mode: "all_participants",
      reservation_visibility: "hidden_from_recipient",
      budget_mode: "none"
    )
    [ giver, recipient ].each do |user|
      ActivityParticipant.invite!(activity: activity, user: user, actor: creator).accept!
    end
    activity
  end

  def wishlist(activity, user)
    Wishlist.find_by!(activity_id: activity.id, owner_id: user.id)
  end

  describe "activity wishlist show + items CRUD [REQ-ACT-005] [REQ-ARCH-001]" do
    it "lists and shows activity wishlists and supports item CRUD [REQ-ACT-005]" do
      activity = sealed_open!
      list = wishlist(activity, recipient)

      get "/api/v1/activities/#{activity.id}/wishlists", headers: giver_headers
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["wishlists"].map { |w| w["id"] }
      # open_gifting + all_participants: peer lists are visible to accepted participants
      expect(ids).to include(list.id)

      get "/api/v1/activities/#{activity.id}/wishlists/#{list.id}", headers: giver_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["wishlist"]["id"]).to eq(list.id)
      expect(response.parsed_body["wishlist"]["activity_id"]).to eq(activity.id)
      expect(response.parsed_body["wishlist"]).not_to have_key("share_token")

      post "/api/v1/activities/#{activity.id}/wishlists/#{list.id}/items",
           params: {
             item: { title: "Libro", price_cents: 1500, currency: "CRC", priority: "medium" }
           },
           headers: recipient_headers
      expect(response).to have_http_status(:created)
      item = response.parsed_body["item"]
      expect(item["title"]).to eq("Libro")
      expect(item["price_cents"]).to eq(1500)
      item_id = item["id"]

      get "/api/v1/activities/#{activity.id}/wishlists/#{list.id}/items", headers: giver_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["items"].map { |i| i["id"] }).to include(item_id)

      patch "/api/v1/activities/#{activity.id}/items/#{item_id}",
            params: { item: { title: "Libro Pro" } },
            headers: recipient_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["item"]["title"]).to eq("Libro Pro")

      delete "/api/v1/activities/#{activity.id}/items/#{item_id}", headers: recipient_headers
      expect(response).to have_http_status(:no_content)
      expect(Item.find(item_id)).to be_discarded
    end

    it "rejects outsider wishlist access [REQ-ARCH-001]" do
      activity = sealed_open!
      list = wishlist(activity, recipient)

      get "/api/v1/activities/#{activity.id}/wishlists/#{list.id}", headers: outsider_headers
      expect(response).to have_http_status(:not_found).or have_http_status(:forbidden)
    end
  end

  describe "reserve / extend / cancel + gifts on activity items [REQ-RES-004] [REQ-ACT-005]" do
    it "reserves extends cancels and runs gift Path 1 on activity items [REQ-RES-004]" do
      activity = sealed_open!
      list = wishlist(activity, recipient)
      item = create(:item, wishlist: list, title: "Taza", price_cents: 500, currency: "CRC")

      post "/api/v1/items/#{item.id}/reservations",
           params: { reservation: { estimated_date: (Date.current + 7).iso8601, private_note: "ok" } },
           headers: giver_headers
      expect(response).to have_http_status(:created)
      reservation_id = response.parsed_body["reservation"]["id"]

      patch "/api/v1/reservations/#{reservation_id}",
            params: { reservation: { estimated_date: (Date.current + 14).iso8601 } },
            headers: giver_headers
      expect(response).to have_http_status(:ok)

      delete "/api/v1/reservations/#{reservation_id}", headers: giver_headers
      expect(response).to have_http_status(:no_content)

      item2 = create(:item, wishlist: list, title: "Bufanda", price_cents: 800, currency: "CRC")
      post "/api/v1/items/#{item2.id}/reservations",
           params: { reservation: { estimated_date: (Date.current + 5).iso8601 } },
           headers: giver_headers
      hold_id = response.parsed_body["reservation"]["id"]

      post "/api/v1/reservations/#{hold_id}/mark_purchased",
           params: { gift: { purchase_link_ref: "https://shop.example/b" } },
           headers: giver_headers
      expect(response).to have_http_status(:created)
      gift_id = response.parsed_body["gift"]["id"]

      post "/api/v1/gifts/#{gift_id}/mark_delivered", headers: giver_headers
      expect(response).to have_http_status(:ok)

      post "/api/v1/gifts/#{gift_id}/confirm_received",
           params: { gift: { thank_you_note: "Gracias" } },
           headers: recipient_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["gift"]["status"]).to eq("received_confirmed")
    end
  end

  describe "my_reservations includes activity holds [REQ-RES-004]" do
    it "returns activity-scoped active holds alongside personal ones [REQ-RES-004]" do
      activity = sealed_open!
      item = create(:item, wishlist: wishlist(activity, recipient), title: "Act item")
      hold = ReservationService.create!(item: item, user: giver, estimated_date: Date.current + 4)

      get "/api/v1/my_reservations", headers: giver_headers
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["reservations"].map { |r| r["id"] }
      expect(ids).to include(hold.id)
      row = response.parsed_body["reservations"].find { |r| r["id"] == hold.id }
      expect(row["item_title"]).to eq("Act item")
      expect(row["activity_id"]).to eq(activity.id)
    end
  end

  describe "open_gifting N setting pre-seal only [REQ-RES-005]" do
    it "sets max_reservations_per_user before seal and rejects after [REQ-RES-005]" do
      activity = open_unsealed!

      patch "/api/v1/activities/#{activity.id}/reservation_limit",
            params: { max_reservations_per_user: 3 },
            headers: creator_headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["max_reservations_per_user"]).to eq(3)
      expect(wishlist(activity, giver).reload.max_reservations_per_user).to eq(3)

      ActivityOpenGiftingService.arrancar!(activity: activity, actor: creator)

      patch "/api/v1/activities/#{activity.id}/reservation_limit",
            params: { max_reservations_per_user: 5 },
            headers: creator_headers
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "error shapes for budget / visibility / limit [REQ-ACT-005] [REQ-RES-005] [REQ-ARCH-001]" do
    it "returns unprocessable_content with errors array for budget reject on item create [REQ-ACT-005]" do
      activity = sealed_open!(budget_mode: "fixed", amount: 1000)
      list = wishlist(activity, recipient)

      post "/api/v1/activities/#{activity.id}/wishlists/#{list.id}/items",
           params: { item: { title: "Caro", price_cents: 2500, currency: "CRC" } },
           headers: recipient_headers
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_an(Array)
      expect(response.parsed_body["errors"].join).to match(/budget|fixed|price/i)
    end

    it "returns unprocessable_content for visibility-blocked reserve [REQ-ARCH-001]" do
      third = create(:user, username: "b_third")
      activity = Activity.create!(
        creator: creator,
        name: "SS3",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
      [ giver, recipient, third ].each do |user|
        ActivityParticipant.invite!(activity: activity, user: user, actor: creator).accept!
      end
      ActivityDrawService.draw!(activity: activity, actor: creator, seed: 11)
      assigned = ActivityAssignment.find_by!(activity: activity, giver: giver).recipient
      peer = ([ recipient, third ] - [ assigned ]).first
      item = create(:item, wishlist: wishlist(activity, peer), title: "Wrong list")

      post "/api/v1/items/#{item.id}/reservations",
           params: { reservation: { estimated_date: (Date.current + 3).iso8601 } },
           headers: giver_headers
      # Anti-leak: unauthorized activity lists return not_found; gate/service errors use errors[].
      expect(response).to have_http_status(:unprocessable_content)
        .or have_http_status(:forbidden)
        .or have_http_status(:not_found)
      body = response.parsed_body
      expect(body["errors"] || body["error"]).to be_present
    end

    it "returns unprocessable_content when reservation limit reached [REQ-RES-005]" do
      activity = sealed_open!
      Wishlist.where(activity_id: activity.id).update_all(max_reservations_per_user: 1)
      list = wishlist(activity, recipient)
      first = create(:item, wishlist: list, title: "One")
      second = create(:item, wishlist: list, title: "Two")

      post "/api/v1/items/#{first.id}/reservations",
           params: { reservation: { estimated_date: (Date.current + 3).iso8601 } },
           headers: giver_headers
      expect(response).to have_http_status(:created)

      post "/api/v1/items/#{second.id}/reservations",
           params: { reservation: { estimated_date: (Date.current + 3).iso8601 } },
           headers: giver_headers
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_an(Array)
    end
  end
end
