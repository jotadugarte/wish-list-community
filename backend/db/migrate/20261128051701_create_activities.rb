# frozen_string_literal: true

class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :creator, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :name, null: false
      t.string :currency, null: false
      t.string :assignment_mode, null: false
      t.string :visibility_mode, null: false
      t.string :reservation_visibility, null: false
      t.string :budget_mode, null: false, default: "none"
      t.integer :budget_amount_cents
      t.integer :budget_max_cents
      t.string :share_token, null: false
      t.string :status, null: false, default: "open"
      t.date :starts_on
      t.date :ends_on
      t.datetime :sealed_at
      t.datetime :cancelled_at
      t.datetime :money_settings_frozen_at
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :activities, :share_token, unique: true
    add_index :activities, :discarded_at
    add_index :activities, [ :creator_id, :status ]

    create_table :activity_participants do |t|
      t.references :activity, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :status, null: false, default: "invited"
      t.boolean :co_organizer, null: false, default: false
      t.datetime :accepted_at
      t.datetime :left_at
      t.timestamps
    end

    add_index :activity_participants, [ :activity_id, :user_id ], unique: true
    add_index :activity_participants, [ :activity_id, :status ]
  end
end
