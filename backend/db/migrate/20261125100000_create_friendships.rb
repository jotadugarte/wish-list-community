# frozen_string_literal: true

class CreateFriendships < ActiveRecord::Migration[8.1]
  def change
    create_table :friendships do |t|
      t.bigint :requester_id, null: false
      t.bigint :addressee_id, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :friendships, :requester_id
    add_index :friendships, :addressee_id
    add_index :friendships, :status
    add_index :friendships,
              "LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)",
              unique: true,
              name: "idx_friendships_on_unordered_user_pair"

    add_foreign_key :friendships, :users, column: :requester_id, on_delete: :cascade
    add_foreign_key :friendships, :users, column: :addressee_id, on_delete: :cascade
  end
end
