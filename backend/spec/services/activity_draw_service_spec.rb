# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityDrawService do
  let(:creator) { create(:user) }
  let(:a) { create(:user) }
  let(:b) { create(:user) }
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
    [ a, b ].each { |u| ActivityParticipant.invite!(activity: activity, user: u, actor: creator).accept! }
  end

  describe "secret_santa draw [REQ-ACT-001] [REQ-ACT-004]" do
    it "requires at least 3 accepted participants [REQ-ACT-001]" do
      thin = Activity.create!(
        creator: creator,
        name: "Dos",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
      ActivityParticipant.invite!(activity: thin, user: a, actor: creator).accept!

      expect {
        described_class.draw!(activity: thin, actor: creator, seed: 1)
      }.to raise_error(ArgumentError, /3|minimum|accepted/i)
    end

    it "persists a single Hamiltonian cycle of assignments [REQ-ACT-001] [REQ-ACT-004]" do
      result = described_class.draw!(activity: activity, actor: creator, seed: 42)

      expect(activity.reload.sealed?).to eq(true)
      expect(activity.status).to eq("sealed")
      assignments = ActivityAssignment.where(activity: activity)
      expect(assignments.count).to eq(3)

      map = assignments.to_h { |row| [ row.giver_id, row.recipient_id ] }
      expect(map.keys.uniq.size).to eq(3)
      expect(map.values.uniq.size).to eq(3)
      expect(map.any? { |giver_id, recipient_id| giver_id == recipient_id }).to eq(false)

      # single cycle: follow edges back to start
      start = map.keys.first
      cursor = start
      seen = []
      3.times do
        seen << cursor
        cursor = map.fetch(cursor)
      end
      expect(cursor).to eq(start)
      expect(seen.uniq.size).to eq(3)
      expect(result).to be_a(Hash)
    end

    it "is deterministic for the same seed [REQ-ACT-004]" do
      first = described_class.draw!(activity: activity, actor: creator, seed: 7)
      # reset for second draw on a fresh activity
      other = Activity.create!(
        creator: creator,
        name: "Otro",
        currency: "CRC",
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none"
      )
      [ a, b ].each { |u| ActivityParticipant.invite!(activity: other, user: u, actor: creator).accept! }
      second = described_class.draw!(activity: other, actor: creator, seed: 7)

      expect(first).to eq(second)
    end

    it "does not expose the full assignment map via creator assignment query helper [REQ-ACT-004]" do
      described_class.draw!(activity: activity, actor: creator, seed: 3)
      expect(described_class.assignment_for(activity: activity, viewer: creator)).to be_a(ActivityAssignment)
      expect(described_class.assignments_for_admin(activity: activity, actor: creator)).to eq([])
    end
  end
end
