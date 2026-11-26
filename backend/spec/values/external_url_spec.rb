# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExternalUrl do
  describe "http/https validation [REQ-ITEM-001]" do
    it "accepts https URLs [REQ-ITEM-001]" do
      vo = described_class.new("https://www.amazon.com/dp/B00TEST")
      expect(vo.value).to eq("https://www.amazon.com/dp/B00TEST")
    end

    it "accepts http URLs [REQ-ITEM-001]" do
      vo = described_class.new("http://example.com/item")
      expect(vo.value).to eq("http://example.com/item")
    end

    it "rejects blank values [REQ-ITEM-001]" do
      expect { described_class.new("  ") }.to raise_error(ArgumentError, /url/i)
    end

    it "rejects javascript and data schemes [REQ-ITEM-001]" do
      expect { described_class.new("javascript:alert(1)") }.to raise_error(ArgumentError, /url/i)
      expect { described_class.new("data:text/html,hi") }.to raise_error(ArgumentError, /url/i)
      expect { described_class.new("file:///etc/passwd") }.to raise_error(ArgumentError, /url/i)
    end

    it "rejects URLs without a host [REQ-ITEM-001]" do
      expect { described_class.new("https:///no-host") }.to raise_error(ArgumentError, /url/i)
    end
  end
end
