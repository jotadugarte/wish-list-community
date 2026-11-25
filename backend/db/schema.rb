# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_25_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.string "device_name"
    t.datetime "last_used_at"
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "audit_events", force: :cascade do |t|
    t.bigint "actor_id"
    t.string "action", null: false
    t.string "auditable_type", null: false
    t.bigint "auditable_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_events_on_action"
    t.index ["actor_id"], name: "index_audit_events_on_actor_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_events_on_auditable_type_and_auditable_id"
  end

  create_table "device_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "api_token_id", null: false
    t.string "token", null: false
    t.string "platform", default: "unknown", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token_id"], name: "index_device_tokens_on_api_token_id"
    t.index ["token"], name: "index_device_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_device_tokens_on_user_id"
  end

  create_table "friendships", force: :cascade do |t|
    t.bigint "requester_id", null: false
    t.bigint "addressee_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)", name: "idx_friendships_on_unordered_user_pair", unique: true
    t.index ["addressee_id"], name: "index_friendships_on_addressee_id"
    t.index ["requester_id"], name: "index_friendships_on_requester_id"
    t.index ["status"], name: "index_friendships_on_status"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "user_blocks", force: :cascade do |t|
    t.bigint "blocker_id", null: false
    t.bigint "blocked_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_id", "blocker_id"], name: "index_user_blocks_on_blocked_id_and_blocker_id"
    t.index ["blocked_id"], name: "index_user_blocks_on_blocked_id"
    t.index ["blocker_id", "blocked_id"], name: "index_user_blocks_on_blocker_id_and_blocked_id", unique: true
    t.index ["blocker_id"], name: "index_user_blocks_on_blocker_id"
  end

  create_table "username_reservations", force: :cascade do |t|
    t.string "username", null: false
    t.bigint "previous_user_id", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((username)::text)", name: "idx_username_reservations_on_lower_username", unique: true
    t.index ["expires_at"], name: "index_username_reservations_on_expires_at"
    t.index ["previous_user_id"], name: "index_username_reservations_on_previous_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "username", null: false
    t.string "password_digest", null: false
    t.string "role", default: "user", null: false
    t.string "locale", default: "es", null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "username_changed_at"
    t.datetime "terms_accepted_at", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email_address)::text)", name: "idx_users_on_lower_email_address", unique: true
    t.index "lower((username)::text)", name: "idx_users_on_lower_username", unique: true
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
  end

  add_foreign_key "api_tokens", "users", on_delete: :cascade
  add_foreign_key "audit_events", "users", column: "actor_id", on_delete: :nullify
  add_foreign_key "device_tokens", "api_tokens", on_delete: :cascade
  add_foreign_key "device_tokens", "users", on_delete: :cascade
  add_foreign_key "friendships", "users", column: "addressee_id", on_delete: :cascade
  add_foreign_key "friendships", "users", column: "requester_id", on_delete: :cascade
  add_foreign_key "sessions", "users", on_delete: :cascade
  add_foreign_key "user_blocks", "users", column: "blocked_id", on_delete: :cascade
  add_foreign_key "user_blocks", "users", column: "blocker_id", on_delete: :cascade
  add_foreign_key "username_reservations", "users", column: "previous_user_id", on_delete: :cascade
end
