# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReservationPolicy do
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

  describe "create? [REQ-RES-001] [REQ-WISH-002] [REQ-BLOCK-001]" do
    it "allows an accepted friend with wishlist access to reserve [REQ-RES-001]" do
      reservation = Reservation.new(item: item, user: friend, status: "active", estimated_date: Date.current + 3)
      expect(policy_for(friend, reservation).create?).to be(true)
    end

    it "denies the wishlist owner [REQ-RES-001]" do
      reservation = Reservation.new(item: item, user: owner, status: "active", estimated_date: Date.current + 3)
      expect(policy_for(owner, reservation).create?).to be(false)
    end

    it "denies strangers without access [REQ-WISH-001]" do
      reservation = Reservation.new(item: item, user: stranger, status: "active", estimated_date: Date.current + 3)
      expect(policy_for(stranger, reservation).create?).to be(false)
    end

    it "denies when blocked [REQ-BLOCK-001]" do
      UserBlock.block!(blocker: owner, blocked: friend)
      reservation = Reservation.new(item: item, user: friend, status: "active", estimated_date: Date.current + 3)
      expect(policy_for(friend, reservation).create?).to be(false)
    end
  end

  describe "update?/destroy? for reserver [REQ-RES-001]" do
    let!(:reservation) do
      Reservation.create!(item: item, user: friend, status: "active", estimated_date: Date.current + 5)
    end

    it "allows only the reserver to extend or cancel [REQ-RES-001]" do
      expect(policy_for(friend, reservation).update?).to be(true)
      expect(policy_for(friend, reservation).destroy?).to be(true)
      expect(policy_for(owner, reservation).update?).to be(false)
      expect(policy_for(stranger, reservation).destroy?).to be(false)
    end
  end

  describe "Scope [REQ-RES-004]" do
    it "returns only the current user's active/grace reservations" do
      mine = Reservation.create!(item: item, user: friend, status: "active", estimated_date: Date.current + 2)
      other_item = create(:item, wishlist: wishlist, title: "Other")
      Reservation.create!(item: other_item, user: create(:user).tap { |u|
        Friendship.request!(requester: owner, addressee: u).accept!(actor: u)
      }, status: "active", estimated_date: Date.current + 2)

      resolved = described_class::Scope.new(friend, Reservation).resolve
      expect(resolved).to contain_exactly(mine)
    end
  end
end
