# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Secret Link Reportar lista", type: :request do
  let(:owner) { create(:user, username: "list_owner") }
  let(:viewer) { create(:user, username: "list_viewer") }
  let(:wishlist) { create(:wishlist, :shared, owner: owner, title: "Reportable List") }

  def login_web!(user)
    post "/session", params: {
      email_address: user.email_address,
      password: "SecurePassword123!"
    }
    expect(response).to have_http_status(:redirect)
  end

  describe "GET /s/:share_token report UI [REQ-DISC-001] [REQ-WISH-002]" do
    it "shows report control with all five reasons for authenticated non-owner [REQ-DISC-001]" do
      login_web!(viewer)
      get "/s/#{wishlist.share_token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-testid="report-wishlist"')
      ReportReason::ALLOWED_REASONS.each do |reason|
        expect(response.body).to include(reason)
      end
    end

    it "hides report control from the wishlist owner [REQ-DISC-001]" do
      login_web!(owner)
      get "/s/#{wishlist.share_token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('data-testid="report-wishlist"')
    end

    it "requires guests to log in before reporting (return_to on login CTA) [REQ-AUTH-001]" do
      get "/s/#{wishlist.share_token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('data-testid="report-wishlist"')
      expect(response.body).to include("return_to=#{CGI.escape("/s/#{wishlist.share_token}")}")
    end
  end

  describe "POST /s/:share_token/report [REQ-DISC-001] [REQ-ADM-001]" do
    it "creates a pending wishlist report via CSRF form and does not notify the owner [REQ-DISC-001]" do
      login_web!(viewer)

      expect do
        post "/s/#{wishlist.share_token}/report", params: { reason: "spam", details: "Bad content" }
      end.to change(Report, :count).by(1)
        .and change(Notification, :count).by(0)

      expect(response).to redirect_to(secret_link_path(share_token: wishlist.share_token))
      expect(flash[:notice]).to be_present
      report = Report.order(:id).last
      expect(report.reportable).to eq(wishlist)
      expect(report.reporter).to eq(viewer)
      expect(report.status).to eq("pending")
      expect(Notification.where(user_id: owner.id)).to be_empty
    end

    it "redirects guests to login with return_to [REQ-AUTH-001]" do
      post "/s/#{wishlist.share_token}/report", params: { reason: "spam" }

      expect(response).to redirect_to(%r{/session/new})
      expect(response.location).to include("return_to=")
    end

    it "returns unavailable for soft-deleted or invalid token [REQ-DISC-001]" do
      login_web!(viewer)
      wishlist.soft_delete!(actor: owner)

      post "/s/#{wishlist.share_token}/report", params: { reason: "spam" }
      expect(response).to have_http_status(:not_found)

      post "/s/not-a-valid-token-zzzz/report", params: { reason: "spam" }
      expect(response).to have_http_status(:not_found)
    end

    it "declares rate_limit on create with clear wait messaging [REQ-DISC-001]" do
      source = File.read(Rails.root.join("app/controllers/secret_link_reports_controller.rb"))
      expect(source).to match(/rate_limit\s+to:\s*\d+,\s*within:/)
      expect(source).to match(/name:\s*["']secret_link_report_create["']/)
      expect(source).to include("current_user&.id || request.remote_ip")
      expect(source).to match(/status:\s*:see_other/)
      expect(source).to include("ActiveRecord::RecordNotUnique")
      expect(SecretLinkReportsController).to respond_to(:rate_limit)
      expect(I18n.t("api.v1.errors.rate_limited")).to be_present
    end
  end
end
