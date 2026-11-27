# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin reports queue [REQ-ADM-001]", type: :request do
  let(:password) { "SecurePassword123!" }
  let!(:admin) do
    create(
      :user,
      role: "admin",
      username: "panel_admin",
      email_address: "panel_admin@example.com",
      password: password,
      password_confirmation: password
    )
  end
  let!(:member) do
    create(
      :user,
      username: "panel_member",
      email_address: "panel_member@example.com",
      password: password,
      password_confirmation: password
    )
  end
  let(:reporter) { create(:user, username: "panel_reporter", email_address: "panel_reporter@example.com") }
  let!(:user_report) { Report.submit!(reporter: reporter, reportable: member, reason: "spam") }

  def sign_in(user)
    post "/session", params: { email_address: user.email_address, password: password }
  end

  describe "admin gate (O1A/O6A)" do
    it "allows role=admin cookie session to reach /admin [REQ-ADM-001]" do
      sign_in(admin)
      get "/admin"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("admin.nav.reports"))
    end

    it "returns not-found for non-admin members without revealing the panel [REQ-ADM-001]" do
      sign_in(member)
      get "/admin"
      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to match(/pending report|Suspend|Dismiss/i)
    end

    it "returns not-found for guests [REQ-ADM-001]" do
      get "/admin"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "pending reports index/show" do
    let(:owner) { create(:user, username: "wl_owner_admin", email_address: "wl_owner_admin@example.com") }
    let(:friend) { create(:user, username: "wl_friend_admin", email_address: "wl_friend_admin@example.com") }
    let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }
    let!(:wishlist_report) do
      Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
      Report.submit!(reporter: friend, reportable: wishlist, reason: "scam")
    end

    before { sign_in(admin) }

    it "lists pending User and Wishlist reports [REQ-ADM-001]" do
      get "/admin/reports"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("@#{member.username}")
      expect(response.body).to include(wishlist.title)
      expect(response.body).to include("User")
      expect(response.body).to include("Wishlist")
    end

    it "shows a User report with clear user action targets [REQ-ADM-001]" do
      get "/admin/reports/#{user_report.id}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("admin.actions.dismiss"))
      expect(response.body).to include(I18n.t("admin.actions.suspend"))
      expect(response.body).to include(I18n.t("admin.actions.soft_delete_account"))
      expect(response.body).to include("@#{member.username}")
    end

    it "shows a Wishlist report with wishlist soft-delete action [REQ-ADM-001]" do
      get "/admin/reports/#{wishlist_report.id}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("admin.actions.soft_delete_wishlist"))
      expect(response.body).to include(wishlist.title)
    end
  end

  describe "triage actions" do
    before { sign_in(admin) }

    it "dismisses a pending report [REQ-ADM-001]" do
      post "/admin/reports/#{user_report.id}/dismiss"
      expect(response).to redirect_to("/admin/reports")
      expect(user_report.reload.status).to eq("dismissed")
    end

    it "suspends the reported user [REQ-ADM-001]" do
      post "/admin/reports/#{user_report.id}/suspend"
      expect(response).to redirect_to("/admin/reports")
      expect(user_report.reload.status).to eq("reviewed")
      expect(member.reload.suspended?).to be(true)
    end

    it "soft-deletes the reported user account [REQ-ADM-001]" do
      post "/admin/reports/#{user_report.id}/soft_delete_user"
      expect(response).to redirect_to("/admin/reports")
      expect(user_report.reload.status).to eq("reviewed")
      expect(member.reload.discarded?).to be(true)
    end

    it "soft-deletes the reported wishlist [REQ-ADM-001]" do
      owner = create(:user, username: "sd_owner", email_address: "sd_owner@example.com")
      friend = create(:user, username: "sd_friend", email_address: "sd_friend@example.com")
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")
      Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
      wl_report = Report.submit!(reporter: friend, reportable: wishlist, reason: "spam")

      post "/admin/reports/#{wl_report.id}/soft_delete_wishlist"
      expect(response).to redirect_to("/admin/reports")
      expect(wl_report.reload.status).to eq("reviewed")
      expect(wishlist.reload.discarded?).to be(true)
    end
  end

  describe "rate_limit on admin writes" do
    it "declares rate_limit covering dismiss, suspend, soft_delete_user, soft_delete_wishlist [REQ-ADM-001]" do
      source = File.read(Rails.root.join("app/controllers/admin/reports_controller.rb"))
      %w[dismiss suspend soft_delete_user soft_delete_wishlist].each do |action|
        expect(source).to match(/rate_limit[\s\S]*#{action}/)
      end
      expect(source).to include("current_user&.id || request.remote_ip")
      expect(Admin::ReportsController).to respond_to(:rate_limit)
    end
  end
end
