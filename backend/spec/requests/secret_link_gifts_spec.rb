# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Secret Link gifts (O3C)", type: :request do
  let(:owner) { create(:user, username: "gift_sl_owner") }
  let(:viewer) { create(:user, username: "gift_sl_viewer") }
  let(:wishlist) { create(:wishlist, :shared, owner: owner, title: "Fiesta") }
  let(:item) { create(:item, wishlist: wishlist, title: "Regalo") }

  def login_web!(user)
    post "/session", params: {
      email_address: user.email_address,
      password: "SecurePassword123!"
    }
  end

  it "lets sharee mark purchased and delivered; owner confirms with thank-you [REQ-GIFT-001] [REQ-GIFT-004]" do
    login_web!(viewer)
    hold = Reservation.create!(item: item, user: viewer, status: "active", estimated_date: Date.current + 5)

    post "/s/#{wishlist.share_token}/reservations/#{hold.id}/mark_purchased"
    expect(response).to redirect_to("/s/#{wishlist.share_token}")
    gift = GiftRecord.find_by!(item: item, gifter: viewer, status: "purchased_secret")

    post "/s/#{wishlist.share_token}/gifts/#{gift.id}/mark_delivered"
    expect(response).to redirect_to("/s/#{wishlist.share_token}")
    expect(gift.reload.status).to eq("delivered_pending_confirmation")

    login_web!(owner)
    post "/s/#{wishlist.share_token}/gifts/#{gift.id}/confirm_received",
         params: { thank_you_note: "¡Gracias!" }
    expect(response).to redirect_to("/s/#{wishlist.share_token}")
    expect(gift.reload.status).to eq("received_confirmed")

    get "/s/#{wishlist.share_token}"
    expect(response.body).to include('data-testid="received-gifts"')
    expect(response.body).to include("Regalo")
  end

  it "lets owner Path 2 mark received on Secret Link [REQ-GIFT-003] [REQ-ITEM-004]" do
    login_web!(owner)
    post "/s/#{wishlist.share_token}/items/#{item.id}/mark_received"
    expect(response).to redirect_to("/s/#{wishlist.share_token}")
    expect(GiftRecord.find_by!(item: item).status).to eq("received_confirmed")

    get "/s/#{wishlist.share_token}"
    expect(response.body).to include('data-testid="received-gifts"')
    expect(response.body).to include('data-testid="received-gift-')
  end
end
