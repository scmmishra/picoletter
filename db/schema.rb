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

ActiveRecord::Schema[8.1].define(version: 2026_03_01_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_hashcash_stamps", force: :cascade do |t|
    t.integer "bits", null: false
    t.jsonb "context"
    t.string "counter", null: false
    t.datetime "created_at", precision: nil, null: false
    t.date "date", null: false
    t.string "ext", null: false
    t.string "ip_address"
    t.string "rand", null: false
    t.string "request_path"
    t.string "resource", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "version", null: false
    t.index ["counter", "rand", "date", "resource", "bits", "version", "ext"], name: "index_active_hashcash_stamps_unique", unique: true
    t.index ["ip_address", "created_at"], name: "index_active_hashcash_stamps_on_ip_address_and_created_at", where: "(ip_address IS NOT NULL)"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "newsletter_id", null: false
    t.jsonb "permissions", default: ["subscription"], null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["newsletter_id"], name: "index_api_tokens_on_newsletter_id"
    t.index ["token"], name: "index_api_tokens_on_token", unique: true
  end

  create_table "connected_services", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["provider", "uid"], name: "index_connected_services_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_connected_services_on_user_id"
  end

  create_table "domains", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "dkim_status", default: "pending"
    t.boolean "dmarc_added", default: false
    t.string "error_message"
    t.string "name"
    t.bigint "newsletter_id", null: false
    t.text "public_key"
    t.string "region", default: "us-east-1"
    t.string "spf_status", default: "pending"
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_domains_on_name", unique: true
    t.index ["newsletter_id"], name: "index_domains_on_newsletter_id", unique: true
    t.index ["status", "dkim_status", "spf_status"], name: "index_domains_on_status_and_dkim_status_and_spf_status"
  end

  create_table "email_clicks", force: :cascade do |t|
    t.string "email_id", null: false
    t.string "link"
    t.bigint "post_id", null: false
    t.datetime "timestamp"
    t.index ["email_id"], name: "index_email_clicks_on_email_id"
    t.index ["post_id"], name: "index_email_clicks_on_post_id"
  end

  create_table "emails", id: :string, force: :cascade do |t|
    t.datetime "bounced_at"
    t.datetime "complained_at"
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.bigint "emailable_id"
    t.string "emailable_type"
    t.datetime "opened_at"
    t.string "status", default: "sent"
    t.integer "subscriber_id"
    t.datetime "updated_at", null: false
    t.index ["emailable_type", "emailable_id"], name: "index_emails_on_emailable_type_and_emailable_id"
    t.index ["subscriber_id"], name: "index_emails_on_subscriber_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.bigint "invited_by_id", null: false
    t.bigint "newsletter_id", null: false
    t.string "role", default: "editor", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["newsletter_id"], name: "index_invitations_on_newsletter_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "labels", force: :cascade do |t|
    t.string "color", default: "#6B7280", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "newsletter_id", null: false
    t.datetime "updated_at", null: false
    t.index ["newsletter_id", "name"], name: "index_labels_on_newsletter_id_and_name", unique: true
    t.index ["newsletter_id"], name: "index_labels_on_newsletter_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "newsletter_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["newsletter_id"], name: "index_memberships_on_newsletter_id"
    t.index ["role"], name: "index_memberships_on_role"
    t.index ["user_id", "newsletter_id"], name: "index_memberships_on_user_id_and_newsletter_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "newsletters", force: :cascade do |t|
    t.boolean "auto_reminder_enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.json "dns_records"
    t.string "domain_id"
    t.text "email_css"
    t.text "email_footer", default: ""
    t.boolean "enable_archive", default: true
    t.string "font_preference", default: "sans-serif"
    t.string "primary_color", default: "#09090b"
    t.string "reply_to"
    t.string "sending_address"
    t.string "sending_name"
    t.jsonb "settings", default: {}, null: false
    t.string "slug", null: false
    t.string "status"
    t.string "template"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "website"
    t.index ["settings"], name: "index_newsletters_on_settings", using: :gin
    t.index ["slug"], name: "index_newsletters_on_slug"
    t.index ["user_id"], name: "index_newsletters_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "newsletter_id", null: false
    t.datetime "published_at"
    t.datetime "scheduled_at"
    t.string "slug", null: false
    t.string "status", default: "draft"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["newsletter_id", "slug"], name: "index_posts_on_newsletter_id_and_slug", unique: true
    t.index ["newsletter_id"], name: "index_posts_on_newsletter_id"
    t.index ["slug"], name: "index_posts_on_slug"
    t.index ["status", "scheduled_at"], name: "index_posts_on_status_and_scheduled_at"
  end

  create_table "publishing_domains", force: :cascade do |t|
    t.string "cloudflare_id"
    t.string "cloudflare_ssl_status"
    t.datetime "created_at", null: false
    t.string "domain_type", default: "custom_cname", null: false
    t.string "hostname", null: false
    t.text "last_error"
    t.bigint "newsletter_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.text "verification_http_body"
    t.string "verification_http_path"
    t.string "verification_method"
    t.datetime "verified_at"
    t.index ["hostname"], name: "index_publishing_domains_on_hostname", unique: true
    t.index ["newsletter_id"], name: "index_publishing_domains_on_newsletter_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.string "token"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "subscriber_reminders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "kind", default: 0, null: false
    t.string "message_id"
    t.datetime "sent_at"
    t.bigint "subscriber_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_subscriber_reminders_on_message_id", unique: true
    t.index ["subscriber_id", "kind"], name: "index_subscriber_reminders_on_subscriber_id_and_kind"
    t.index ["subscriber_id"], name: "index_subscriber_reminders_on_subscriber_id"
  end

  create_table "subscribers", force: :cascade do |t|
    t.jsonb "analytics_data", default: {}
    t.datetime "created_at", null: false
    t.string "created_via"
    t.string "email"
    t.string "full_name"
    t.string "labels", default: [], array: true
    t.integer "newsletter_id", null: false
    t.text "notes"
    t.integer "status", default: 0
    t.string "unsubscribe_reason"
    t.datetime "unsubscribed_at"
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["labels"], name: "index_subscribers_on_labels", using: :gin
    t.index ["newsletter_id"], name: "index_subscribers_on_newsletter_id"
    t.index ["status"], name: "index_subscribers_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active"
    t.jsonb "additional_data", default: {}
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.boolean "is_superadmin", default: false
    t.jsonb "limits", default: {}
    t.string "name"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["is_superadmin"], name: "index_users_on_is_superadmin"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_tokens", "newsletters"
  add_foreign_key "connected_services", "users"
  add_foreign_key "domains", "newsletters"
  add_foreign_key "email_clicks", "emails"
  add_foreign_key "emails", "subscribers"
  add_foreign_key "invitations", "newsletters"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "labels", "newsletters"
  add_foreign_key "memberships", "newsletters"
  add_foreign_key "memberships", "users"
  add_foreign_key "newsletters", "users"
  add_foreign_key "posts", "newsletters"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscriber_reminders", "subscribers"
  add_foreign_key "subscribers", "newsletters"
end
