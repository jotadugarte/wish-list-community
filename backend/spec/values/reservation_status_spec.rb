# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReservationStatus do
  describe "allowed S5 statuses [REQ-RES-001] [REQ-RES-006]" do
    %w[active expired_grace auto_released canceled].each do |status|
      it "accepts #{status}" do
        expect(described_class.new(status).value).to eq(status)
      end
    end

    it "rejects gift/unknown statuses in S5 constructor [REQ-RES-001]" do
      expect { described_class.new("purchased_secret") }.to raise_error(ArgumentError)
      expect { described_class.new("nope") }.to raise_error(ArgumentError)
    end

    it "exposes active-hold set for partial unique index [REQ-RES-001]" do
      expect(described_class::ACTIVE_HOLD).to contain_exactly("active", "expired_grace")
    end
  end
end
