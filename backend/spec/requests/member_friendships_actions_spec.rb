# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Hotwire friendship accept/decline [REQ-SOC-001]", type: :request do
  let(:viewer) { create(:user, username: "viewer_fr") }
  let(:requester) { create(:user, username: "req_fr") }

  def login_web!(user)
    post "/session", params: { email_address: user.email_address, password: "SecurePassword123!" }
  end

  before { login_web!(viewer) }

  it "accepts an incoming request from /app/friends" do
    friendship = Friendship.request!(requester: requester, addressee: viewer)
    patch "/app/friendships/#{friendship.id}"
    expect(response).to redirect_to(member_friends_path)
    expect(friendship.reload.status).to eq("accepted")
  end

  it "declines an incoming request" do
    friendship = Friendship.request!(requester: requester, addressee: viewer)
    delete "/app/friendships/#{friendship.id}"
    expect(response).to redirect_to(member_friends_path)
    expect(Friendship.find_by(id: friendship.id)).to be_nil
    expect(flash[:notice]).to eq(
      I18n.t("member.friends.declined_notice", locale: viewer.locale.to_sym)
    )
  end
end
