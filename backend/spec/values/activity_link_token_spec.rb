# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityLinkToken do
  describe "opaque URL-safe tokens [REQ-ACT-001]" do
    it "generates a URL-safe opaque token [REQ-ACT-001]" do
      token = described_class.generate
      expect(token.value).to match(/\A[A-Za-z0-9\-_]+\z/)
      expect(token.value.length).to be >= 22
    end

    it "rejects blank or unsafe tokens [REQ-ACT-001]" do
      expect { described_class.new("") }.to raise_error(ArgumentError, /activity.?link.?token|share_token/i)
      expect { described_class.new("bad token!") }.to raise_error(ArgumentError)
    end

    it "wraps an existing valid token [REQ-ACT-001]" do
      raw = described_class.generate.value
      expect(described_class.new(raw).value).to eq(raw)
    end
  end
end
