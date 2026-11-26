# frozen_string_literal: true

require "rails_helper"

RSpec.describe ItemPriority do
  describe "allowed desire levels [REQ-ITEM-003]" do
    it "accepts low medium high must_have [REQ-ITEM-003]" do
      %w[low medium high must_have].each do |level|
        expect(described_class.new(level).value).to eq(level)
      end
    end

    it "rejects unknown priorities [REQ-ITEM-003]" do
      expect { described_class.new("urgent") }.to raise_error(ArgumentError, /priority/i)
      expect { described_class.new("") }.to raise_error(ArgumentError, /priority/i)
    end

    it "exposes ALLOWED list [REQ-ITEM-003]" do
      expect(described_class::ALLOWED).to contain_exactly("low", "medium", "high", "must_have")
    end

    it "defaults to medium [REQ-ITEM-003]" do
      expect(described_class.default.value).to eq("medium")
    end
  end
end
