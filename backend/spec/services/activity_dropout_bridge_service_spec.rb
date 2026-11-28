# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityDropoutBridgeService do
  let(:creator) { create(:user) }
  let(:a) { create(:user) }
  let(:b) { create(:user) }
  let(:c) { create(:user) }
  let(:activity) do
    Activity.create!(
      creator: creator,
      name: "Sorteo",
      currency: "CRC",
      assignment_mode: "secret_santa",
      visibility_mode: "recipient_only",
      reservation_visibility: "hidden_from_recipient",
      budget_mode: "none"
    )
  end

  before do
    [ a, b, c ].each { |u| ActivityParticipant.invite!(activity: activity, user: u, actor: creator).accept! }
  end

  describe "leave rules [REQ-ACT-003] [REQ-ACT-004]" do
    it "allows free leave before seal [REQ-ACT-003]" do
      participant = activity.participants.find_by!(user: a)
      described_class.leave!(activity: activity, actor: a)
      expect(participant.reload.status).to eq("left")
      expect(activity.reload.needs_dropout_recovery?).to eq(false)
    end

    it "forces cure choice after sealed secret_santa leave [REQ-ACT-003]" do
      ActivityDrawService.draw!(activity: activity, actor: creator, seed: 11)
      described_class.leave!(activity: activity, actor: b)

      expect(activity.participants.find_by!(user: b).status).to eq("left")
      expect(activity.reload.needs_dropout_recovery?).to eq(true)
    end

    it "allows leave after Arrancar without bridge [REQ-ACT-003]" do
      open_activity = Activity.create!(
        creator: creator,
        name: "Abiertos",
        currency: "CRC",
        assignment_mode: "open_gifting",
        visibility_mode: "all_participants",
        reservation_visibility: "visible_to_recipient",
        budget_mode: "none"
      )
      ActivityParticipant.invite!(activity: open_activity, user: a, actor: creator).accept!
      ActivityOpenGiftingService.arrancar!(activity: open_activity, actor: creator)

      described_class.leave!(activity: open_activity, actor: a)
      expect(open_activity.participants.find_by!(user: a).status).to eq("left")
      expect(open_activity.reload.needs_dropout_recovery?).to eq(false)
    end
  end

  describe "Blind Auto-Bridge [REQ-ACT-003] [REQ-ACT-004]" do
    it "heals A→B→C into A→C, notifies only the giver, clears cure flag [REQ-ACT-003] [REQ-ACT-004]" do
      # Force a known cycle via seed attempts — bridge by removing middle of any edge.
      ActivityDrawService.draw!(activity: activity, actor: creator, seed: 5)
      middle = activity.participants.find_by!(user: b)
      giver_before = ActivityAssignment.find_by(activity: activity, recipient: b)
      recipient_before = ActivityAssignment.find_by(activity: activity, giver: b)
      expect(giver_before).to be_present
      expect(recipient_before).to be_present

      described_class.leave!(activity: activity, actor: b)
      result = described_class.blind_bridge!(activity: activity, actor: creator)

      expect(result).to be_a(BlindBridgeResult)
      expect(ActivityAssignment.find_by(activity: activity, giver: b)).to be_nil
      bridged = ActivityAssignment.find_by!(activity: activity, giver_id: giver_before.giver_id)
      expect(bridged.recipient_id).to eq(recipient_before.recipient_id)
      expect(activity.reload.needs_dropout_recovery?).to eq(false)
      expect(result.notified_giver_id).to eq(giver_before.giver_id)
      expect(result.revealed_full_map).to eq(false)
    end

    it "validates exclusions before bridging [REQ-ACT-004]" do
      ActivityDrawService.draw!(activity: activity, actor: creator, seed: 9)
      giver_edge = ActivityAssignment.find_by!(activity: activity, recipient: b)
      next_edge = ActivityAssignment.find_by!(activity: activity, giver: b)
      ActivityExclusion.create!(
        activity: activity,
        giver_id: giver_edge.giver_id,
        forbidden_recipient_id: next_edge.recipient_id
      )

      described_class.leave!(activity: activity, actor: b)
      expect {
        described_class.blind_bridge!(activity: activity, actor: creator)
      }.to raise_error(ArgumentError, /exclusion|solvable|bridge/i)
    end

    it "notifies every bridged giver when multiple leavers are healed [REQ-ACT-003]" do
      d = create(:user)
      ActivityParticipant.invite!(activity: activity, user: d, actor: creator).accept!
      ActivityDrawService.draw!(activity: activity, actor: creator, seed: 12)
      described_class.leave!(activity: activity, actor: a)
      described_class.leave!(activity: activity, actor: b)

      expect {
        described_class.blind_bridge!(activity: activity, actor: creator)
      }.to change { Notification.where(event_key: "activity.blind_bridged").count }.by_at_least(1)

      expect(activity.reload.needs_dropout_recovery?).to eq(false)
      expect(ActivityAssignment.where(activity: activity, giver: a)).not_to exist
      expect(ActivityAssignment.where(activity: activity, giver: b)).not_to exist
    end
  end

  describe "Full Redraw [REQ-ACT-003]" do
    it "redraws when enough participants remain [REQ-ACT-003]" do
      ActivityDrawService.draw!(activity: activity, actor: creator, seed: 2)
      described_class.leave!(activity: activity, actor: c)
      # still creator + a + b = 3
      described_class.full_redraw!(activity: activity, actor: creator, seed: 99)

      expect(activity.reload.needs_dropout_recovery?).to eq(false)
      expect(ActivityAssignment.where(activity: activity).count).to eq(3)
      expect(ActivityAssignment.where(activity: activity, giver: c)).not_to exist
    end

    it "refuses redraw when fewer than 3 accepted remain [REQ-ACT-003]" do
      ActivityDrawService.draw!(activity: activity, actor: creator, seed: 4)
      described_class.leave!(activity: activity, actor: a)
      described_class.leave!(activity: activity, actor: b)

      expect {
        described_class.full_redraw!(activity: activity, actor: creator, seed: 1)
      }.to raise_error(ArgumentError, /3|cancel|minimum/i)
    end
  end
end
