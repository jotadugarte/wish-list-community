# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin audit viewer + revert [REQ-ADM-001]", type: :request do
  let(:password) { "SecurePassword123!" }
  let!(:admin) do
    create(
      :user,
      role: "admin",
      username: "audit_admin",
      email_address: "audit_admin@example.com",
      password: password,
      password_confirmation: password
    )
  end
  let!(:member) do
    create(
      :user,
      username: "audit_member",
      email_address: "audit_member@example.com",
      password: password,
      password_confirmation: password
    )
  end
  let(:reporter) { create(:user, username: "audit_reporter", email_address: "audit_reporter@example.com") }

  def sign_in(user)
    post "/session", params: { email_address: user.email_address, password: password }
  end

  before { sign_in(admin) }

  describe "list / filter" do
    it "lists AuditEvents for admins" do
      member.suspend!(actor: admin)
      get "/admin/audit_events"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("user.suspended")
      expect(response.body).to include("Audit")
    end

    it "filters by action" do
      member.suspend!(actor: admin)
      Report.submit!(reporter: reporter, reportable: member, reason: "spam").dismiss!(actor: admin)

      get "/admin/audit_events", params: { action_filter: "report.dismissed" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("report.dismissed")
      expect(response.body).not_to include("user.suspended")
    end

    it "hides the viewer from non-admins" do
      delete "/session"
      post "/session", params: { email_address: member.email_address, password: password }
      get "/admin/audit_events"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "1-click revert buttons (O4A)" do
    it "unsuspends from the viewer and records a compensating AuditEvent" do
      member.suspend!(actor: admin)
      event = AuditEvent.find_by!(action: "user.suspended", auditable: member)

      post "/admin/audit_events/#{event.id}/revert"
      expect(response).to redirect_to(admin_audit_events_path)
      expect(member.reload.suspended?).to be(false)
      expect(AuditEvent.where(action: "user.unsuspended", auditable: member).count).to eq(1)
    end

    it "restores an admin soft-deleted user within the SoftDeletable window" do
      member.soft_delete!(actor: admin)
      event = AuditEvent.find_by!(action: "user.soft_deleted", auditable: member)

      post "/admin/audit_events/#{event.id}/revert"
      expect(response).to redirect_to(admin_audit_events_path)
      expect(member.reload.discarded?).to be(false)
      expect(AuditEvent.where(action: "user.restored", auditable: member).count).to eq(1)
    end

    it "reopens a dismissed report to pending" do
      report = Report.submit!(reporter: reporter, reportable: member, reason: "spam")
      report.dismiss!(actor: admin)
      event = AuditEvent.find_by!(action: "report.dismissed", auditable: report)

      post "/admin/audit_events/#{event.id}/revert"
      expect(response).to redirect_to(admin_audit_events_path)
      expect(report.reload.status).to eq("pending")
      expect(AuditEvent.where(action: "report.reopened", auditable: report).count).to eq(1)
    end
  end

  describe "rate_limit on revert writes" do
    it "declares rate_limit covering revert" do
      source = File.read(Rails.root.join("app/controllers/admin/audit_events_controller.rb"))
      expect(source).to match(/rate_limit[\s\S]*revert/)
      expect(source).to include("current_user&.id || request.remote_ip")
    end
  end
end
