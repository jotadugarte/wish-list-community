# frozen_string_literal: true

class CreateUsersAndUsernameReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :username, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "user"
      t.string :locale, null: false, default: "es"
      t.string :time_zone, null: false, default: "UTC"
      t.datetime :username_changed_at
      t.datetime :terms_accepted_at, null: false
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :users, "LOWER(email_address)", unique: true, name: "idx_users_on_lower_email_address"
    add_index :users, "LOWER(username)", unique: true, name: "idx_users_on_lower_username"
    add_index :users, :discarded_at

    create_table :username_reservations do |t|
      t.string :username, null: false
      t.references :previous_user, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :username_reservations, "LOWER(username)", unique: true, name: "idx_username_reservations_on_lower_username"
    add_index :username_reservations, :expires_at
  end
end
