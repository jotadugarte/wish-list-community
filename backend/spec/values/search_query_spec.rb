# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchQuery do
  describe "#initialize [REQ-SOC-001]" do
    it "normalizes a valid query by stripping whitespace, leading @, and downcasing" do
      query = described_class.new("  @Nata_24  ")
      expect(query.value).to eq("nata_24")
      expect(query.to_s).to eq("nata_24")
      expect(query.prefix_pattern).to eq("nata\\_24%")
    end

    it "rejects queries shorter than 2 characters" do
      expect { described_class.new("a") }.to raise_error(ArgumentError, /between 2 and 30/)
      expect { described_class.new("@a") }.to raise_error(ArgumentError, /between 2 and 30/)
    end

    it "rejects queries longer than 30 characters" do
      expect { described_class.new("a" * 31) }.to raise_error(ArgumentError, /between 2 and 30/)
    end

    it "rejects queries with invalid characters" do
      expect { described_class.new("nata%drop") }.to raise_error(ArgumentError, /format/)
      expect { described_class.new("nata space") }.to raise_error(ArgumentError, /format/)
    end

    it "supports value equality" do
      expect(described_class.new("@Nata")).to eq(described_class.new("nata"))
    end
  end
end
