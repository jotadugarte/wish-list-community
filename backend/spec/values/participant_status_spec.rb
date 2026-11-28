# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParticipantStatus do
  it "accepts invite lifecycle statuses [REQ-ACT-001]" do
    expect(described_class.new("invited").invited?).to eq(true)
    expect(described_class.new("accepted").accepted?).to eq(true)
    expect(described_class.new("declined").declined?).to eq(true)
    expect(described_class.new("left").left?).to eq(true)
  end

  it "rejects unknown statuses [REQ-ACT-001]" do
    expect { described_class.new("maybe") }.to raise_error(ArgumentError)
  end
end
