# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentMode do
  it "accepts secret_santa and open_gifting [REQ-ACT-001]" do
    expect(described_class.new("secret_santa").secret_santa?).to eq(true)
    expect(described_class.new("open_gifting").open_gifting?).to eq(true)
  end

  it "rejects unknown modes [REQ-ACT-001]" do
    expect { described_class.new("cooperacha") }.to raise_error(ArgumentError)
  end
end
