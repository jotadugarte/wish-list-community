# frozen_string_literal: true

require "rails_helper"

RSpec.describe GiftRecord do
  let(:owner) { create(:user) }
  let(:gifter) { create(:user) }
  let(:wishlist) { create(:wishlist, owner: owner) }
  let(:item) { create(:item, wishlist: wishlist, title: "Taza") }

  def create_gift!(attrs = {})
    described_class.create!({
      item: item,
      gifter: gifter,
      status: "purchased_secret",
      thank_you_note: nil,
      purchase_link_ref: nil
    }.merge(attrs))
  end

  describe "core fields and statuses [REQ-GIFT-001] [REQ-GIFT-002] [REQ-ADM-001]" do
    it "creates a purchased_secret gift with optional fields [REQ-GIFT-001]" do
      gift = create_gift!(
        thank_you_note: nil,
        purchase_link_ref: "https://store.example/taza"
      )

      expect(gift.status).to eq("purchased_secret")
      expect(gift.status_vo.value).to eq("purchased_secret")
      expect(gift.item_id).to eq(item.id)
      expect(gift.gifter_id).to eq(gifter.id)
      expect(gift.purchase_link_ref).to eq("https://store.example/taza")
      expect(gift.thank_you_note).to be_nil
      expect(described_class.column_names).to include(
        "status", "item_id", "gifter_id", "thank_you_note", "purchase_link_ref"
      )
    end

    it "allows nil gifter for Path 2 free-item receive (FC1) [REQ-GIFT-003]" do
      gift = create_gift!(gifter: nil, status: "received_confirmed")
      expect(gift.gifter_id).to be_nil
      expect(gift.status).to eq("received_confirmed")
    end

    it "validates status via GiftStatus [REQ-GIFT-001]" do
      expect {
        create_gift!(status: "active")
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "does not change items.updated_at when creating a gift [REQ-RES-002]" do
      item.update_columns(updated_at: 2.days.ago)
      before = item.reload.updated_at

      create_gift!

      expect(item.reload.updated_at).to eq(before)
    end

    it "omits gifter_id from owner-facing as_api_json [REQ-GIFT-004] [REQ-RES-002]" do
      gift = create_gift!
      owner_json = gift.as_api_json(viewer: owner)
      gifter_json = gift.as_api_json(viewer: gifter)

      expect(owner_json).not_to have_key(:gifter_id)
      expect(gifter_json[:gifter_id]).to eq(gifter.id)
    end
  end

  describe "partial unique open gift [REQ-GIFT-002]" do
    it "allows only one open gift per item [REQ-GIFT-002]" do
      create_gift!
      other = create(:user)

      expect {
        described_class.create!(
          item: item,
          gifter: other,
          status: "delivered_pending_confirmation"
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows a new open gift after prior was voided [REQ-GIFT-002]" do
      first = create_gift!
      first.update_columns(status: "voided")

      second = described_class.create!(
        item: item,
        gifter: create(:user),
        status: "purchased_secret"
      )
      expect(second).to be_persisted
    end

    it "allows received_confirmed alongside a prior voided row [REQ-ITEM-004]" do
      first = create_gift!
      first.update_columns(status: "voided")

      received = described_class.create!(
        item: item,
        gifter: gifter,
        status: "received_confirmed",
        thank_you_note: "Gracias"
      )
      expect(received).to be_persisted
    end
  end
end
