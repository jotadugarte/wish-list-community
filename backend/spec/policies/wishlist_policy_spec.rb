# frozen_string_literal: true

require "rails_helper"

RSpec.describe WishlistPolicy do
  let(:owner) { create(:user) }
  let(:friend) { create(:user) }
  let(:stranger) { create(:user) }
  let(:sharee) { create(:user) }

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
    Friendship.request!(requester: owner, addressee: sharee).accept!(actor: sharee)
  end

  def policy_for(viewer, wishlist)
    described_class.new(viewer, wishlist)
  end

  describe "show? 4-actor matrix [REQ-WISH-001] [REQ-BLOCK-001]" do
    it "allows the owner to show their wishlist [REQ-WISH-001]" do
      wishlist = create(:wishlist, owner: owner)
      expect(policy_for(owner, wishlist).show?).to be(true)
    end

    it "allows accepted friends to show friends-mode wishlists [REQ-WISH-001]" do
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")
      expect(policy_for(friend, wishlist).show?).to be(true)
      expect(policy_for(stranger, wishlist).show?).to be(false)
    end

    it "denies friends without explicit share on shared-mode wishlists [REQ-WISH-001]" do
      wishlist = create(:wishlist, :shared, owner: owner)
      expect(policy_for(friend, wishlist).show?).to be(false)
    end

    it "allows explicit sharees and secret_link sharees on shared wishlists [REQ-WISH-001]" do
      wishlist = create(:wishlist, :shared, owner: owner)
      WishlistShare.upsert_explicit!(wishlist: wishlist, user: sharee)
      secret_viewer = create(:user)
      WishlistShare.upsert_secret_link!(wishlist: wishlist, user: secret_viewer)

      expect(policy_for(sharee, wishlist).show?).to be(true)
      expect(policy_for(secret_viewer, wishlist).show?).to be(true)
    end

    it "denies access when a block exists in either direction [REQ-BLOCK-001]" do
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")
      UserBlock.block!(blocker: owner, blocked: friend)
      expect(policy_for(friend, wishlist).show?).to be(false)
    end
  end

  describe "owner mutations [REQ-WISH-001]" do
    it "permits update?/destroy?/restore?/rotate?/manage_shares? only for the owner" do
      wishlist = create(:wishlist, :shared, owner: owner)
      expect(policy_for(owner, wishlist).update?).to be(true)
      expect(policy_for(owner, wishlist).destroy?).to be(true)
      expect(policy_for(owner, wishlist).restore?).to be(true)
      expect(policy_for(owner, wishlist).rotate_share_token?).to be(true)
      expect(policy_for(owner, wishlist).manage_shares?).to be(true)
      expect(policy_for(friend, wishlist).update?).to be(false)
      expect(policy_for(friend, wishlist).manage_shares?).to be(false)
    end
  end

  describe "Scope [REQ-WISH-001] [REQ-BLOCK-001]" do
    it "scopes accessible wishlists for a viewer excluding blocked and strangers [REQ-WISH-001]" do
      friends_list = create(:wishlist, owner: owner, privacy_mode: "friends", title: "Friends")
      shared_list = create(:wishlist, :shared, owner: owner, title: "Shared")
      WishlistShare.upsert_explicit!(wishlist: shared_list, user: sharee)
      create(:wishlist, owner: owner, privacy_mode: "friends", title: "Hidden")

      friend_scope = described_class::Scope.new(friend, Wishlist.kept).resolve
      expect(friend_scope).to include(friends_list)
      expect(friend_scope).not_to include(shared_list)

      sharee_scope = described_class::Scope.new(sharee, Wishlist.kept).resolve
      expect(sharee_scope).to include(friends_list, shared_list)

      stranger_scope = described_class::Scope.new(stranger, Wishlist.kept).resolve
      expect(stranger_scope).to be_empty
    end
  end
end
