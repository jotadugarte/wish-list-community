# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReportReason do
  describe "#initialize [REQ-SOC-001] [REQ-DISC-001]" do
    it "normalizes and accepts all allowed report reasons" do
      %w[spam harassment impersonation inappropriate_content scam].each do |raw_reason|
        vo = described_class.new("  #{raw_reason.upcase}  ")
        expect(vo.value).to eq(raw_reason)
        expect(vo.to_s).to eq(raw_reason)
      end
    end

    it "rejects unknown or empty report reasons" do
      expect { described_class.new("") }.to raise_error(ArgumentError, /Invalid report reason/)
      expect { described_class.new("other_random") }.to raise_error(ArgumentError, /Invalid report reason/)
    end

    it "supports value equality" do
      expect(described_class.new("SPAM")).to eq(described_class.new("spam"))
    end
  end
end
