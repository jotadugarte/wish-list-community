# frozen_string_literal: true

require "rails_helper"
require "vips"

RSpec.describe "Hotwire member items [REQ-ITEM-001] [REQ-ITEM-002]", type: :request do
  let(:owner) { create(:user) }
  let(:wishlist) { create(:wishlist, owner: owner, title: "Lista items") }

  def login_web!(user)
    post "/session", params: { email_address: user.email_address, password: "SecurePassword123!" }
  end

  def tiny_png_upload
    image = Vips::Image.black(32, 32).copy(interpretation: :srgb)
    tmp = Tempfile.new([ "hotwire", ".png" ])
    image.write_to_file(tmp.path)
    tmp.rewind
    Rack::Test::UploadedFile.new(tmp.path, "image/png", original_filename: "shot.png")
  end

  before { login_web!(owner) }

  it "creates an item with title, paste URL link, and multipart image" do
    expect {
      post "/app/wishlists/#{wishlist.id}/items", params: {
        item: { title: "Libro", links: [ "https://store.example/libro" ] },
        images: [ tiny_png_upload ]
      }
    }.to change { wishlist.items.kept.count }.by(1)

    item = wishlist.items.kept.find_by!(title: "Libro")
    expect(response).to redirect_to(member_wishlist_path(wishlist))
    expect(item.item_links.pluck(:url)).to include("https://store.example/libro")
    expect(item.images.count).to eq(1)
  end

  it "updates and soft-deletes an item" do
    item = create(:item, wishlist: wishlist, title: "Old")
    patch "/app/items/#{item.id}", params: { item: { title: "New" } }
    expect(response).to redirect_to(member_wishlist_path(wishlist))
    expect(item.reload.title).to eq("New")

    delete "/app/items/#{item.id}"
    expect(response).to redirect_to(member_wishlist_path(wishlist))
    expect(item.reload.discarded_at).to be_present
  end

  it "preserves the full links list when editing with links_text [REQ-ITEM-001]" do
    item = create(:item, wishlist: wishlist, title: "Multi")
    item.item_links.create!(url: "https://a.example/1", position: 0)
    item.item_links.create!(url: "https://b.example/2", position: 1)

    patch "/app/items/#{item.id}", params: {
      item: {
        title: "Multi",
        links_text: "https://a.example/1\nhttps://b.example/2\nhttps://c.example/3"
      }
    }
    expect(response).to redirect_to(member_wishlist_path(wishlist))
    expect(item.reload.item_links.order(:position).pluck(:url)).to eq([
      "https://a.example/1",
      "https://b.example/2",
      "https://c.example/3"
    ])
  end


  it "item form page includes client image compress helper hook (O5A)" do
    get "/app/wishlists/#{wishlist.id}/items/new"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("data-controller=\"image-compress\"")
  end
end
