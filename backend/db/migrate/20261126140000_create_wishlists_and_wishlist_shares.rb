# frozen_string_literal: true

class CreateWishlistsAndWishlistShares < ActiveRecord::Migration[8.1]
  def change
    create_table :wishlists do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.string :title, null: false
      t.string :privacy_mode, null: false, default: "friends"
      t.string :share_token
      t.date :event_date
      t.bigint :activity_id
      t.integer :max_reservations_per_user
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :wishlists, :share_token, unique: true, where: "share_token IS NOT NULL", name: "index_wishlists_on_share_token_unique"
    add_index :wishlists, :discarded_at
    add_index :wishlists, :activity_id
    add_index :wishlists, [ :owner_id, :discarded_at ]

    create_table :wishlist_shares do |t|
      t.references :wishlist, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :source, null: false, default: "explicit"
      t.timestamps
    end

    add_index :wishlist_shares, [ :wishlist_id, :user_id ], unique: true, name: "index_wishlist_shares_on_wishlist_id_and_user_id"
  end
end
