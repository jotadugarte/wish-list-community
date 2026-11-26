# frozen_string_literal: true

class CreateGiftRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :gift_records do |t|
      t.references :item, null: false, foreign_key: true
      t.references :gifter, null: true, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "purchased_secret"
      t.string :thank_you_note
      t.string :purchase_link_ref
      t.timestamps
    end

    add_index :gift_records, :item_id,
              unique: true,
              where: "status IN ('purchased_secret', 'delivered_pending_confirmation')",
              name: "index_gift_records_one_open_gift_per_item"
    add_index :gift_records, [ :gifter_id, :status ], name: "index_gift_records_on_gifter_id_and_status"
  end
end
