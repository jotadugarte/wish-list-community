# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReportPolicy do
  let(:owner) { create(:user) }
  let(:friend) { create(:user) }
  let(:stranger) { create(:user) }
  let(:sharee) { create(:user) }

  before do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
    Friendship.request!(requester: owner, addressee: sharee).accept!(actor: sharee)
  end

  def policy_for(viewer, reportable)
    report = Report.new(reporter: viewer, reportable: reportable)
    described_class.new(viewer, report)
  end

  describe "create? for Wishlist [REQ-DISC-001] [REQ-WISH-001] [REQ-BLOCK-001]" do
    it "allows a friend with WishlistPolicy#show? access who is not the owner [REQ-DISC-001]" do
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")
      expect(WishlistPolicy.new(friend, wishlist).show?).to be(true)
      expect(policy_for(friend, wishlist).create?).to be(true)
    end

    it "allows an explicit sharee on a shared wishlist [REQ-DISC-001] [REQ-WISH-001]" do
      wishlist = create(:wishlist, :shared, owner: owner)
      WishlistShare.upsert_explicit!(wishlist: wishlist, user: sharee)
      expect(policy_for(sharee, wishlist).create?).to be(true)
    end

    it "allows a secret_link sharee on a shared wishlist [REQ-DISC-001] [REQ-WISH-001]" do
      wishlist = create(:wishlist, :shared, owner: owner)
      secret_viewer = create(:user)
      WishlistShare.upsert_secret_link!(wishlist: wishlist, user: secret_viewer)
      expect(policy_for(secret_viewer, wishlist).create?).to be(true)
    end

    it "denies the wishlist owner even though they can show the list [REQ-DISC-001]" do
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")
      expect(WishlistPolicy.new(owner, wishlist).show?).to be(true)
      expect(policy_for(owner, wishlist).create?).to be(false)
    end

    it "denies a stranger with no access [REQ-DISC-001] [REQ-WISH-001]" do
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")
      expect(WishlistPolicy.new(stranger, wishlist).show?).to be(false)
      expect(policy_for(stranger, wishlist).create?).to be(false)
    end

    it "denies when a block exists in either direction [REQ-BLOCK-001]" do
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")
      UserBlock.block!(blocker: owner, blocked: friend)
      expect(WishlistPolicy.new(friend, wishlist).show?).to be(false)
      expect(policy_for(friend, wishlist).create?).to be(false)
    end

    it "denies when the wishlist is soft-deleted [REQ-DISC-001]" do
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")
      wishlist.soft_delete!(actor: owner)
      expect(WishlistPolicy.new(friend, wishlist).show?).to be(false)
      expect(policy_for(friend, wishlist).create?).to be(false)
    end
  end

  describe "create? for User (regression) [REQ-SOC-001]" do
    it "allows reporting another user and denies self-report" do
      expect(policy_for(friend, owner).create?).to be(true)
      expect(policy_for(friend, friend).create?).to be(false)
    end
  end
end
