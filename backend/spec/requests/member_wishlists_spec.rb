# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Hotwire member wishlists [REQ-WISH-001] [REQ-WISH-002] [REQ-WISH-006] [REQ-LIFE-001]", type: :request do
  let(:owner) { create(:user, username: "web_owner") }
  let(:friend) { create(:user, username: "web_friend") }

  def login_web!(user)
    post "/session", params: { email_address: user.email_address, password: "SecurePassword123!" }
  end

  before { login_web!(owner) }

  it "lists owner wishlists and creates with default friends privacy" do
    get "/app/wishlists"
    expect(response).to have_http_status(:ok)

    expect {
      post "/app/wishlists", params: { wishlist: { title: "Navidad" } }
    }.to change { owner.wishlists.kept.count }.by(1)

    expect(response).to redirect_to(%r{/app/wishlists/\d+})
    follow_redirect!
    wishlist = owner.wishlists.kept.find_by!(title: "Navidad")
    expect(wishlist.privacy_mode).to eq("friends")
    expect(response.body).to include("Navidad")
  end

  it "edits title and switches privacy to shared minting a secret link" do
    wishlist = create(:wishlist, owner: owner, title: "Old", privacy_mode: "friends")
    patch "/app/wishlists/#{wishlist.id}", params: { wishlist: { title: "New", privacy_mode: "shared" } }
    expect(response).to redirect_to(member_wishlist_path(wishlist))
    wishlist.reload
    expect(wishlist.title).to eq("New")
    expect(wishlist.privacy_mode).to eq("shared")
    expect(wishlist.share_token).to be_present
  end

  it "rotates share token while staying shared" do
    wishlist = create(:wishlist, :shared, owner: owner)
    old = wishlist.share_token
    post "/app/wishlists/#{wishlist.id}/rotate_share_token"
    expect(response).to redirect_to(member_wishlist_path(wishlist))
    expect(wishlist.reload.share_token).to be_present
    expect(wishlist.share_token).not_to eq(old)
  end

  it "adds and removes an explicit share with an accepted friend" do
    Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
    wishlist = create(:wishlist, :shared, owner: owner)

    post "/app/wishlists/#{wishlist.id}/shares", params: { user_id: friend.id }
    expect(WishlistShare.find_by(wishlist: wishlist, user: friend)).to be_present

    delete "/app/wishlists/#{wishlist.id}/shares/#{friend.id}"
    expect(WishlistShare.find_by(wishlist: wishlist, user: friend)).to be_nil
  end

  it "soft-deletes an owned wishlist" do
    wishlist = create(:wishlist, owner: owner)
    delete "/app/wishlists/#{wishlist.id}"
    expect(response).to redirect_to(member_wishlists_path)
    expect(wishlist.reload.discarded_at).to be_present
  end
end
