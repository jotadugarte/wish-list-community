# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Moderation revert helpers [REQ-ADM-001]" do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin) { create(:user, role: "admin", username: "revert_admin", email_address: "revert_admin@example.com") }
  let(:member) { create(:user, username: "revert_member", email_address: "revert_member@example.com") }

  after { travel_back }

  describe "User#unsuspend! compensating AuditEvent (O4A)" do
    it "clears suspension with a new AuditEvent and never mutates old rows" do
      member.suspend!(actor: admin)
      original = AuditEvent.find_by!(action: "user.suspended", auditable: member)
      original_attrs = original.attributes.except("updated_at")

      expect(member.unsuspend!(actor: admin)).to be(true)
      expect(member.reload.suspended?).to be(false)
      expect(AuditEvent.find(original.id).attributes.except("updated_at")).to eq(original_attrs)
      expect(AuditEvent.where(action: "user.unsuspended", auditable: member).count).to eq(1)
    end
  end

  describe "restore admin soft-deleted user/wishlist within window (O4A/FC3)" do
    it "restores a soft-deleted user within 30 days with a new AuditEvent" do
      member.soft_delete!(actor: admin)
      original = AuditEvent.find_by!(action: "user.soft_deleted", auditable: member)

      expect(member.restore!(actor: admin)).to be(true)
      expect(member.reload.discarded?).to be(false)
      expect(AuditEvent.find(original.id).action).to eq("user.soft_deleted")
      expect(AuditEvent.where(action: "user.restored", auditable: member).count).to eq(1)
    end

    it "restores a soft-deleted wishlist within 30 days with a new AuditEvent" do
      wishlist = create(:wishlist, owner: member)
      wishlist.soft_delete!(actor: admin)
      original = AuditEvent.find_by!(action: "wishlist.soft_deleted", auditable: wishlist)

      expect(wishlist.restore!(actor: admin)).to be(true)
      expect(wishlist.reload.discarded?).to be(false)
      expect(AuditEvent.find(original.id).action).to eq("wishlist.soft_deleted")
      expect(AuditEvent.where(action: "wishlist.restored", auditable: wishlist).count).to eq(1)
    end

    it "denies restore after the 30-day SoftDeletable window" do
      freeze_time
      member.soft_delete!(actor: admin)
      travel 31.days
      expect(member.restore!(actor: admin)).to be(false)
      expect(member.reload.discarded?).to be(true)
    end
  end

  describe "Report#reopen! dismissed → pending (FC1 KEEP)" do
    let(:reporter) { create(:user, username: "reopen_reporter", email_address: "reopen_reporter@example.com") }
    let!(:report) { Report.submit!(reporter: reporter, reportable: member, reason: "spam") }

    it "reopens a dismissed report to pending with a new AuditEvent and does not mutate old rows" do
      report.dismiss!(actor: admin)
      dismissed_event = AuditEvent.find_by!(action: "report.dismissed", auditable: report)
      dismissed_attrs = dismissed_event.attributes.except("updated_at")

      expect(report.reopen!(actor: admin)).to be(true)
      expect(report.reload.status).to eq("pending")
      expect(AuditEvent.find(dismissed_event.id).attributes.except("updated_at")).to eq(dismissed_attrs)
      expect(AuditEvent.where(action: "report.reopened", auditable: report).count).to eq(1)
    end

    it "respects the unique pending index when another pending report already exists" do
      report.dismiss!(actor: admin)
      other_reporter = create(:user, username: "other_rep", email_address: "other_rep@example.com")
      Report.submit!(reporter: other_reporter, reportable: member, reason: "harassment")

      # Same reporter cannot have two pending — reopen after another pending from same reporter blocked:
      Report.submit!(reporter: reporter, reportable: member, reason: "scam")
      expect do
        report.reopen!(actor: admin)
      end.to raise_error(ActiveRecord::RecordInvalid)
      expect(report.reload.status).to eq("dismissed")
    end
  end

  describe "member cannot restore admin soft-delete (O4A)" do
    it "blocks member restore of an admin soft-deleted user" do
      member.soft_delete!(actor: admin)
      expect(member.restore!(actor: member)).to be(false)
      expect(member.errors[:base].join).to match(/admin/i)
      expect(member.reload.discarded?).to be(true)
    end

    it "blocks member restore of an admin soft-deleted wishlist" do
      wishlist = create(:wishlist, owner: member)
      wishlist.soft_delete!(actor: admin)
      expect(wishlist.restore!(actor: member)).to be(false)
      expect(wishlist.errors[:base].join).to match(/admin/i)
      expect(wishlist.reload.discarded?).to be(true)
    end

    it "still allows member restore of a self soft-delete" do
      member.soft_delete!(actor: member)
      expect(member.restore!(actor: member)).to be(true)
      expect(member.reload.discarded?).to be(false)
    end
  end
end
