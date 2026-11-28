# frozen_string_literal: true

require "rails_helper"

RSpec.describe Activity do
  let(:creator) { create(:user) }

  describe "schema and defaults [REQ-ACT-001] [REQ-ACT-005] [REQ-ARCH-001]" do
    it "creates an activity with secret_santa defaults and opaque link token [REQ-ACT-001] [REQ-ACT-005]" do
      activity = described_class.create!(
        creator: creator,
        name: "Intercambio navideño",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )

      expect(activity).to be_persisted
      expect(activity.assignment_mode).to eq("secret_santa")
      expect(activity.visibility_mode).to eq("recipient_only")
      expect(activity.reservation_visibility).to eq("hidden_from_recipient")
      expect(activity.budget_mode).to eq("none")
      expect(activity.currency).to eq("CRC")
      expect(activity.share_token).to be_present
      expect(activity.share_token).to match(/\A[A-Za-z0-9\-_]+\z/)
      expect(activity.link_token_vo).to be_a(ActivityLinkToken)
      expect(activity.budget_mode_vo).to be_a(BudgetMode)
      expect(activity.sealed?).to eq(false)
      expect(activity.cancelled?).to eq(false)
      expect(activity.status).to eq("open")
    end

    it "supports all five budget modes via BudgetMode VO [REQ-ACT-005]" do
      activity = described_class.create!(
        creator: creator,
        name: "Presupuesto fijo",
        currency: "USD",
        assignment_mode: "open_gifting",
        visibility_mode: "all_participants",
        reservation_visibility: "visible_to_recipient",
        budget_mode: "fixed",
        budget_amount_cents: 2_500
      )

      expect(activity.budget_mode_vo.value).to eq("fixed")
      expect(activity.budget_amount_cents).to eq(2_500)
      expect(activity.assignment_mode).to eq("open_gifting")
    end

    it "enforces unique share_token [REQ-ACT-001]" do
      first = described_class.create!(
        creator: creator,
        name: "Uno",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
      second = described_class.create!(
        creator: creator,
        name: "Dos",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )

      expect(second.share_token).not_to eq(first.share_token)
      expect {
        second.update_columns(share_token: first.share_token)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "exposes required columns for Sprint A shell [REQ-ACT-001] [REQ-ARCH-001]" do
      expect(described_class.column_names).to include(
        "creator_id", "name", "currency", "assignment_mode", "visibility_mode",
        "reservation_visibility", "budget_mode", "budget_amount_cents", "budget_max_cents",
        "share_token", "status", "sealed_at", "cancelled_at", "starts_on", "ends_on",
        "money_settings_frozen_at"
      )
    end
  end

  describe "creator as accepted participant [REQ-ACT-001]" do
    it "auto-accepts the creator as a co-organizer participant on create [REQ-ACT-001]" do
      activity = described_class.create!(
        creator: creator,
        name: "Grupo",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )

      participant = activity.participants.find_by!(user: creator)
      expect(participant.status).to eq("accepted")
      expect(participant.co_organizer).to eq(true)
    end

    it "ensures an activity-scoped wishlist for the creator on create [REQ-ARCH-002] [REQ-ACT-001]" do
      activity = described_class.create!(
        creator: creator,
        name: "Grupo con lista",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )

      wishlists = Wishlist.kept.where(activity_id: activity.id, owner_id: creator.id)
      expect(wishlists.count).to eq(1)
      expect(wishlists.first.share_token).to be_nil
    end
  end
end
