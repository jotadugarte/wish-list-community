# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Member Hotwire activity B surfaces [REQ-ACT-001] [REQ-ACT-005] FC1A FC4A", type: :request do
  let(:creator) { create(:user, username: "hw_creator", password: "SecurePassword123!", password_confirmation: "SecurePassword123!") }
  let(:giver) { create(:user, username: "hw_giver", password: "SecurePassword123!", password_confirmation: "SecurePassword123!", time_zone: "UTC") }
  let(:recipient) { create(:user, username: "hw_recipient", password: "SecurePassword123!", password_confirmation: "SecurePassword123!") }

  def login_web!(user)
    post session_path, params: { email_address: user.email_address, password: "SecurePassword123!" }
  end

  def sealed_open!(budget_mode: "none", amount: nil)
    activity = Activity.create!(
      creator: creator,
      name: "Hotwire B",
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

  def wishlist(activity, user)
    Wishlist.find_by!(activity_id: activity.id, owner_id: user.id)
  end

  describe "activity board lists and items [REQ-ACT-001] [REQ-ACT-005]" do
    it "shows activity-scoped lists and items on the board (not personal My Wishlists) [REQ-ACT-001] FC1A" do
      activity = sealed_open!
      list = wishlist(activity, recipient)
      create(:item, wishlist: list, title: "Taza CRC", price_cents: 900, currency: "CRC")

      login_web!(giver)
      get member_activity_path(activity)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taza CRC")
      expect(response.body).to include(list.title).or include("@#{recipient.username}")
      expect(response.body).to include("data-testid=\"activity-wishlist-#{list.id}\"").or include("activity-lists")

      get member_wishlists_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Taza CRC")
      expect(response.body).not_to include("data-testid=\"activity-wishlist-#{list.id}\"")
    end

    it "lets the owner add an item with price on the activity board [REQ-ACT-005]" do
      activity = sealed_open!
      list = wishlist(activity, recipient)

      login_web!(recipient)
      expect {
        post member_activity_wishlist_items_path(activity, list), params: {
          item: { title: "Libro", price_cents: 1500, currency: "CRC", priority: "medium" }
        }
      }.to change { list.items.kept.count }.by(1)

      expect(response).to redirect_to(member_activity_path(activity))
      follow_redirect!
      expect(response.body).to include("Libro")
      item = list.items.kept.find_by!(title: "Libro")
      expect(item.price_cents).to eq(1500)
      expect(item.currency).to eq("CRC")
    end

    it "shows budget enforcement errors on the activity board [REQ-ACT-005]" do
      activity = sealed_open!(budget_mode: "fixed", amount: 1000)
      list = wishlist(activity, recipient)

      login_web!(recipient)
      post member_activity_wishlist_items_path(activity, list), params: {
        item: { title: "Caro", price_cents: 2500, currency: "CRC" }
      }
      expect(response).to have_http_status(:unprocessable_content).or be_redirect
      body = response.redirect? ? (follow_redirect! && response.body) : response.body
      expect(body).to match(/budget|fixed|price|presupuesto|precio/i)
      expect(list.items.kept.where(title: "Caro")).to be_empty
    end
  end

  describe "reserve gift grace on activity items [REQ-ACT-001] [REQ-RES-004] [REQ-RES-006]" do
    it "reserves from the board and supports cancel purchase deliver confirm [REQ-RES-004]" do
      activity = sealed_open!
      list = wishlist(activity, recipient)
      item = create(:item, wishlist: list, title: "Bufanda", price_cents: 800, currency: "CRC")

      login_web!(giver)
      get member_activity_path(activity)
      expect(response.body).to include("Bufanda")
      expect(response.body).to match(/reserve|Reservar/i)

      post member_item_reservations_path(item), params: { estimated_date: (Date.current + 7).to_s }
      expect(response).to be_redirect
      hold = Reservation.find_by!(item: item, user: giver)
      expect(hold.status).to eq("active")

      get member_activity_path(activity)
      expect(response.body).to match(/cancel|Cancelar|extend|Extender|mark.?purchased|Compr/i)

      post mark_purchased_member_reservation_path(hold)
      gift = GiftRecord.find_by!(item: item, gifter: giver)
      expect(gift.status).to eq("purchased_secret")

      post mark_delivered_member_gift_path(gift)
      expect(gift.reload.status).to eq("delivered_pending_confirmation")

      login_web!(recipient)
      post confirm_received_member_gift_path(gift), params: { thank_you_note: "Gracias" }
      expect(gift.reload.status).to eq("received_confirmed")
    end

    it "extends a grace hold from the activity board [REQ-RES-006]" do
      activity = sealed_open!
      item = create(:item, wishlist: wishlist(activity, recipient), title: "Grace Item", price_cents: 500, currency: "CRC")
      hold = ReservationService.create!(item: item, user: giver, estimated_date: Date.current + 3)
      hold.update!(status: "expired_grace", grace_expires_at: 2.days.from_now, estimated_date: Date.current - 1)

      login_web!(giver)
      get member_activity_path(activity)
      expect(response.body).to match(/extend|Extender/i)

      patch member_reservation_path(hold), params: { estimated_date: (Date.current + 10).to_s }
      expect(response).to be_redirect
      expect(hold.reload.status).to eq("active")
      expect(hold.estimated_date).to eq(Date.current + 10)
    end
  end

  describe "FC1A board-only and FC4A no Secret Link [REQ-ACT-001]" do
    it "does not expose activity wishlists under personal wishlist show [REQ-ACT-001] FC1A" do
      activity = sealed_open!
      list = wishlist(activity, recipient)

      login_web!(recipient)
      get member_wishlist_path(list)
      expect(response).to have_http_status(:not_found).or have_http_status(:forbidden)
        .or redirect_to(member_activity_path(activity))
    end

    it "does not show Secret Link controls on activity board lists [REQ-ACT-001] FC4A" do
      activity = sealed_open!
      list = wishlist(activity, recipient)
      create(:item, wishlist: list, title: "Sin enlace", price_cents: 400, currency: "CRC")

      login_web!(recipient)
      get member_activity_path(activity)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to match(/Secret Link|enlace secreto|rotate_share_token|Rotar enlace/i)
      expect(response.body).not_to include("/s/")
      expect(list.share_token).to be_blank
    end
  end
end
