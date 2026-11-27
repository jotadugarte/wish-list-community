# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseLinkRef do
  describe "optional admin purchase link reference [REQ-ADM-001]" do
    it "accepts an http(s) URL via ExternalUrl rules [REQ-ADM-001]" do
      ref = described_class.new("https://store.example/item/1")
      expect(ref.value).to eq("https://store.example/item/1")
    end

    it "accepts a plain ItemLink-style opaque ref string [REQ-ADM-001]" do
      ref = described_class.new("item_link:42")
      expect(ref.value).to eq("item_link:42")
    end

    it "rejects blank refs [REQ-ADM-001]" do
      expect { described_class.new("") }.to raise_error(ArgumentError)
      expect { described_class.new("   ") }.to raise_error(ArgumentError)
    end
  end
end
