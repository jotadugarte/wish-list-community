# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShareToken do
  describe ".generate and validation [REQ-WISH-002] [REQ-WISH-006]" do
    it "generates a URL-safe opaque token [REQ-WISH-002] [REQ-WISH-006]" do
      token = described_class.generate

      expect(token.value).to match(/\A[A-Za-z0-9\-_]+\z/)
      expect(token.value.length).to be >= 22
    end

    it "rejects blank or unsafe raw tokens [REQ-WISH-006]" do
      expect { described_class.new("   ") }.to raise_error(ArgumentError, /share_token/i)
      expect { described_class.new("bad/token") }.to raise_error(ArgumentError, /share_token/i)
      expect { described_class.new("//evil") }.to raise_error(ArgumentError, /share_token/i)
    end

    it "wraps an existing valid URL-safe token [REQ-WISH-006]" do
      raw = described_class.generate.value
      expect(described_class.new(raw).value).to eq(raw)
    end
  end
end
