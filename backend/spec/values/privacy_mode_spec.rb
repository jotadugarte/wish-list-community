# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrivacyMode do
  describe "allowed modes [REQ-WISH-001]" do
    it "accepts friends and shared [REQ-WISH-001]" do
      expect(described_class.new("friends").value).to eq("friends")
      expect(described_class.new("shared").value).to eq("shared")
      expect(described_class.new("friends")).to be_friends
      expect(described_class.new("shared")).to be_shared
    end

    it "rejects unknown modes [REQ-WISH-001]" do
      expect { described_class.new("public") }.to raise_error(ArgumentError, /privacy_mode/i)
      expect { described_class.new("") }.to raise_error(ArgumentError, /privacy_mode/i)
    end

    it "normalizes case and whitespace [REQ-WISH-001]" do
      expect(described_class.new(" Friends ").value).to eq("friends")
    end
  end
end
