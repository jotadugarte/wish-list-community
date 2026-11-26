# frozen_string_literal: true

class CreateReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :reservations do |t|
      t.references :item, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.date :estimated_date, null: false
      t.string :private_note
      t.datetime :grace_expires_at
      t.timestamps
    end

    add_index :reservations, :item_id,
              unique: true,
              where: "status IN ('active', 'expired_grace')",
              name: "index_reservations_one_active_hold_per_item"
    add_index :reservations, [:user_id, :status], name: "index_reservations_on_user_id_and_status"
  end
end
