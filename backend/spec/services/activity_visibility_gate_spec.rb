# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityVisibilityGate do
  let(:creator) { create(:user) }
  let(:giver) { create(:user) }
  let(:recipient) { create(:user) }
  let(:outsider) { create(:user) }

  def build_activity!(mode:, visibility:)
    Activity.create!(
      creator: creator,
      name: "Visibilidad #{mode}",
      currency: "CRC",
      assignment_mode: mode,
      visibility_mode: visibility,
      reservation_visibility: "hidden_from_recipient",
      budget_mode: "none"
    )
  end

  def accept!(activity, user)
    ActivityParticipant.invite!(activity: activity, user: user, actor: creator).accept!
  end

  def wishlist_for(activity, user)
    Wishlist.find_by!(activity_id: activity.id, owner_id: user.id)
  end

  def seal_secret_santa!(activity)
    ActivityAssignment.create!(activity: activity, giver: giver, recipient: recipient)
    ActivityAssignment.create!(activity: activity, giver: recipient, recipient: creator)
    ActivityAssignment.create!(activity: activity, giver: creator, recipient: giver)
    activity.update!(status: "sealed", sealed_at: Time.current)
  end

  def seal_open!(activity)
    activity.update!(status: "sealed", sealed_at: Time.current)
  end

  describe ".can_view_list? [REQ-ACT-001] O3A" do
    context "secret_santa recipient_only" do
      let(:activity) { build_activity!(mode: "secret_santa", visibility: "recipient_only") }

      before do
        accept!(activity, giver)
        accept!(activity, recipient)
        seal_secret_santa!(activity)
      end

      it "lets the owner always view their own list [REQ-ACT-001]" do
        list = wishlist_for(activity, recipient)
        expect(described_class.can_view_list?(viewer: recipient, owner_wishlist: list)).to eq(true)
      end

      it "lets only the assigned giver view the recipient list [REQ-ACT-001]" do
        list = wishlist_for(activity, recipient)
        expect(described_class.can_view_list?(viewer: giver, owner_wishlist: list)).to eq(true)
        expect(described_class.can_view_list?(viewer: creator, owner_wishlist: list)).to eq(false)
      end

      it "rejects outsiders and non-participants [REQ-ACT-001]" do
        list = wishlist_for(activity, recipient)
        expect(described_class.can_view_list?(viewer: outsider, owner_wishlist: list)).to eq(false)
      end
    end

    context "secret_santa all_participants" do
      let(:activity) { build_activity!(mode: "secret_santa", visibility: "all_participants") }

      before do
        accept!(activity, giver)
        accept!(activity, recipient)
        seal_secret_santa!(activity)
      end

      it "lets any accepted participant view another participant list [REQ-ACT-001]" do
        list = wishlist_for(activity, recipient)
        expect(described_class.can_view_list?(viewer: giver, owner_wishlist: list)).to eq(true)
        expect(described_class.can_view_list?(viewer: creator, owner_wishlist: list)).to eq(true)
      end
    end

    context "open_gifting" do
      let(:activity) { build_activity!(mode: "open_gifting", visibility: "all_participants") }

      before do
        accept!(activity, giver)
        accept!(activity, recipient)
        seal_open!(activity)
      end

      it "lets accepted participants view other lists [REQ-ACT-001]" do
        list = wishlist_for(activity, recipient)
        expect(described_class.can_view_list?(viewer: giver, owner_wishlist: list)).to eq(true)
        expect(described_class.can_view_list?(viewer: outsider, owner_wishlist: list)).to eq(false)
      end

      it "honors recipient_only when set for open_gifting [REQ-ACT-001]" do
        activity.update!(visibility_mode: "recipient_only")
        list = wishlist_for(activity, recipient)
        # open_gifting has no assignments — recipient_only still allows accepted peers
        # only when assignment_mode would assign; without assignments treat as all accepted peers
        # Spec lock: open_gifting + recipient_only → accepted participants may view (no draw).
        expect(described_class.can_view_list?(viewer: giver, owner_wishlist: list)).to eq(true)
      end
    end

    it "returns false when users are blocked (Block Wins) [REQ-ACT-001] [REQ-BLOCK-001]" do
      activity = build_activity!(mode: "open_gifting", visibility: "all_participants")
      accept!(activity, giver)
      accept!(activity, recipient)
      seal_open!(activity)
      list = wishlist_for(activity, recipient)
      UserBlock.block!(blocker: recipient, blocked: giver)

      expect(described_class.can_view_list?(viewer: giver, owner_wishlist: list)).to eq(false)
    end
  end

  describe ".can_reserve? [REQ-ACT-001] O3A" do
    let(:activity) { build_activity!(mode: "secret_santa", visibility: "recipient_only") }
    let(:item) { create(:item, wishlist: wishlist_for(activity, recipient), title: "Café") }

    before do
      accept!(activity, giver)
      accept!(activity, recipient)
    end

    it "forbids reserves before seal even when the viewer is the assigned giver [REQ-ACT-001]" do
      ActivityAssignment.create!(activity: activity, giver: giver, recipient: recipient)
      expect(described_class.can_reserve?(viewer: giver, item: item)).to eq(false)
    end

    it "allows the assigned giver to reserve after seal [REQ-ACT-001]" do
      seal_secret_santa!(activity)
      expect(described_class.can_reserve?(viewer: giver, item: item)).to eq(true)
    end

    it "never allows reserving on own list [REQ-ACT-001]" do
      seal_secret_santa!(activity)
      own_item = create(:item, wishlist: wishlist_for(activity, giver), title: "Own")
      expect(described_class.can_reserve?(viewer: giver, item: own_item)).to eq(false)
    end

    it "requires the viewer to be an accepted participant [REQ-ACT-001]" do
      seal_secret_santa!(activity)
      expect(described_class.can_reserve?(viewer: outsider, item: item)).to eq(false)
    end
  end

  describe "pre-seal item add documentation [REQ-ACT-001] O3A" do
    it "does not gate owner writes — owner may add items before seal [REQ-ACT-001]" do
      activity = build_activity!(mode: "secret_santa", visibility: "recipient_only")
      accept!(activity, giver)
      list = wishlist_for(activity, giver)
      expect(activity.sealed?).to eq(false)
      expect {
        create(:item, wishlist: list, title: "Pre-seal gift", price_cents: nil, currency: nil)
      }.not_to raise_error
    end
  end
end
