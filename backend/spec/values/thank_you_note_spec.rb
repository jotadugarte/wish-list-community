# frozen_string_literal: true

require "rails_helper"

RSpec.describe ThankYouNote do
  describe "optional anonymous thank-you text [REQ-GIFT-004]" do
    it "accepts a non-blank note and freezes the value" do
      note = described_class.new("¡Gracias!")
      expect(note.value).to eq("¡Gracias!")
      expect(note.value).to be_frozen
    end

    it "rejects blank notes [REQ-GIFT-004]" do
      expect { described_class.new("") }.to raise_error(ArgumentError)
      expect { described_class.new("   ") }.to raise_error(ArgumentError)
    end

    it "rejects notes longer than 500 characters [REQ-GIFT-004]" do
      expect { described_class.new("x" * 501) }.to raise_error(ArgumentError)
    end
  end
end
