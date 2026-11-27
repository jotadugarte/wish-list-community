# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, "Suspend domain [REQ-ADM-001]" do
  let(:admin) { create(:user, role: "admin", username: "admin_one", email_address: "admin_one@example.com") }
  let(:member) { create(:user, username: "member_one", email_address: "member_one@example.com") }

  describe "#suspend! / #unsuspend! / #suspended?" do
    it "sets suspended_at, records user.suspended AuditEvent, and revokes sessions + api_tokens + device_tokens [REQ-ADM-001]" do
      _token, raw = ApiToken.issue_for!(member, fcm_token: "fcm_suspend_1")
      member.sessions.create!(ip_address: "127.0.0.1")

      expect do
        expect(member.suspend!(actor: admin)).to be(true)
      end.to change(AuditEvent, :count).by(1)

      member.reload
      expect(member.suspended?).to be(true)
      expect(member.suspended_at).to be_present
      expect(member.discarded?).to be(false)
      expect(Session.where(user: member).count).to eq(0)
      expect(DeviceToken.where(user: member).count).to eq(0)
      expect(ApiToken.authenticate(raw)).to be_nil

      event = AuditEvent.order(:id).last
      expect(event.action).to eq("user.suspended")
      expect(event.actor_id).to eq(admin.id)
      expect(event.auditable).to eq(member)
    end

    it "clears suspended_at and records user.unsuspended AuditEvent [REQ-ADM-001]" do
      member.suspend!(actor: admin)

      expect do
        expect(member.unsuspend!(actor: admin)).to be(true)
      end.to change(AuditEvent, :count).by(1)

      member.reload
      expect(member.suspended?).to be(false)
      expect(member.suspended_at).to be_nil

      event = AuditEvent.order(:id).last
      expect(event.action).to eq("user.unsuspended")
      expect(event.actor_id).to eq(admin.id)
      expect(event.auditable).to eq(member)
    end

    it "rejects self-suspend [REQ-ADM-001]" do
      expect do
        admin.suspend!(actor: admin)
      end.to raise_error(ArgumentError, /Pre-condition failed/)
      expect(admin.reload.suspended?).to be(false)
    end

    it "rejects suspending the last remaining admin [REQ-ADM-001]" do
      sole_admin = admin
      actor = create(:user, role: "user", username: "ops_actor", email_address: "ops_actor@example.com")
      expect(User.kept.where(role: "admin").where(suspended_at: nil).count).to eq(1)

      expect do
        sole_admin.suspend!(actor: actor)
      end.to raise_error(ArgumentError, /Pre-condition failed|last.*admin/i)

      expect(sole_admin.reload.suspended?).to be(false)
    end

    it "allows suspending an admin when another unsuspended admin remains [REQ-ADM-001]" do
      second_admin = create(:user, role: "admin", username: "admin_two", email_address: "admin_two@example.com")
      expect(admin.suspend!(actor: second_admin)).to be(true)
      expect(admin.reload.suspended?).to be(true)
    end

    it "keeps the suspended user SoftDeletable kept (content not hidden) [REQ-ADM-001]" do
      member.suspend!(actor: admin)
      expect(member.reload.discarded?).to be(false)
      expect(User.kept).to include(member)
    end
  end
end
