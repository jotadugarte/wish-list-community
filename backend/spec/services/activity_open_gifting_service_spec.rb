# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityOpenGiftingService do
  let(:creator) { create(:user) }
  let(:a) { create(:user) }
  let(:activity) do
    Activity.create!(
      creator: creator,
      name: "Abiertos",
      currency: "CRC",
      assignment_mode: "open_gifting",
      visibility_mode: "all_participants",
      reservation_visibility: "visible_to_recipient",
      budget_mode: "none"
    )
  end

  describe "Arrancar / cerrar altas [REQ-ACT-001]" do
    it "requires at least 2 accepted participants [REQ-ACT-001]" do
      expect {
        described_class.arrancar!(activity: activity, actor: creator)
      }.to raise_error(ArgumentError, /2|minimum|accepted/i)
    end

    it "seals participation without creating assignments [REQ-ACT-001]" do
      ActivityParticipant.invite!(activity: activity, user: a, actor: creator).accept!
      described_class.arrancar!(activity: activity, actor: creator)

      expect(activity.reload.sealed?).to eq(true)
      expect(activity.status).to eq("sealed")
      expect(ActivityAssignment.where(activity: activity)).to be_empty
    end

    it "rejects Arrancar for secret_santa activities [REQ-ACT-001]" do
      santa = Activity.create!(
        creator: creator,
        name: "Santa",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
      ActivityParticipant.invite!(activity: santa, user: a, actor: creator).accept!
      create(:user).tap { |u| ActivityParticipant.invite!(activity: santa, user: u, actor: creator).accept! }

      expect {
        described_class.arrancar!(activity: santa, actor: creator)
      }.to raise_error(ArgumentError, /open_gifting/i)
    end
  end
end
