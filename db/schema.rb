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

ActiveRecord::Schema[8.0].define(version: 2025_06_15_143524) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_hashcash_stamps", force: :cascade do |t|
    t.string "version", null: false
    t.integer "bits", null: false
    t.date "date", null: false
    t.string "resource", null: false
    t.string "ext", null: false
    t.string "rand", null: false
    t.string "counter", null: false
    t.string "request_path"
    t.string "ip_address"
    t.jsonb "context"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["counter", "rand", "date", "resource", "bits", "version", "ext"], name: "index_active_hashcash_stamps_unique", unique: true
    t.index ["ip_address", "created_at"], name: "index_active_hashcash_stamps_on_ip_address_and_created_at", where: "(ip_address IS NOT NULL)"
  end

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

  create_table "connected_services", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_connected_services_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_connected_services_on_user_id"
  end

  create_table "domains", force: :cascade do |t|
    t.string "name"
    t.bigint "newsletter_id", null: false
    t.string "status", default: "pending"
    t.string "region", default: "us-east-1"
    t.string "public_key"
    t.string "dkim_status", default: "pending"
    t.string "spf_status", default: "pending"
    t.string "error_message"
    t.boolean "dmarc_added", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_domains_on_name", unique: true
    t.index ["newsletter_id"], name: "index_domains_on_newsletter_id"
    t.index ["status", "dkim_status", "spf_status"], name: "index_domains_on_status_and_dkim_status_and_spf_status"
  end

  create_table "email_clicks", force: :cascade do |t|
    t.string "link"
    t.string "email_id", null: false
    t.bigint "post_id", null: false
    t.datetime "timestamp"
    t.index ["email_id"], name: "index_email_clicks_on_email_id"
    t.index ["post_id"], name: "index_email_clicks_on_post_id"
  end

  create_table "emails", id: :string, force: :cascade do |t|
    t.bigint "post_id", null: false
    t.string "status", default: "sent"
    t.datetime "bounced_at"
    t.datetime "delivered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "subscriber_id"
    t.datetime "complained_at"
    t.datetime "opened_at"
    t.index ["post_id"], name: "index_emails_on_post_id"
    t.index ["subscriber_id"], name: "index_emails_on_subscriber_id"
  end

  create_table "labels", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "color", default: "#6B7280", null: false
    t.bigint "newsletter_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["newsletter_id", "name"], name: "index_labels_on_newsletter_id_and_name", unique: true
    t.index ["newsletter_id"], name: "index_labels_on_newsletter_id"
  end

  create_table "newsletters", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "user_id", null: false
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.string "timezone", default: "UTC", null: false
    t.string "template"
    t.string "website"
    t.text "email_css"
    t.string "primary_color", default: "#09090b"
    t.string "font_preference", default: "sans-serif"
    t.text "email_footer", default: ""
    t.string "domain"
    t.string "sending_address"
    t.string "reply_to"
    t.boolean "domain_verified", default: false
    t.string "domain_id"
    t.json "dns_records"
    t.boolean "enable_archive", default: true
    t.string "sending_name"
    t.jsonb "settings", default: {}, null: false
    t.boolean "auto_reminder_enabled", default: true, null: false
    t.index ["settings"], name: "index_newsletters_on_settings", using: :gin
    t.index ["slug"], name: "index_newsletters_on_slug"
    t.index ["user_id"], name: "index_newsletters_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.integer "newsletter_id", null: false
    t.datetime "scheduled_at"
    t.string "status", default: "draft"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.index ["newsletter_id", "slug"], name: "index_posts_on_newsletter_id_and_slug", unique: true
    t.index ["newsletter_id"], name: "index_posts_on_newsletter_id"
    t.index ["slug"], name: "index_posts_on_slug"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "subscribers", force: :cascade do |t|
    t.string "email"
    t.string "full_name"
    t.integer "newsletter_id", null: false
    t.string "created_via"
    t.datetime "verified_at"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "unsubscribed_at"
    t.string "unsubscribe_reason"
    t.text "notes"
    t.jsonb "analytics_data", default: {}
    t.string "labels", default: [], array: true
    t.integer "reminder_status", default: 0, null: false
    t.jsonb "additional_data", default: {}, null: false
    t.index "((additional_data ->> 'last_reminder_sent_at'::text))", name: "index_subscribers_on_reminder_sent_at"
    t.index ["additional_data"], name: "index_subscribers_on_additional_data", using: :gin
    t.index ["labels"], name: "index_subscribers_on_labels", using: :gin
    t.index ["newsletter_id"], name: "index_subscribers_on_newsletter_id"
    t.index ["reminder_status"], name: "index_subscribers_on_reminder_status"
    t.index ["status"], name: "index_subscribers_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", null: false
    t.string "password_digest"
    t.boolean "active"
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_superadmin", default: false
    t.jsonb "limits", default: {}
    t.jsonb "additional_data", default: {}
    t.datetime "verified_at"
    t.index ["is_superadmin"], name: "index_users_on_is_superadmin"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "connected_services", "users"
  add_foreign_key "domains", "newsletters"
  add_foreign_key "email_clicks", "emails"
  add_foreign_key "emails", "posts"
  add_foreign_key "emails", "subscribers"
  add_foreign_key "labels", "newsletters"
  add_foreign_key "newsletters", "users"
  add_foreign_key "posts", "newsletters"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscribers", "newsletters"
end
