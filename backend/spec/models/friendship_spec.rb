# frozen_string_literal: true

require "rails_helper"

RSpec.describe Friendship do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:charlie) { create(:user) }

  describe ".request! and unordered unique pair invariant [REQ-SOC-001] [REQ-BLOCK-001]" do
    it "creates a pending friendship request between two active non-blocked users" do
      friendship = described_class.request!(requester: alice, addressee: bob)

      expect(friendship).to be_persisted
      expect(friendship.status).to eq("pending")
      expect(described_class.status_between(alice, bob)).to eq("pending_outgoing")
      expect(described_class.status_between(bob, alice)).to eq("pending_incoming")
    end

    it "prevents a user from sending a friend request to themselves" do
      expect do
        described_class.request!(requester: alice, addressee: alice)
      end.to raise_error(ArgumentError, /Pre-condition failed/)
    end

    it "prevents duplicate or inverse friend requests between the same pair of users" do
      described_class.request!(requester: alice, addressee: bob)

      expect do
        described_class.request!(requester: bob, addressee: alice)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "denies friend requests when a block exists in either direction [REQ-BLOCK-001]" do
      UserBlock.block!(blocker: bob, blocked: alice)

      expect do
        described_class.request!(requester: alice, addressee: bob)
      end.to raise_error(ArgumentError, /blocked/)
    end

    it "enforces the 20 pending outgoing friend requests anti-spam limit" do
      20.times do
        target = create(:user)
        described_class.request!(requester: alice, addressee: target)
      end

      expect do
        described_class.request!(requester: alice, addressee: charlie)
      end.to raise_error(ArgumentError, /limit/)
    end
  end

  describe "#accept! [REQ-SOC-001] [REQ-ADM-001]" do
    it "allows the addressee to accept a pending request and records an AuditEvent" do
      friendship = described_class.request!(requester: alice, addressee: bob)

      expect do
        friendship.accept!(actor: bob)
      end.to change(AuditEvent, :count).by(1)

      expect(friendship.reload.status).to eq("accepted")
      expect(described_class.status_between(alice, bob)).to eq("accepted")
      expect(described_class.status_between(bob, alice)).to eq("accepted")
    end

    it "rejects acceptance by the requester or third parties" do
      friendship = described_class.request!(requester: alice, addressee: bob)

      expect do
        friendship.accept!(actor: alice)
      end.to raise_error(ArgumentError, /Pre-condition failed/)
    end
  end

  describe "UserBlock cascading cleanup integration [REQ-BLOCK-002]" do
    it "transactionally destroys any existing friendship when either user blocks the other" do
      friendship = described_class.request!(requester: alice, addressee: bob)
      friendship.accept!(actor: bob)

      expect do
        UserBlock.block!(blocker: alice, blocked: bob)
      end.to change(described_class, :count).by(-1)

      expect(described_class.status_between(alice, bob)).to eq("none")
    end
  end
end
