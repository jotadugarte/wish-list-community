# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Member::Activities Hotwire [REQ-ACT-001] [REQ-WISH-001]", type: :request do
  let(:creator) { create(:user, password: "SecurePassword123!", password_confirmation: "SecurePassword123!") }
  let(:friend) { create(:user, password: "SecurePassword123!", password_confirmation: "SecurePassword123!") }

  before do
    post session_path, params: { email_address: creator.email_address, password: "SecurePassword123!" }
  end

  describe "create and board [REQ-ACT-001]" do
    it "creates an activity and shows personal wishlist bridge links [REQ-ACT-001] [REQ-WISH-001]" do
      Friendship.request!(requester: creator, addressee: friend).accept!(actor: friend)
      wishlist = Wishlist.create!(owner: friend, title: "Lista de Ana")

      post member_activities_path, params: {
        activity: {
          name: "Navidad",
          currency: "CRC",
          assignment_mode: "secret_santa",
          visibility_mode: "recipient_only",
          reservation_visibility: "hidden_from_recipient",
          budget_mode: "none"
        }
      }
      expect(response).to redirect_to(member_activity_path(Activity.order(:id).last))

      activity = Activity.order(:id).last
      ActivityParticipant.invite!(activity: activity, user: friend, actor: creator).accept!

      get member_activity_path(activity)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Navidad")
      expect(response.body).to include(wishlist.title)
    end
  end
end
