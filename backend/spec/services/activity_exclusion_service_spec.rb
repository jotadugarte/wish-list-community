# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityExclusionService do
  let(:creator) { create(:user) }
  let(:users) { create_list(:user, 3) }
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
    users.each { |u| ActivityParticipant.invite!(activity: activity, user: u, actor: creator).accept! }
  end

  describe "pair exclusions + solvability [REQ-ACT-002] [REQ-ACT-004]" do
    it "adds an exclusion between accepted participants [REQ-ACT-002]" do
      exclusion = described_class.add!(
        activity: activity,
        actor: creator,
        giver: users[0],
        forbidden_recipient: users[1]
      )

      expect(exclusion.giver_id).to eq(users[0].id)
      expect(exclusion.forbidden_recipient_id).to eq(users[1].id)
      expect(described_class.solvable?(activity: activity)).to eq(true)
    end

    it "rejects self-exclusions and duplicates [REQ-ACT-002]" do
      expect {
        described_class.add!(activity: activity, actor: creator, giver: users[0], forbidden_recipient: users[0])
      }.to raise_error(ArgumentError, /self/i)

      described_class.add!(activity: activity, actor: creator, giver: users[0], forbidden_recipient: users[1])
      expect {
        described_class.add!(activity: activity, actor: creator, giver: users[0], forbidden_recipient: users[1])
      }.to raise_error(ArgumentError, /duplicate|exists/i)
    end

    it "detects unsolvable exclusion graphs with a hard upper bound [REQ-ACT-002] [REQ-ACT-004]" do
      # With 3 participants A,B,C (plus creator = 4). Make A unable to gift anyone except self:
      # For 3-person {u0,u1,u2} force u0 cannot gift u1 or u2 → unsolvable for that subgraph when drawing only them.
      # Use creator + 2 users (3 accepted) and exclude all edges from one person.
      solo = Activity.create!(
        creator: creator,
        name: "Tres",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
      a = create(:user)
      b = create(:user)
      ActivityParticipant.invite!(activity: solo, user: a, actor: creator).accept!
      ActivityParticipant.invite!(activity: solo, user: b, actor: creator).accept!

      described_class.add!(activity: solo, actor: creator, giver: a, forbidden_recipient: b)
      described_class.add!(activity: solo, actor: creator, giver: a, forbidden_recipient: creator)
      # a can only gift a (invalid) → no Hamiltonian cycle among {creator,a,b}
      expect(described_class.solvable?(activity: solo)).to eq(false)
      expect {
        described_class.assert_solvable!(activity: solo)
      }.to raise_error(ArgumentError, /solvable|exclusion/i)
    end

    it "removes an exclusion [REQ-ACT-002]" do
      exclusion = described_class.add!(activity: activity, actor: creator, giver: users[0], forbidden_recipient: users[1])
      described_class.remove!(activity: activity, actor: creator, exclusion: exclusion)
      expect(ActivityExclusion.where(id: exclusion.id)).not_to exist
    end
  end
end
