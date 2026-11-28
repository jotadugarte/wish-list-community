# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityStatus do
  it "accepts open sealed cancelled [REQ-ACT-001]" do
    expect(described_class.new("open").open?).to eq(true)
    expect(described_class.new("sealed").sealed?).to eq(true)
    expect(described_class.new("cancelled").cancelled?).to eq(true)
  end

  it "rejects unknown statuses [REQ-ACT-001]" do
    expect { described_class.new("draft") }.to raise_error(ArgumentError)
  end
end
