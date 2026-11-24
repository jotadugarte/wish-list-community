# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailAddress do
  describe ".new [REQ-USER-001]" do
    it "normalizes email by stripping whitespace and downcasing [REQ-USER-001]" do
      email = described_class.new("  Ceci.Pinilla@Example.COM  ")
      expect(email.value).to eq("ceci.pinilla@example.com")
    end

    it "rejects blank or malformed email addresses [REQ-USER-001]" do
      expect { described_class.new("") }.to raise_error(ArgumentError, /invalid email/i)
      expect { described_class.new("not-an-email") }.to raise_error(ArgumentError, /invalid email/i)
    end

    it "redacts the raw email in inspect/to_s to prevent accidental logging leaks [REQ-USER-001]" do
      email = described_class.new("secret@example.com")
      expect(email.to_s).to eq("[REDACTED_EMAIL]")
      expect(email.inspect).not_to include("secret@example.com")
    end
  end
end
