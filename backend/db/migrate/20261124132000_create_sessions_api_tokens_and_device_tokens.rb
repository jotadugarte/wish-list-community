# frozen_string_literal: true

class CreateSessionsApiTokensAndDeviceTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    create_table :api_tokens do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :token_digest, null: false
      t.string :device_name
      t.datetime :last_used_at
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :api_tokens, :token_digest, unique: true

    create_table :device_tokens do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :api_token, null: false, foreign_key: { on_delete: :cascade }
      t.string :token, null: false
      t.string :platform, null: false, default: "unknown"

      t.timestamps
    end

    add_index :device_tokens, :token, unique: true
  end
end
