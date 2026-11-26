# frozen_string_literal: true

require "rails_helper"

RSpec.describe Item do
  let(:wishlist) { create(:wishlist) }

  describe "core fields and readiness [REQ-ITEM-001] [REQ-ITEM-003] [REQ-ITEM-005] [REQ-ARCH-002]" do
    it "creates one giftable unit with default priority medium and append position [REQ-ITEM-003] [REQ-ITEM-005]" do
      item = described_class.create!(wishlist: wishlist, title: "Auriculares")

      expect(item.title).to eq("Auriculares")
      expect(item.priority).to eq("medium")
      expect(item.priority_vo.value).to eq("medium")
      expect(item.position).to eq(0)
      expect(item.price_cents).to be_nil
      expect(item.currency).to be_nil
      expect(described_class.column_names).to include("price_cents", "currency", "specifications", "position")
    end

    it "stores specifications and validates priority via ItemPriority [REQ-ITEM-001] [REQ-ITEM-003]" do
      item = described_class.create!(
        wishlist: wishlist,
        title: "Camisa",
        specifications: "Talla M, color navy",
        priority: "must_have"
      )

      expect(item.specifications).to eq("Talla M, color navy")
      expect(item.priority_vo.value).to eq("must_have")
      expect { described_class.create!(wishlist: wishlist, title: "X", priority: "urgent") }
        .to raise_error(ActiveRecord::RecordInvalid)
    end

    it "requires price_cents and currency together [REQ-ARCH-002]" do
      expect {
        described_class.create!(wishlist: wishlist, title: "Libro", price_cents: 1500, currency: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect {
        described_class.create!(wishlist: wishlist, title: "Libro", price_cents: nil, currency: "USD")
      }.to raise_error(ActiveRecord::RecordInvalid)

      item = described_class.create!(wishlist: wishlist, title: "Libro", price_cents: 1500, currency: "USD")
      expect(item.currency).to eq("USD")
      expect(item.price_cents).to eq(1500)
    end

    it "appends position after existing items [REQ-ITEM-001]" do
      first = described_class.create!(wishlist: wishlist, title: "Uno")
      second = described_class.create!(wishlist: wishlist, title: "Dos")

      expect(first.position).to eq(0)
      expect(second.position).to eq(1)
    end
  end

  describe "ItemLink association [REQ-ITEM-001]" do
    it "accepts multiple http(s) purchase links [REQ-ITEM-001]" do
      item = described_class.create!(wishlist: wishlist, title: "Gadget")
      item.item_links.create!(url: "https://www.amazon.com/dp/ABC", position: 0)
      item.item_links.create!(url: "https://www.mercadolibre.com.mx/x", position: 1)

      expect(item.item_links.count).to eq(2)
      expect(item.item_links.first.url_vo).to be_a(ExternalUrl)
    end
  end

  describe "images attachment [REQ-ITEM-002]" do
    it "allows up to 3 attached images [REQ-ITEM-002]" do
      item = described_class.create!(wishlist: wishlist, title: "Con fotos")
      expect(item).to respond_to(:images)
      expect(item.images).to be_an(ActiveStorage::Attached::Many)
    end
  end

  describe "SoftDeletable [REQ-LIFE-001]" do
    it "soft-deletes and restores within grace [REQ-LIFE-001]" do
      item = described_class.create!(wishlist: wishlist, title: "Temporal")
      item.soft_delete!(actor: wishlist.owner)

      expect(item).to be_discarded
      expect(described_class.kept.where(id: item.id)).not_to exist
      expect(item.restore!(actor: wishlist.owner)).to eq(true)
      expect(item.reload).not_to be_discarded
    end
  end
end
