# frozen_string_literal: true

require "rails_helper"

RSpec.describe GiftService, "#mark_purchased! [REQ-GIFT-001] [REQ-GIFT-002] [REQ-RES-006]" do
  let(:owner) { create(:user) }
  let(:reserver) { create(:user, time_zone: "America/Costa_Rica") }
  let(:other) { create(:user) }
  let(:wishlist) { create(:wishlist, owner: owner) }
  let(:item) { create(:item, wishlist: wishlist, title: "Libro") }

  def hold!(status: "active", user: reserver)
    Reservation.create!(
      item: item,
      user: user,
      status: status,
      estimated_date: Date.current + 5,
      grace_expires_at: (status == "expired_grace" ? 2.days.from_now : nil)
    )
  end

  it "creates purchased_secret GiftRecord and completes the hold from active [REQ-GIFT-001] [REQ-RES-006]" do
    reservation = hold!(status: "active")
    item.update_columns(updated_at: 2.days.ago)
    before = item.reload.updated_at

    gift = described_class.mark_purchased!(
      reservation: reservation,
      actor: reserver,
      purchase_link_ref: "https://store.example/libro"
    )

    expect(gift).to be_persisted
    expect(gift.status).to eq("purchased_secret")
    expect(gift.gifter_id).to eq(reserver.id)
    expect(gift.item_id).to eq(item.id)
    expect(gift.purchase_link_ref).to eq("https://store.example/libro")
    expect(reservation.reload.status).to eq("completed_by_gift")
    expect(reservation.grace_expires_at).to be_nil
    expect(item.reload.updated_at).to eq(before)
    expect(AuditEvent.where(action: "gift.mark_purchased", auditable: gift).count).to eq(1)
  end

  it "allows mark purchased from expired_grace (O6A) [REQ-GIFT-001]" do
    reservation = hold!(status: "expired_grace")
    gift = described_class.mark_purchased!(reservation: reservation, actor: reserver)
    expect(gift.status).to eq("purchased_secret")
    expect(reservation.reload.status).to eq("completed_by_gift")
  end

  it "rejects non-reserver actors and auto_released holds [REQ-GIFT-002]" do
    reservation = hold!(status: "active")
    expect {
      described_class.mark_purchased!(reservation: reservation, actor: other)
    }.to raise_error(GiftService::Error)

    reservation.update_columns(status: "auto_released", grace_expires_at: nil)
    expect {
      described_class.mark_purchased!(reservation: reservation.reload, actor: reserver)
    }.to raise_error(GiftService::Error)
  end

  it "rejects when an open gift already exists for the item [REQ-GIFT-002]" do
    reservation = hold!(status: "active")
    GiftRecord.create!(item: item, gifter: other, status: "purchased_secret")

    expect {
      described_class.mark_purchased!(reservation: reservation, actor: reserver)
    }.to raise_error(GiftService::ConflictError)
  end

  it "allows blank purchase_link_ref (O4A) [REQ-ADM-001]" do
    reservation = hold!
    gift = described_class.mark_purchased!(reservation: reservation, actor: reserver, purchase_link_ref: nil)
    expect(gift.purchase_link_ref).to be_nil
  end
end
