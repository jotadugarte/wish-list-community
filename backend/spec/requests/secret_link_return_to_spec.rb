# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Secret Link return_to auth", type: :request do
  let(:owner) { create(:user, username: "return_owner") }
  let(:wishlist) { create(:wishlist, :shared, owner: owner) }
  let(:return_to) { "/s/#{wishlist.share_token}" }

  describe "web login with return_to [REQ-WISH-005] [REQ-AUTH-001]" do
    it "redirects back to the Secret Link and registers Shared-with-me [REQ-WISH-005] [REQ-WISH-003]" do
      viewer = create(:user, email_address: "viewer_rt@example.com", username: "viewer_rt", password: "SecurePassword123!", password_confirmation: "SecurePassword123!")

      get "/session/new", params: { return_to: return_to }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(return_to)

      post "/session", params: {
        email_address: viewer.email_address,
        password: "SecurePassword123!",
        return_to: return_to
      }
      expect(response).to redirect_to(return_to)

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(WishlistShare.exists?(user: viewer, wishlist: wishlist, source: "secret_link")).to be(true)
    end

    it "rejects open redirects and off-allowlist return_to [REQ-WISH-005]" do
      viewer = create(:user, email_address: "viewer_evil@example.com", username: "viewer_evil", password: "SecurePassword123!", password_confirmation: "SecurePassword123!")

      post "/session", params: {
        email_address: viewer.email_address,
        password: "SecurePassword123!",
        return_to: "//evil.example"
      }
      expect(response).to redirect_to(root_path)

      post "/session", params: {
        email_address: viewer.email_address,
        password: "SecurePassword123!",
        return_to: "https://evil.example/phish"
      }
      expect(response).to redirect_to(root_path)

      post "/session", params: {
        email_address: viewer.email_address,
        password: "SecurePassword123!",
        return_to: "/wishlists/1"
      }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "web signup with return_to [REQ-WISH-005] [REQ-AUTH-001] [REQ-AUTH-002]" do
    it "creates an account with terms acceptance and returns to the Secret Link [REQ-AUTH-002]" do
      post "/signup", params: {
        email_address: "newbie@example.com",
        username: "newbie_link",
        password: "SecurePassword123!",
        password_confirmation: "SecurePassword123!",
        terms_accepted: "1",
        return_to: return_to
      }

      expect(response).to redirect_to(return_to)
      user = User.find_by(username: "newbie_link")
      expect(user.terms_accepted_at).to be_present

      follow_redirect!
      expect(WishlistShare.exists?(user: user, wishlist: wishlist, source: "secret_link")).to be(true)
    end
  end
end
