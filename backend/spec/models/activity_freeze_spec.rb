# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Activity O2B freeze [REQ-ACT-001]" do
  let(:creator) { create(:user) }
  let(:invitee) { create(:user) }
  let(:activity) do
    Activity.create!(
      creator: creator,
      name: "Intercambio",
      currency: "CRC",
      assignment_mode: "secret_santa",
      visibility_mode: "recipient_only",
      reservation_visibility: "hidden_from_recipient",
      budget_mode: "none",
      starts_on: Date.new(2026, 12, 1),
      ends_on: Date.new(2026, 12, 24)
    )
  end

  describe "money/visibility freeze on first invitee accept [REQ-ACT-001]" do
    it "keeps money settings editable before any invitee accepts [REQ-ACT-001]" do
      expect(activity.money_settings_frozen?).to eq(false)

      activity.update_settings!(
        actor: creator,
        currency: "USD",
        budget_mode: BudgetMode.new("fixed", amount_cents: 3_000),
        visibility_mode: "all_participants",
        reservation_visibility: "visible_to_recipient"
      )

      activity.reload
      expect(activity.currency).to eq("USD")
      expect(activity.budget_mode).to eq("fixed")
      expect(activity.budget_amount_cents).to eq(3_000)
      expect(activity.visibility_mode).to eq("all_participants")
      expect(activity.reservation_visibility).to eq("visible_to_recipient")
    end

    it "freezes currency/budget/visibility after the first invitee accepts [REQ-ACT-001]" do
      participant = ActivityParticipant.invite!(activity: activity, user: invitee, actor: creator)
      participant.accept!

      expect(activity.reload.money_settings_frozen?).to eq(true)
      expect(activity.money_settings_frozen_at).to be_present

      expect {
        activity.update_settings!(
          actor: creator,
          currency: "USD",
          budget_mode: BudgetMode.new("fixed", amount_cents: 1_000),
          visibility_mode: "all_participants",
          reservation_visibility: "visible_to_recipient"
        )
      }.to raise_error(ArgumentError, /frozen|freeze/i)
    end

    it "allows soft name/dates edits after freeze and records an audit notice [REQ-ACT-001]" do
      participant = ActivityParticipant.invite!(activity: activity, user: invitee, actor: creator)
      participant.accept!

      activity.update_soft_fields!(
        actor: creator,
        name: "Intercambio actualizado",
        starts_on: Date.new(2026, 12, 10),
        ends_on: Date.new(2026, 12, 28)
      )

      activity.reload
      expect(activity.name).to eq("Intercambio actualizado")
      expect(activity.starts_on).to eq(Date.new(2026, 12, 10))
      expect(activity.ends_on).to eq(Date.new(2026, 12, 28))
      expect(
        AuditEvent.where(auditable: activity, action: "activity.soft_fields_updated").exists?
      ).to eq(true)
    end
  end
end
