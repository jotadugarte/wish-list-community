# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservation do
  let(:owner) { create(:user) }
  let(:reserver) { create(:user, time_zone: "America/Costa_Rica") }
  let(:wishlist) { create(:wishlist, owner: owner) }
  let(:item) { create(:item, wishlist: wishlist, title: "Libro") }

  def create_reservation!(attrs = {})
    described_class.create!({
      item: item,
      user: reserver,
      status: "active",
      estimated_date: Date.current + 7,
      private_note: "para junio"
    }.merge(attrs))
  end

  describe "core fields and statuses [REQ-RES-001] [REQ-RES-002] [REQ-USER-003]" do
    it "creates an active reservation with private note and estimated_date [REQ-RES-001]" do
      reservation = create_reservation!

      expect(reservation.status).to eq("active")
      expect(reservation.status_vo.value).to eq("active")
      expect(reservation.private_note).to eq("para junio")
      expect(reservation.estimated_date).to eq(Date.current + 7)
      expect(reservation.user_id).to eq(reserver.id)
      expect(reservation.item_id).to eq(item.id)
      expect(described_class.column_names).to include(
        "status", "estimated_date", "private_note", "grace_expires_at", "user_id", "item_id"
      )
    end

    it "validates status via ReservationStatus [REQ-RES-001]" do
      expect {
        create_reservation!(status: "purchased_secret")
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "does not change items.updated_at when creating a reservation [REQ-RES-002]" do
      item.update_columns(updated_at: 2.days.ago)
      before = item.reload.updated_at

      create_reservation!

      expect(item.reload.updated_at).to eq(before)
    end
  end

  describe "partial unique active hold [REQ-RES-001]" do
    it "allows only one active/grace reservation per item [REQ-RES-001]" do
      create_reservation!
      other = create(:user)

      expect {
        described_class.create!(
          item: item,
          user: other,
          status: "active",
          estimated_date: Date.current + 3
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows a new active reservation after prior was canceled [REQ-RES-001]" do
      first = create_reservation!
      first.update_columns(status: "canceled")

      second = described_class.create!(
        item: item,
        user: create(:user),
        status: "active",
        estimated_date: Date.current + 5
      )
      expect(second).to be_persisted
    end
  end

  describe "ownership invariant [REQ-RES-001]" do
    it "rejects the wishlist owner as reserver [REQ-RES-001]" do
      expect {
        described_class.create!(
          item: item,
          user: owner,
          status: "active",
          estimated_date: Date.current + 2
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "estimated_date vs event_date warning helper [REQ-WISH-004]" do
    it "reports warn_event_date_exceeded? when estimated_date > wishlist.event_date" do
      wishlist.update!(event_date: Date.current + 3)
      reservation = create_reservation!(estimated_date: Date.current + 10)
      expect(reservation.warn_event_date_exceeded?).to be(true)
    end
  end
end
