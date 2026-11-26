# frozen_string_literal: true

require "rails_helper"

RSpec.describe WishlistShare do
  let(:owner) { create(:user) }
  let(:friend) { create(:user) }
  let(:stranger) { create(:user) }

  before do
    friendship = Friendship.request!(requester: owner, addressee: friend)
    friendship.accept!(actor: friend)
  end

  describe "invariants [REQ-WISH-003]" do
    it "enforces unique (wishlist_id, user_id) and rejects owner self-share [REQ-WISH-003]" do
      wishlist = create(:wishlist, :shared, owner: owner)
      described_class.upsert_explicit!(wishlist: wishlist, user: friend)

      expect do
        described_class.create!(wishlist: wishlist, user: friend, source: "explicit")
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect do
        described_class.create!(wishlist: wishlist, user: owner, source: "explicit")
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "upserts secret_link shares for logged-in viewers [REQ-WISH-003]" do
      wishlist = create(:wishlist, :shared, owner: owner)
      share = described_class.upsert_secret_link!(wishlist: wishlist, user: stranger)

      expect(share.source).to eq("secret_link")
      expect(described_class.upsert_secret_link!(wishlist: wishlist, user: stranger).id).to eq(share.id)
    end
  end

  describe "UserBlock cleanup [REQ-BLOCK-002]" do
    it "deletes shares between the pair when either user blocks the other [REQ-BLOCK-002]" do
      wishlist = create(:wishlist, :shared, owner: owner)
      described_class.upsert_explicit!(wishlist: wishlist, user: friend)
      expect(described_class.where(wishlist: wishlist, user: friend)).to exist

      UserBlock.block!(blocker: owner, blocked: friend)

      expect(described_class.where(wishlist: wishlist, user: friend)).not_to exist
    end
  end

  describe "friendship remove cleanup [REQ-BLOCK-002]" do
    it "deletes shares between the pair when friendship is removed [REQ-BLOCK-002]" do
      wishlist = create(:wishlist, :shared, owner: owner)
      described_class.upsert_explicit!(wishlist: wishlist, user: friend)
      friendship = Friendship.between_users(owner, friend).first

      friendship.remove!(actor: owner)

      expect(described_class.where(wishlist: wishlist, user: friend)).not_to exist
    end
  end
end
