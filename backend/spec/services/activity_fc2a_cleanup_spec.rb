# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FC2A activity cleanup [REQ-BLOCK-001] [REQ-ACT-003] [REQ-LIFE-001]" do
  let(:creator) { create(:user) }
  let(:leaver) { create(:user) }
  let(:peer) { create(:user) }

  def sealed_open!
    activity = Activity.create!(
      creator: creator,
      name: "FC2A",
      currency: "CRC",
      assignment_mode: "open_gifting",
      visibility_mode: "all_participants",
      reservation_visibility: "hidden_from_recipient",
      budget_mode: "none"
    )
    [ leaver, peer ].each do |user|
      ActivityParticipant.invite!(activity: activity, user: user, actor: creator).accept!
    end
    ActivityOpenGiftingService.arrancar!(activity: activity, actor: creator)
    activity
  end

  def wishlist(activity, user)
    Wishlist.find_by!(activity_id: activity.id, owner_id: user.id)
  end

  describe "leave! cleanup [REQ-ACT-003] FC2A" do
    it "cancels leaver holds, voids leaver open gifts, soft-deletes leaver wishlist [REQ-ACT-003] [REQ-LIFE-001]" do
      activity = sealed_open!
      peer_item = create(:item, wishlist: wishlist(activity, peer), title: "Peer gift")
      leaver_item = create(:item, wishlist: wishlist(activity, leaver), title: "Mine")
      other_hold_item = create(:item, wishlist: wishlist(activity, peer), title: "Other")

      hold = ReservationService.create!(
        item: peer_item, user: leaver, estimated_date: Date.current + 3
      )
      gift = GiftService.mark_purchased!(reservation: hold, actor: leaver)
      peer_hold = ReservationService.create!(
        item: leaver_item, user: peer, estimated_date: Date.current + 4
      )
      untouched = ReservationService.create!(
        item: other_hold_item, user: creator, estimated_date: Date.current + 5
      )

      ActivityDropoutBridgeService.leave!(activity: activity, actor: leaver)

      expect(activity.participants.find_by!(user: leaver).status).to eq("left")
      expect(hold.reload.status).to eq("canceled").or eq("completed_by_gift")
      # purchased gift must be voided (open gift cleanup)
      expect(gift.reload.status).to eq("voided")
      expect(wishlist(activity, leaver).discarded?).to eq(true)
      expect(peer_hold.reload.status).to eq("canceled")
      expect(untouched.reload.status).to eq("active")
      expect(wishlist(activity, peer).discarded?).to eq(false)
    end
  end

  describe "cancel! cleanup [REQ-ACT-003] [REQ-LIFE-001] FC2A" do
    it "soft-deletes all activity wishlists and clears open holds/gifts [REQ-ACT-003]" do
      activity = sealed_open!
      item = create(:item, wishlist: wishlist(activity, peer), title: "X")
      hold = ReservationService.create!(
        item: item, user: leaver, estimated_date: Date.current + 2
      )

      ActivityAdminService.cancel!(activity: activity, actor: creator)

      expect(activity.reload.cancelled?).to eq(true)
      expect(Wishlist.where(activity_id: activity.id).kept.count).to eq(0)
      expect(hold.reload.status).to eq("canceled")
    end
  end

  describe "Block Wins inherits force_leave! cleanup [REQ-BLOCK-001] FC2A" do
    it "archives activity wishlist and cancels activity holds when blocked [REQ-BLOCK-001]" do
      activity = sealed_open!
      item = create(:item, wishlist: wishlist(activity, peer), title: "Block gift")
      hold = ReservationService.create!(
        item: item, user: leaver, estimated_date: Date.current + 2
      )

      UserBlock.block!(blocker: peer, blocked: leaver)

      expect(activity.participants.find_by!(user: leaver).status).to eq("left")
      expect(wishlist(activity, leaver).discarded?).to eq(true)
      expect(hold.reload.status).to eq("canceled")
    end
  end
end
