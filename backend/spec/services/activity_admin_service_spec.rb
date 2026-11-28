# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityAdminService do
  let(:creator) { create(:user) }
  let(:co_org_user) { create(:user) }
  let(:invitee) { create(:user) }
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

  before do
    ActivityParticipant.invite!(activity: activity, user: co_org_user, actor: creator).accept!
    ActivityParticipant.invite!(activity: activity, user: invitee, actor: creator).accept!
  end

  describe "co-organizer appoint/remove [REQ-ACT-001]" do
    it "allows only the creator to appoint and remove co-organizers [REQ-ACT-001]" do
      described_class.appoint_co_organizer!(activity: activity, actor: creator, user: co_org_user)
      expect(activity.participants.find_by!(user: co_org_user).co_organizer).to eq(true)

      expect {
        described_class.appoint_co_organizer!(activity: activity, actor: co_org_user, user: invitee)
      }.to raise_error(ArgumentError, /creator/i)

      described_class.remove_co_organizer!(activity: activity, actor: creator, user: co_org_user)
      expect(activity.participants.find_by!(user: co_org_user).co_organizer).to eq(false)
    end
  end

  describe "equal admin powers for co-org [REQ-ACT-001]" do
    it "lets co-organizers invite like the creator [REQ-ACT-001]" do
      described_class.appoint_co_organizer!(activity: activity, actor: creator, user: co_org_user)
      new_user = create(:user)

      participant = described_class.invite!(activity: activity, actor: co_org_user, user: new_user)
      expect(participant.status).to eq("invited")
    end
  end

  describe "ownership transfer and cancel [REQ-ACT-001] [REQ-ACT-003]" do
    it "transfers ownership to a co-org then lets the former creator leave [REQ-ACT-001]" do
      described_class.appoint_co_organizer!(activity: activity, actor: creator, user: co_org_user)
      described_class.transfer_ownership!(activity: activity, actor: creator, new_creator: co_org_user)

      expect(activity.reload.creator_id).to eq(co_org_user.id)
      former = activity.participants.find_by!(user: creator)
      former.leave!
      expect(former.reload.status).to eq("left")
    end

    it "cancels the whole activity [REQ-ACT-001]" do
      described_class.cancel!(activity: activity, actor: creator)
      expect(activity.reload.cancelled?).to eq(true)
      expect(activity.status).to eq("cancelled")
      expect(activity.cancelled_at).to be_present
    end

    it "allows a co-org to cancel [REQ-ACT-001]" do
      described_class.appoint_co_organizer!(activity: activity, actor: creator, user: co_org_user)
      described_class.cancel!(activity: activity, actor: co_org_user)
      expect(activity.reload.cancelled?).to eq(true)
    end
  end
end
