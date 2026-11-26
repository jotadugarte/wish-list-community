# frozen_string_literal: true

class CreateNotificationsAndPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :channels, null: false, default: {}
      t.timestamps
    end

    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :event_key, null: false
      t.string :title, null: false
      t.text :body
      t.jsonb :payload, null: false, default: {}
      t.datetime :read_at
      t.timestamps
    end

    add_index :notifications, [:user_id, :created_at]
    add_index :notifications, [:user_id, :read_at]
  end
end
