# frozen_string_literal: true

require "rails_helper"

RSpec.describe BudgetMode do
  describe "allowed modes [REQ-ACT-005]" do
    it "accepts the five budget modes [REQ-ACT-005]" do
      %w[none fixed min_only max_only range].each do |mode|
        expect(described_class.new(mode, amount_cents: mode == "none" ? nil : 5_000, max_cents: mode == "range" ? 10_000 : nil).value).to eq(mode)
      end
    end

    it "rejects unknown modes [REQ-ACT-005]" do
      expect { described_class.new("unlimited") }.to raise_error(ArgumentError, /budget_mode/i)
    end

    it "requires amount_cents for fixed/min_only/max_only [REQ-ACT-005]" do
      expect { described_class.new("fixed") }.to raise_error(ArgumentError, /amount_cents/i)
      expect { described_class.new("min_only") }.to raise_error(ArgumentError, /amount_cents/i)
      expect { described_class.new("max_only") }.to raise_error(ArgumentError, /amount_cents/i)
    end

    it "requires amount_cents and max_cents for range with amount <= max [REQ-ACT-005]" do
      expect { described_class.new("range", amount_cents: 5_000) }.to raise_error(ArgumentError, /max_cents/i)
      expect { described_class.new("range", amount_cents: 10_000, max_cents: 5_000) }.to raise_error(ArgumentError, /range/i)
      vo = described_class.new("range", amount_cents: 5_000, max_cents: 10_000)
      expect(vo.amount_cents).to eq(5_000)
      expect(vo.max_cents).to eq(10_000)
    end

    it "allows none without amounts [REQ-ACT-005]" do
      vo = described_class.new("none")
      expect(vo).to be_none
      expect(vo.amount_cents).to be_nil
      expect(vo.max_cents).to be_nil
    end
  end
end
