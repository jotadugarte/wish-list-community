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

ActiveRecord::Schema[8.1].define(version: 2026_11_28_051701) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.bigint "creator_id", null: false
    t.string "name", null: false
    t.string "currency", null: false
    t.string "assignment_mode", null: false
    t.string "visibility_mode", null: false
    t.string "reservation_visibility", null: false
    t.string "budget_mode", default: "none", null: false
    t.integer "budget_amount_cents"
    t.integer "budget_max_cents"
    t.string "share_token", null: false
    t.string "status", default: "open", null: false
    t.date "starts_on"
    t.date "ends_on"
    t.datetime "sealed_at"
    t.datetime "cancelled_at"
    t.datetime "money_settings_frozen_at"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id", "status"], name: "index_activities_on_creator_id_and_status"
    t.index ["creator_id"], name: "index_activities_on_creator_id"
    t.index ["discarded_at"], name: "index_activities_on_discarded_at"
    t.index ["share_token"], name: "index_activities_on_share_token", unique: true
  end

  create_table "activity_participants", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.bigint "user_id", null: false
    t.string "status", default: "invited", null: false
    t.boolean "co_organizer", default: false, null: false
    t.datetime "accepted_at"
    t.datetime "left_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id", "status"], name: "index_activity_participants_on_activity_id_and_status"
    t.index ["activity_id", "user_id"], name: "index_activity_participants_on_activity_id_and_user_id", unique: true
    t.index ["activity_id"], name: "index_activity_participants_on_activity_id"
    t.index ["user_id"], name: "index_activity_participants_on_user_id"
  end

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

  create_table "gift_records", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "gifter_id"
    t.string "status", default: "purchased_secret", null: false
    t.string "thank_you_note"
    t.string "purchase_link_ref"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gifter_id", "status"], name: "index_gift_records_on_gifter_id_and_status"
    t.index ["gifter_id"], name: "index_gift_records_on_gifter_id"
    t.index ["item_id"], name: "index_gift_records_on_item_id"
    t.index ["item_id"], name: "index_gift_records_one_open_gift_per_item", unique: true, where: "((status)::text = ANY (ARRAY[('purchased_secret'::character varying)::text, ('delivered_pending_confirmation'::character varying)::text]))"
  end

  create_table "item_links", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.string "url", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id", "position"], name: "index_item_links_on_item_id_and_position"
    t.index ["item_id"], name: "index_item_links_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.bigint "wishlist_id", null: false
    t.string "title", null: false
    t.text "specifications"
    t.string "priority", default: "medium", null: false
    t.integer "price_cents"
    t.string "currency"
    t.integer "position", default: 0, null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_items_on_discarded_at"
    t.index ["wishlist_id", "discarded_at"], name: "index_items_on_wishlist_id_and_discarded_at"
    t.index ["wishlist_id", "position"], name: "index_items_on_wishlist_id_and_position"
    t.index ["wishlist_id"], name: "index_items_on_wishlist_id"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "channels", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notification_preferences_on_user_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "event_key", null: false
    t.string "title", null: false
    t.text "body"
    t.jsonb "payload", default: {}, null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "reporter_id", null: false
    t.string "reportable_type", null: false
    t.bigint "reportable_id", null: false
    t.string "reason", null: false
    t.text "details"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reportable_type_and_reportable_id"
    t.index ["reporter_id", "reportable_type", "reportable_id"], name: "idx_reports_unique_pending_per_reporter_target", unique: true, where: "((status)::text = 'pending'::text)"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["status"], name: "index_reports_on_status"
  end

  create_table "reservations", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "user_id", null: false
    t.string "status", default: "active", null: false
    t.date "estimated_date", null: false
    t.string "private_note"
    t.datetime "grace_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_reservations_on_item_id"
    t.index ["item_id"], name: "index_reservations_one_active_hold_per_item", unique: true, where: "((status)::text = ANY (ARRAY[('active'::character varying)::text, ('expired_grace'::character varying)::text]))"
    t.index ["user_id", "status"], name: "index_reservations_on_user_id_and_status"
    t.index ["user_id"], name: "index_reservations_on_user_id"
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
    t.datetime "suspended_at"
    t.index "lower((email_address)::text)", name: "idx_users_on_lower_email_address", unique: true
    t.index "lower((username)::text)", name: "idx_users_on_lower_username", unique: true
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["suspended_at"], name: "index_users_on_suspended_at"
  end

  create_table "wishlist_shares", force: :cascade do |t|
    t.bigint "wishlist_id", null: false
    t.bigint "user_id", null: false
    t.string "source", default: "explicit", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wishlist_shares_on_user_id"
    t.index ["wishlist_id", "user_id"], name: "index_wishlist_shares_on_wishlist_id_and_user_id", unique: true
    t.index ["wishlist_id"], name: "index_wishlist_shares_on_wishlist_id"
  end

  create_table "wishlists", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.string "title", null: false
    t.string "privacy_mode", default: "friends", null: false
    t.string "share_token"
    t.date "event_date"
    t.bigint "activity_id"
    t.integer "max_reservations_per_user"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_wishlists_on_activity_id"
    t.index ["discarded_at"], name: "index_wishlists_on_discarded_at"
    t.index ["owner_id", "discarded_at"], name: "index_wishlists_on_owner_id_and_discarded_at"
    t.index ["owner_id"], name: "index_wishlists_on_owner_id"
    t.index ["share_token"], name: "index_wishlists_on_share_token_unique", unique: true, where: "(share_token IS NOT NULL)"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "users", column: "creator_id", on_delete: :restrict
  add_foreign_key "activity_participants", "activities", on_delete: :cascade
  add_foreign_key "activity_participants", "users", on_delete: :cascade
  add_foreign_key "api_tokens", "users", on_delete: :cascade
  add_foreign_key "audit_events", "users", column: "actor_id", on_delete: :nullify
  add_foreign_key "device_tokens", "api_tokens", on_delete: :cascade
  add_foreign_key "device_tokens", "users", on_delete: :cascade
  add_foreign_key "friendships", "users", column: "addressee_id", on_delete: :cascade
  add_foreign_key "friendships", "users", column: "requester_id", on_delete: :cascade
  add_foreign_key "gift_records", "items"
  add_foreign_key "gift_records", "users", column: "gifter_id"
  add_foreign_key "item_links", "items"
  add_foreign_key "items", "wishlists"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "reports", "users", column: "reporter_id", on_delete: :cascade
  add_foreign_key "reservations", "items"
  add_foreign_key "reservations", "users"
  add_foreign_key "sessions", "users", on_delete: :cascade
  add_foreign_key "user_blocks", "users", column: "blocked_id", on_delete: :cascade
  add_foreign_key "user_blocks", "users", column: "blocker_id", on_delete: :cascade
  add_foreign_key "username_reservations", "users", column: "previous_user_id", on_delete: :cascade
  add_foreign_key "wishlist_shares", "users", on_delete: :cascade
  add_foreign_key "wishlist_shares", "wishlists", on_delete: :cascade
  add_foreign_key "wishlists", "users", column: "owner_id", on_delete: :cascade
end
