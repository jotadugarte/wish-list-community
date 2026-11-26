# frozen_string_literal: true

require "rails_helper"

RSpec.describe ItemLink do
  let(:item) { create(:item) }

  describe "ExternalUrl validation [REQ-ITEM-001]" do
    it "persists https purchase links [REQ-ITEM-001]" do
      link = described_class.create!(item: item, url: "https://store.example/p/1", position: 0)

      expect(link.url).to eq("https://store.example/p/1")
      expect(link.url_vo.value).to eq("https://store.example/p/1")
    end

    it "rejects non-http schemes [REQ-ITEM-001]" do
      expect {
        described_class.create!(item: item, url: "javascript:alert(1)", position: 0)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
