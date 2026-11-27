# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin gift detail O5A [REQ-ADM-001] [REQ-GIFT-001]", type: :request do
  let(:password) { "SecurePassword123!" }
  let!(:admin) do
    create(
      :user,
      role: "admin",
      username: "gift_admin",
      email_address: "gift_admin@example.com",
      password: password,
      password_confirmation: password
    )
  end
  let(:owner) { create(:user, username: "gift_owner", email_address: "gift_owner@example.com") }
  let(:gifter) do
    create(
      :user,
      username: "secret_gifter",
      email_address: "secret_gifter@example.com",
      password: password,
      password_confirmation: password
    )
  end
  let(:wishlist) { create(:wishlist, owner: owner) }
  let(:item) { create(:item, wishlist: wishlist, title: "Libro") }
  let!(:gift) do
    GiftRecord.create!(
      item: item,
      gifter: gifter,
      status: "purchased_secret",
      purchase_link_ref: "https://store.example/libro"
    )
  end

  def sign_in(user)
    post "/session", params: { email_address: user.email_address, password: password }
  end

  describe "Hotwire admin gift detail" do
    it "shows gifter @username, email, and purchase_link_ref read-only" do
      sign_in(admin)
      get "/admin/gifts/#{gift.id}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("@secret_gifter")
      expect(response.body).to include("secret_gifter@example.com")
      expect(response.body).to include("https://store.example/libro")
    end

    it "returns not-found for non-admins" do
      sign_in(gifter)
      get "/admin/gifts/#{gift.id}"
      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("secret_gifter@example.com")
    end

    it "shows the same fields from an audit gift detail context" do
      AuditEvent.record!(actor: gifter, action: "gift.purchased", auditable: gift)
      event = AuditEvent.order(:id).last
      sign_in(admin)
      get "/admin/audit_events/#{event.id}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("@secret_gifter")
      expect(response.body).to include("secret_gifter@example.com")
      expect(response.body).to include("https://store.example/libro")
    end
  end

  describe "member API never leaks admin-only gift fields" do
    it "omits purchase_link_ref, gifter email, and gifter username even for admin API tokens" do
      post "/api/v1/session", params: {
        email_address: admin.email_address,
        password: password
      }, as: :json
      token = response.parsed_body["token"]

      get "/api/v1/items/#{item.id}", headers: { "Authorization" => "Bearer #{token}" }, as: :json
      body = response.parsed_body.to_s
      expect(body).not_to include("purchase_link_ref")
      expect(body).not_to include("secret_gifter@example.com")
      expect(body).not_to include("@secret_gifter")

      json = gift.as_api_json(viewer: admin)
      expect(json).not_to have_key(:purchase_link_ref)
      expect(json).not_to have_key("purchase_link_ref")
      expect(json).not_to have_key(:gifter_email)
      expect(json).not_to have_key(:gifter_username)
    end
  end
end
