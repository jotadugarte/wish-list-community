# frozen_string_literal: true

class CreateActivityAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_assignments do |t|
      t.references :activity, null: false, foreign_key: { on_delete: :cascade }
      t.references :giver, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :recipient, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.timestamps
    end

    add_index :activity_assignments, [ :activity_id, :giver_id ], unique: true
    add_index :activity_assignments, [ :activity_id, :recipient_id ], unique: true
  end
end
