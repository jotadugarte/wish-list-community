# frozen_string_literal: true

require "rails_helper"

RSpec.describe Username do
  describe ".new [REQ-USER-001]" do
    it "normalizes a valid username to lowercase [REQ-USER-001]" do
      handle = described_class.new("  Nata_Pinilla99 ")
      expect(handle.value).to eq("nata_pinilla99")
    end

    it "rejects usernames shorter than 3 or longer than 30 characters [REQ-USER-001]" do
      expect { described_class.new("ab") }.to raise_error(ArgumentError, /length/i)
      expect { described_class.new("a" * 31) }.to raise_error(ArgumentError, /length/i)
    end

    it "rejects usernames with special characters or spaces [REQ-USER-001]" do
      expect { described_class.new("nata.pinilla") }.to raise_error(ArgumentError, /format/i)
      expect { described_class.new("nata-pinilla") }.to raise_error(ArgumentError, /format/i)
      expect { described_class.new("nata pinilla") }.to raise_error(ArgumentError, /format/i)
    end

    it "rejects system reserved words [REQ-USER-001]" do
      %w[admin api login logout signup wishlists settings support].each do |reserved|
        expect { described_class.new(reserved) }.to raise_error(ArgumentError, /reserved/i)
      end
    end
  end
end
