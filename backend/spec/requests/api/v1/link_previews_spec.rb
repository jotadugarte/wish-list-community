# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe "Api::V1::LinkPreviews", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{ApiToken.issue_for!(user).last}" } }

  before do
    WebMock.disable_net_connect!(allow_localhost: false)
    allow(Addrinfo).to receive(:getaddrinfo).and_return([ Addrinfo.ip("203.0.113.10") ])
  end

  after { WebMock.allow_net_connect! }

  describe "POST /api/v1/link_previews [REQ-ITEM-006]" do
    it "returns mocked og preview for authenticated users [REQ-ITEM-006]" do
      stub_request(:get, "https://shop.example/p/1").to_return(
        status: 200,
        body: '<meta property="og:title" content="Gadget" /><meta property="og:image" content="https://cdn.example/i.png" />'
      )

      post "/api/v1/link_previews", params: { url: "https://shop.example/p/1" }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["title"]).to eq("Gadget")
      expect(response.parsed_body["image_url"]).to eq("https://cdn.example/i.png")
    end

    it "requires auth [REQ-ITEM-006]" do
      post "/api/v1/link_previews", params: { url: "https://shop.example/p/1" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
