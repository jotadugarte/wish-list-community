# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityWishlistEnsureService do
  let(:creator) { create(:user) }
  let(:invitee) { create(:user) }
  let(:activity) do
    Activity.create!(
      creator: creator,
      name: "Intercambio B",
      currency: "CRC",
      assignment_mode: "secret_santa",
      visibility_mode: "recipient_only",
      reservation_visibility: "hidden_from_recipient",
      budget_mode: "none"
    )
  end

  describe ".ensure_for_participant! [REQ-ARCH-002] [REQ-ACT-001]" do
    it "creates one activity-scoped wishlist for an accepted participant [REQ-ARCH-002] [REQ-ACT-001]" do
      participant = ActivityParticipant.invite!(activity: activity, user: invitee, actor: creator)
      participant.accept!

      wishlist = described_class.ensure_for_participant!(participant: participant.reload)

      expect(wishlist).to be_persisted
      expect(wishlist.activity_id).to eq(activity.id)
      expect(wishlist.owner_id).to eq(invitee.id)
      expect(wishlist.share_token).to be_nil
      expect(wishlist.title).to be_present
      expect(Wishlist.where(activity_id: activity.id, owner_id: invitee.id).kept.count).to eq(1)
    end

    it "is idempotent and does not duplicate [REQ-ARCH-002]" do
      participant = ActivityParticipant.invite!(activity: activity, user: invitee, actor: creator)
      participant.accept!

      first = described_class.ensure_for_participant!(participant: participant)
      second = described_class.ensure_for_participant!(participant: participant)

      expect(second.id).to eq(first.id)
      expect(Wishlist.where(activity_id: activity.id, owner_id: invitee.id).kept.count).to eq(1)
    end

    it "rejects non-accepted participants [REQ-ACT-001]" do
      participant = ActivityParticipant.invite!(activity: activity, user: invitee, actor: creator)

      expect {
        described_class.ensure_for_participant!(participant: participant)
      }.to raise_error(ArgumentError, /accepted/i)
    end
  end

  describe ".backfill_accepted! [REQ-ARCH-002]" do
    it "ensures wishlists for every already-accepted participant [REQ-ARCH-002]" do
      ActivityParticipant.invite!(activity: activity, user: invitee, actor: creator).accept!

      created = described_class.backfill_accepted!(activity: activity)

      expect(created.map(&:owner_id)).to include(creator.id, invitee.id)
      expect(Wishlist.where(activity_id: activity.id, owner_id: creator.id).kept.count).to eq(1)
      expect(Wishlist.where(activity_id: activity.id, owner_id: invitee.id).kept.count).to eq(1)
    end
  end
end
