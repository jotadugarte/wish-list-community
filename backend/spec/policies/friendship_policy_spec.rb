# frozen_string_literal: true

require "rails_helper"

RSpec.describe FriendshipPolicy do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:charlie) { create(:user) }

  describe "permissions [REQ-SOC-001] [REQ-BLOCK-001]" do
    it "permits create? only when the requester is the current user and not blocked" do
      candidate = Friendship.new(requester: alice, addressee: bob)
      expect(described_class.new(alice, candidate).create?).to be(true)
      expect(described_class.new(bob, candidate).create?).to be(false)

      UserBlock.block!(blocker: bob, blocked: alice)
      expect(described_class.new(alice, candidate).create?).to be(false)
    end

    it "permits update? (accept) only to the addressee of a pending friendship when not blocked" do
      friendship = Friendship.request!(requester: alice, addressee: bob)

      expect(described_class.new(bob, friendship).update?).to be(true)
      expect(described_class.new(alice, friendship).update?).to be(false)
      expect(described_class.new(charlie, friendship).update?).to be(false)
    end

    it "permits destroy? (decline, cancel, or unfriend) to either participant" do
      friendship = Friendship.request!(requester: alice, addressee: bob)

      expect(described_class.new(alice, friendship).destroy?).to be(true)
      expect(described_class.new(bob, friendship).destroy?).to be(true)
      expect(described_class.new(charlie, friendship).destroy?).to be(false)
    end
  end
end
