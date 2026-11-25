# frozen_string_literal: true

class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.bigint :reporter_id, null: false
      t.string :reportable_type, null: false
      t.bigint :reportable_id, null: false
      t.string :reason, null: false
      t.text :details
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :reports, :reporter_id
    add_index :reports, %i[reportable_type reportable_id]
    add_index :reports, :status
    add_index :reports,
              %i[reporter_id reportable_type reportable_id],
              unique: true,
              where: "status = 'pending'",
              name: "idx_reports_unique_pending_per_reporter_target"

    add_foreign_key :reports, :users, column: :reporter_id, on_delete: :cascade
  end
end
