# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthToken do
  describe ".generate and .digest [REQ-AUTH-001]" do
    it "generates a high-entropy raw token and matching SHA-256 hex digest [REQ-AUTH-001]" do
      token = described_class.generate

      expect(token.raw.length).to be >= 32
      expect(token.digest).to eq(Digest::SHA256.hexdigest(token.raw))
      expect(token.digest).not_to eq(token.raw)
    end

    it "computes a deterministic SHA-256 digest from an existing raw token [REQ-AUTH-001]" do
      token = described_class.from_raw("sample_raw_token_1234567890")
      expect(token.digest).to eq(Digest::SHA256.hexdigest("sample_raw_token_1234567890"))
    end

    it "rejects blank raw tokens [REQ-AUTH-001]" do
      expect { described_class.from_raw("   ") }.to raise_error(ArgumentError, /blank/i)
    end

    it "redacts the raw token in to_s and inspect [REQ-AUTH-001]" do
      token = described_class.generate
      expect(token.to_s).to eq("[REDACTED_AUTH_TOKEN]")
      expect(token.inspect).not_to include(token.raw)
    end
  end
end
