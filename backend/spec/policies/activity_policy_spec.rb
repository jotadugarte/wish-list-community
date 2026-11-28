# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityPolicy do
  subject(:policy) { described_class.new(viewer, activity) }

  let(:creator) { create(:user) }
  let(:viewer) { create(:user) }
  let(:activity) do
    Activity.create!(
      creator: creator,
      name: "Grupo",
      currency: "CRC",
      assignment_mode: "secret_santa",
      visibility_mode: "recipient_only",
      reservation_visibility: "hidden_from_recipient",
      budget_mode: "none"
    )
  end

  describe "show? / board access [REQ-BLOCK-001] [REQ-ACT-001]" do
    it "allows creator and accepted participants [REQ-ACT-001]" do
      expect(described_class.new(creator, activity).show?).to eq(true)

      invitee = create(:user)
      ActivityParticipant.invite!(activity: activity, user: invitee, actor: creator).accept!
      expect(described_class.new(invitee, activity).show?).to eq(true)
    end

    it "denies strangers and blocked users [REQ-BLOCK-001]" do
      expect(policy.show?).to eq(false)

      UserBlock.block!(blocker: creator, blocked: viewer)
      expect(described_class.new(viewer, activity).show?).to eq(false)
      expect(described_class.new(viewer, activity).join?).to eq(false)
    end
  end

  describe "Block Wins mid sealed secret_santa [REQ-BLOCK-001] [REQ-ACT-003]" do
    it "removes affected participants and requires dropout cure [REQ-BLOCK-001] [REQ-ACT-003]" do
      a = create(:user)
      b = create(:user)
      c = create(:user)
      [a, b, c].each { |u| ActivityParticipant.invite!(activity: activity, user: u, actor: creator).accept! }

      activity.update!(status: "sealed", sealed_at: Time.current, assignment_mode: "secret_santa")

      UserBlock.block!(blocker: a, blocked: b)

      expect(activity.participants.find_by(user: a).status).to eq("left")
      expect(activity.participants.find_by(user: b).status).to eq("left")
      expect(activity.reload.needs_dropout_recovery?).to eq(true)
    end

    it "removes affected participants without bridge requirement for open_gifting [REQ-BLOCK-001]" do
      open_activity = Activity.create!(
        creator: creator,
        name: "Abiertos",
        currency: "CRC",
        assignment_mode: "open_gifting",
        visibility_mode: "all_participants",
        reservation_visibility: "visible_to_recipient",
        budget_mode: "none"
      )
      a = create(:user)
      b = create(:user)
      [a, b].each { |u| ActivityParticipant.invite!(activity: open_activity, user: u, actor: creator).accept! }
      open_activity.update!(status: "sealed", sealed_at: Time.current)

      UserBlock.block!(blocker: a, blocked: b)

      expect(open_activity.participants.find_by(user: a).status).to eq("left")
      expect(open_activity.participants.find_by(user: b).status).to eq("left")
      expect(open_activity.reload.needs_dropout_recovery?).to eq(false)
    end
  end
end
