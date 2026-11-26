# frozen_string_literal: true

require "rails_helper"

RSpec.describe Wishlist do
  include ActiveSupport::Testing::TimeHelpers

  after { travel_back }

  let(:owner) { create(:user) }

  describe "defaults and schema readiness [REQ-WISH-001] [REQ-WISH-004] [REQ-ARCH-002]" do
    it "defaults privacy_mode to friends with nil share_token [REQ-WISH-001]" do
      wishlist = described_class.create!(owner: owner, title: "Cumpleaños")

      expect(wishlist.privacy_mode).to eq("friends")
      expect(wishlist.share_token).to be_nil
      expect(wishlist.privacy_mode_vo).to be_friends
    end

    it "supports optional event_date and nullable readiness columns [REQ-WISH-004] [REQ-ARCH-002]" do
      wishlist = described_class.create!(
        owner: owner,
        title: "Navidad",
        event_date: Date.new(2026, 12, 25),
        activity_id: nil,
        max_reservations_per_user: nil
      )

      expect(wishlist.event_date).to eq(Date.new(2026, 12, 25))
      expect(wishlist.activity_id).to be_nil
      expect(wishlist.max_reservations_per_user).to be_nil
      expect(described_class.column_names).to include("activity_id", "max_reservations_per_user", "event_date")
    end
  end

  describe "privacy mode transitions and ShareToken [REQ-WISH-001] [REQ-WISH-002] [REQ-WISH-006]" do
    it "mints a unique URL-safe share_token when switching to shared [REQ-WISH-002] [REQ-WISH-006]" do
      wishlist = described_class.create!(owner: owner, title: "Lista")
      other = described_class.create!(owner: owner, title: "Otra")

      wishlist.switch_privacy_mode!(PrivacyMode.new("shared"))
      other.switch_privacy_mode!(PrivacyMode.new("shared"))

      expect(wishlist.reload.share_token).to be_present
      expect(wishlist.share_token).to match(/\A[A-Za-z0-9\-_]+\z/)
      expect(wishlist.share_token_vo).to be_a(ShareToken)
      expect(other.reload.share_token).not_to eq(wishlist.share_token)
      expect(wishlist.privacy_mode).to eq("shared")
    end

    it "wipes share_token when switching shared to friends [REQ-WISH-002]" do
      wishlist = described_class.create!(owner: owner, title: "Lista")
      wishlist.switch_privacy_mode!(PrivacyMode.new("shared"))
      expect(wishlist.reload.share_token).to be_present

      wishlist.switch_privacy_mode!(PrivacyMode.new("friends"))

      expect(wishlist.reload.privacy_mode).to eq("friends")
      expect(wishlist.share_token).to be_nil
    end
  end

  describe "SoftDeletable lifecycle [REQ-LIFE-001]" do
    it "soft-deletes and restores within the grace window [REQ-LIFE-001]" do
      freeze_time
      wishlist = described_class.create!(owner: owner, title: "Temporal")

      expect(wishlist.soft_delete!(actor: owner)).to be(true)
      expect(wishlist).to be_discarded
      expect(described_class.kept.where(id: wishlist.id)).to be_empty

      travel 10.days
      expect(wishlist.restore!(actor: owner)).to be(true)
      expect(wishlist).not_to be_discarded
      expect(described_class.kept.find(wishlist.id)).to eq(wishlist)
    end
  end
end
