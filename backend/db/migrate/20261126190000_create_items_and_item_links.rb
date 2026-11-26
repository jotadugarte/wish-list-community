# frozen_string_literal: true

class CreateItemsAndItemLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.references :wishlist, null: false, foreign_key: true
      t.string :title, null: false
      t.text :specifications
      t.string :priority, null: false, default: "medium"
      t.integer :price_cents
      t.string :currency
      t.integer :position, null: false, default: 0
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :items, :discarded_at
    add_index :items, %i[wishlist_id discarded_at]
    add_index :items, %i[wishlist_id position]

    create_table :item_links do |t|
      t.references :item, null: false, foreign_key: true
      t.string :url, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :item_links, %i[item_id position]
  end
end
