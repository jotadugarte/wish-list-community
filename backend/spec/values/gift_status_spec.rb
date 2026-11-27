# frozen_string_literal: true

require "rails_helper"

RSpec.describe GiftStatus do
  describe "allowed gift lifecycle statuses [REQ-GIFT-001] [REQ-GIFT-002]" do
    %w[purchased_secret delivered_pending_confirmation received_confirmed voided].each do |status|
      it "accepts #{status}" do
        expect(described_class.new(status).value).to eq(status)
      end
    end

    it "rejects reservation/unknown statuses [REQ-GIFT-001]" do
      expect { described_class.new("active") }.to raise_error(ArgumentError)
      expect { described_class.new("nope") }.to raise_error(ArgumentError)
    end

    it "exposes open-gift set for partial unique index [REQ-GIFT-002]" do
      expect(described_class::OPEN).to contain_exactly(
        "purchased_secret",
        "delivered_pending_confirmation"
      )
    end

    it "reports open? for purchased_secret and delivered_pending_confirmation [REQ-GIFT-002]" do
      expect(described_class.new("purchased_secret")).to be_open
      expect(described_class.new("delivered_pending_confirmation")).to be_open
      expect(described_class.new("received_confirmed")).not_to be_open
      expect(described_class.new("voided")).not_to be_open
    end
  end
end
