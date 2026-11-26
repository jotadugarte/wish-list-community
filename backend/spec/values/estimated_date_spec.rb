# frozen_string_literal: true

require "rails_helper"

RSpec.describe EstimatedDate do
  describe "calendar date in reserver time zone [REQ-RES-001] [REQ-USER-003]" do
    it "parses a valid ISO date" do
      vo = described_class.new("2030-06-15", time_zone: "America/Costa_Rica")
      expect(vo.value).to eq(Date.new(2030, 6, 15))
    end

    it "rejects blank and invalid dates" do
      expect { described_class.new("", time_zone: "UTC") }.to raise_error(ArgumentError)
      expect { described_class.new("not-a-date", time_zone: "UTC") }.to raise_error(ArgumentError)
    end

    it "requires date >= today in the given time zone on assert_not_past! [REQ-RES-001]" do
      zone = ActiveSupport::TimeZone["America/Bogota"]
      today = zone.today
      ok = described_class.new(today.iso8601, time_zone: "America/Bogota")
      expect { ok.assert_not_past! }.not_to raise_error

      past = described_class.new((today - 1).iso8601, time_zone: "America/Bogota")
      expect { past.assert_not_past! }.to raise_error(ArgumentError)
    end
  end
end
