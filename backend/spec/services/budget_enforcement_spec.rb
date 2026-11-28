# frozen_string_literal: true

require "rails_helper"

RSpec.describe BudgetEnforcement do
  def mode(value, amount: nil, max: nil)
    BudgetMode.new(value, amount_cents: amount, max_cents: max)
  end

  describe ".assert_price! [REQ-ACT-005]" do
    it "allows any or missing price when mode is none [REQ-ACT-005]" do
      expect { described_class.assert_price!(budget_mode: mode("none"), price_cents: nil) }.not_to raise_error
      expect { described_class.assert_price!(budget_mode: mode("none"), price_cents: 9_999_999) }.not_to raise_error
    end

    it "blocks missing price when mode requires an amount [REQ-ACT-005]" do
      %w[fixed min_only max_only].each do |value|
        expect {
          described_class.assert_price!(budget_mode: mode(value, amount: 1000), price_cents: nil)
        }.to raise_error(ArgumentError, /price|budget/i)
      end
      expect {
        described_class.assert_price!(budget_mode: mode("range", amount: 500, max: 1500), price_cents: nil)
      }.to raise_error(ArgumentError, /price|budget/i)
    end

    it "enforces fixed / min_only / max_only / range bounds [REQ-ACT-005]" do
      expect {
        described_class.assert_price!(budget_mode: mode("fixed", amount: 1000), price_cents: 1000)
      }.not_to raise_error
      expect {
        described_class.assert_price!(budget_mode: mode("fixed", amount: 1000), price_cents: 999)
      }.to raise_error(ArgumentError, /fixed|budget/i)

      expect {
        described_class.assert_price!(budget_mode: mode("min_only", amount: 1000), price_cents: 1000)
      }.not_to raise_error
      expect {
        described_class.assert_price!(budget_mode: mode("min_only", amount: 1000), price_cents: 999)
      }.to raise_error(ArgumentError, /min|budget/i)

      expect {
        described_class.assert_price!(budget_mode: mode("max_only", amount: 1000), price_cents: 1000)
      }.not_to raise_error
      expect {
        described_class.assert_price!(budget_mode: mode("max_only", amount: 1000), price_cents: 1001)
      }.to raise_error(ArgumentError, /max|budget/i)

      expect {
        described_class.assert_price!(budget_mode: mode("range", amount: 500, max: 1500), price_cents: 500)
      }.not_to raise_error
      expect {
        described_class.assert_price!(budget_mode: mode("range", amount: 500, max: 1500), price_cents: 1500)
      }.not_to raise_error
      expect {
        described_class.assert_price!(budget_mode: mode("range", amount: 500, max: 1500), price_cents: 499)
      }.to raise_error(ArgumentError, /range|budget/i)
      expect {
        described_class.assert_price!(budget_mode: mode("range", amount: 500, max: 1500), price_cents: 1501)
      }.to raise_error(ArgumentError, /range|budget/i)
    end
  end

  describe ".assert_currency! [REQ-ACT-005]" do
    it "requires item currency to equal activity currency [REQ-ACT-005]" do
      activity = instance_double(Activity, currency: "CRC")
      expect { described_class.assert_currency!(activity: activity, currency: "CRC") }.not_to raise_error
      expect {
        described_class.assert_currency!(activity: activity, currency: "USD")
      }.to raise_error(ArgumentError, /currency/i)
    end
  end
end
