# frozen_string_literal: true

class CreateActivityExclusions < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_exclusions do |t|
      t.references :activity, null: false, foreign_key: { on_delete: :cascade }
      t.references :giver, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :forbidden_recipient, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.timestamps
    end

    add_index :activity_exclusions,
              [ :activity_id, :giver_id, :forbidden_recipient_id ],
              unique: true,
              name: "index_activity_exclusions_unique_pair"
  end
end
