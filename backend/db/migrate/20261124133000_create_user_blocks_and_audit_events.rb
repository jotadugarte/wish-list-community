# frozen_string_literal: true

class CreateUserBlocksAndAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :user_blocks do |t|
      t.references :blocker, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :blocked, null: false, foreign_key: { to_table: :users, on_delete: :cascade }

      t.timestamps
    end

    add_index :user_blocks, %i[blocker_id blocked_id], unique: true
    add_index :user_blocks, %i[blocked_id blocker_id]

    create_table :audit_events do |t|
      t.references :actor, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :action, null: false
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :audit_events, %i[auditable_type auditable_id]
    add_index :audit_events, :action
  end
end
