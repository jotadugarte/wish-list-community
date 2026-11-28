# frozen_string_literal: true

# One activity-scoped wishlist per participant (FC1A / REQ-ARCH-002).
class AddUniqueActivityOwnerToWishlists < ActiveRecord::Migration[8.1]
  def change
    add_index :wishlists, [ :activity_id, :owner_id ],
              unique: true,
              where: "activity_id IS NOT NULL",
              name: "index_wishlists_on_activity_id_and_owner_id_unique"
  end
end
