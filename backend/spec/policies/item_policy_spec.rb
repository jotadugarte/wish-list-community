# frozen_string_literal: true

require "rails_helper"

RSpec.describe ItemPolicy do
  let(:owner) { create(:user) }
  let(:friend) { create(:user) }
  let(:stranger) { create(:user) }
  let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }
  let(:item) { create(:item, wishlist: wishlist) }

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
  end

  def policy_for(viewer, record)
    described_class.new(viewer, record)
  end

  describe "show? [REQ-WISH-001] [REQ-BLOCK-001] [REQ-ITEM-001]" do
    it "allows owner and friends-mode friends to show [REQ-WISH-001]" do
      expect(policy_for(owner, item).show?).to be(true)
      expect(policy_for(friend, item).show?).to be(true)
      expect(policy_for(stranger, item).show?).to be(false)
    end

    it "denies when blocked [REQ-BLOCK-001]" do
      UserBlock.block!(blocker: owner, blocked: friend)
      expect(policy_for(friend, item).show?).to be(false)
    end
  end

  describe "mutations [REQ-ITEM-001]" do
    it "allows only the owner to create update destroy [REQ-ITEM-001]" do
      expect(policy_for(owner, item).create?).to be(true)
      expect(policy_for(owner, item).update?).to be(true)
      expect(policy_for(owner, item).destroy?).to be(true)
      expect(policy_for(friend, item).create?).to be(false)
      expect(policy_for(friend, item).update?).to be(false)
      expect(policy_for(friend, item).destroy?).to be(false)
    end

    it "allows only the owner to restore discarded items [REQ-LIFE-001]" do
      item.soft_delete!(actor: owner)
      expect(policy_for(owner, item).restore?).to be(true)
      expect(policy_for(friend, item).restore?).to be(false)
    end
  end
end
