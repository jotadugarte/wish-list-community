# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityParticipant do
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
      budget_mode: "none"
    )
  end

  describe "invite / accept / decline / leave [REQ-ACT-001]" do
    it "invites a user as pending [REQ-ACT-001]" do
      participant = described_class.invite!(activity: activity, user: invitee, actor: creator)

      expect(participant.status).to eq("invited")
      expect(participant.co_organizer).to eq(false)
      expect(participant.user).to eq(invitee)
    end

    it "accepts an invitation [REQ-ACT-001]" do
      participant = described_class.invite!(activity: activity, user: invitee, actor: creator)
      participant.accept!

      expect(participant.reload.status).to eq("accepted")
    end

    it "declines an invitation [REQ-ACT-001]" do
      participant = described_class.invite!(activity: activity, user: invitee, actor: creator)
      participant.decline!

      expect(participant.reload.status).to eq("declined")
    end

    it "allows leave while unsealed [REQ-ACT-001]" do
      participant = described_class.invite!(activity: activity, user: invitee, actor: creator)
      participant.accept!
      participant.leave!

      expect(participant.reload.status).to eq("left")
    end

    it "enforces unique (activity_id, user_id) [REQ-ACT-001]" do
      described_class.invite!(activity: activity, user: invitee, actor: creator)

      duplicate = described_class.new(activity: activity, user: invitee, status: "invited")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "supports co_organizer flag [REQ-ACT-001]" do
      participant = described_class.invite!(activity: activity, user: invitee, actor: creator)
      participant.accept!
      participant.update!(co_organizer: true)

      expect(participant.reload.co_organizer).to eq(true)
    end

    it "re-invites a declined participant [REQ-ACT-001]" do
      participant = described_class.invite!(activity: activity, user: invitee, actor: creator)
      participant.decline!
      revived = described_class.invite!(activity: activity, user: invitee, actor: creator)

      expect(revived.id).to eq(participant.id)
      expect(revived.reload.status).to eq("invited")
    end
  end
end
