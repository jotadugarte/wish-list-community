# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Wishlist Item SoftDeletable cascade [REQ-LIFE-001]" do
  let(:owner) { create(:user) }
  let(:wishlist) { create(:wishlist, owner: owner) }

  it "soft-deletes kept items when the wishlist is soft-deleted [REQ-LIFE-001]" do
    kept = create(:item, wishlist: wishlist, title: "Kept")
    already = create(:item, wishlist: wishlist, title: "Already")
    already.soft_delete!(actor: owner)

    wishlist.soft_delete!(actor: owner)

    expect(kept.reload).to be_discarded
    expect(already.reload).to be_discarded
  end

  it "restores items that were cascaded with the wishlist soft-delete [REQ-LIFE-001]" do
    item = create(:item, wishlist: wishlist, title: "Restore me")
    wishlist.soft_delete!(actor: owner)
    expect(item.reload).to be_discarded

    expect(wishlist.restore!(actor: owner)).to eq(true)
    expect(wishlist.reload).not_to be_discarded
    expect(item.reload).not_to be_discarded
  end

  it "registers reservation cancel hook on soft-delete [REQ-LIFE-001]" do
    expect(Item.soft_delete_hooks).to have_key(:cancel_active_reservations)
  end
end
