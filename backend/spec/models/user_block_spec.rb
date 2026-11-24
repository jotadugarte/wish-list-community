# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserBlock, type: :model do
  let(:alice) do
    User.create!(
      email_address: "alice@example.com",
      username: "alice_user",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      locale: "es",
      time_zone: "UTC",
      terms_accepted_at: Time.current
    )
  end

  let(:bob) do
    User.create!(
      email_address: "bob@example.com",
      username: "bob_user",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      locale: "es",
      time_zone: "UTC",
      terms_accepted_at: Time.current
    )
  end

  describe ".block!, .blocked_between?, and cascading hooks [REQ-BLOCK-001] [REQ-BLOCK-002] [REQ-ADM-001]" do
    it "prevents a user from blocking themselves [REQ-BLOCK-001]" do
      expect {
        described_class.block!(blocker: alice, blocked: alice)
      }.to raise_error(ActiveRecord::RecordInvalid, /cannot block yourself/i)
    end

    it "detects a block in either direction via .blocked_between? and logs an AuditEvent [REQ-BLOCK-001] [REQ-ADM-001]" do
      expect(described_class.blocked_between?(alice, bob)).to be(false)

      block = described_class.block!(blocker: alice, blocked: bob)
      expect(block).to be_persisted
      expect(described_class.blocked_between?(alice, bob)).to be(true)
      expect(described_class.blocked_between?(bob, alice)).to be(true)

      audit = AuditEvent.find_by(action: "user.blocked", auditable: block)
      expect(audit).to be_present
      expect(audit.actor).to eq(alice)
    end

    it "executes registered cascading cleanup hooks inside the block transaction [REQ-BLOCK-002]" do
      hook_called_with = nil
      hook = ->(blocker, blocked) { hook_called_with = [ blocker.id, blocked.id ] }

      described_class.register_cleanup_hook(:test_sprint1_hook, &hook)
      described_class.block!(blocker: alice, blocked: bob)

      expect(hook_called_with).to eq([ alice.id, bob.id ])
    ensure
      described_class.unregister_cleanup_hook(:test_sprint1_hook)
    end
  end
end
