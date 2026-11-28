# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityReservationLimitService do
  let(:creator) { create(:user) }
  let(:invitee) { create(:user) }

  def open_activity!(n_invitees: 1)
    activity = Activity.create!(
      creator: creator,
      name: "Open N",
      currency: "CRC",
      assignment_mode: "open_gifting",
      visibility_mode: "all_participants",
      reservation_visibility: "hidden_from_recipient",
      budget_mode: "none"
    )
    n_invitees.times do
      user = create(:user)
      ActivityParticipant.invite!(activity: activity, user: user, actor: creator).accept!
    end
    activity
  end

  describe ".set! [REQ-RES-005] O5A FC3A" do
    it "updates max_reservations_per_user on all activity wishlists pre-seal [REQ-RES-005]" do
      activity = open_activity!
      described_class.set!(activity: activity, actor: creator, max: 3)

      wishlists = Wishlist.where(activity_id: activity.id).kept
      expect(wishlists.map(&:max_reservations_per_user).uniq).to eq([ 3 ])
    end

    it "rejects set! after seal (freeze at Arrancar) [REQ-RES-005] FC3A" do
      activity = open_activity!
      ActivityOpenGiftingService.arrancar!(activity: activity, actor: creator)

      expect {
        described_class.set!(activity: activity, actor: creator, max: 5)
      }.to raise_error(ArgumentError, /seal|frozen|sealed/i)
    end

    it "requires creator or co-organizer [REQ-RES-005]" do
      activity = open_activity!
      peer = activity.accepted_participants.where.not(user_id: creator.id).first.user

      expect {
        described_class.set!(activity: activity, actor: peer, max: 2)
      }.to raise_error(ArgumentError, /admin|creator|co-organizer/i)
    end
  end
end
