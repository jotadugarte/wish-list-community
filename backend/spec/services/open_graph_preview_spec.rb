# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe OpenGraphPreview do
  before { WebMock.disable_net_connect!(allow_localhost: false) }
  after { WebMock.allow_net_connect! }

  describe "extract [REQ-ITEM-006]" do
    it "returns og:title and og:image from mocked HTML [REQ-ITEM-006]" do
      stub_request(:get, "https://shop.example/product/1")
        .to_return(
          status: 200,
          body: <<~HTML
            <html><head>
              <meta property="og:title" content="Cool Gadget" />
              <meta property="og:image" content="https://cdn.example/img.webp" />
            </head></html>
          HTML
        )

      allow(Addrinfo).to receive(:getaddrinfo).and_return(
        [ Addrinfo.ip("203.0.113.10") ]
      )

      result = described_class.fetch("https://shop.example/product/1")
      expect(result[:title]).to eq("Cool Gadget")
      expect(result[:image_url]).to eq("https://cdn.example/img.webp")
      expect(result[:source_url]).to eq("https://shop.example/product/1")
    end

    it "rejects SSRF targets without connecting [REQ-ITEM-006]" do
      %w[
        http://127.0.0.1/secret
        http://10.0.0.1/secret
        http://169.254.169.254/latest/meta-data
      ].each do |evil|
        allow(Addrinfo).to receive(:getaddrinfo).and_return(
          [ Addrinfo.ip(URI.parse(evil).host) ]
        )
        result = described_class.fetch(evil)
        expect(result[:title]).to eq("")
        expect(result[:image_url]).to eq("")
        expect(WebMock).not_to have_requested(:get, evil)
      end
    end
  end
end
