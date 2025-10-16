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

ActiveRecord::Schema[8.0].define(version: 2025_10_13_185710) do
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

  create_table "admin_activities", force: :cascade do |t|
    t.bigint "admin_id", null: false
    t.string "action", null: false
    t.string "target_type"
    t.bigint "target_id"
    t.json "details", default: {}
    t.string "ip_address"
    t.string "user_agent", limit: 500
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_admin_activities_on_action"
    t.index ["admin_id", "created_at"], name: "index_admin_activities_on_admin_id_and_created_at"
    t.index ["admin_id"], name: "index_admin_activities_on_admin_id"
    t.index ["created_at"], name: "index_admin_activities_on_created_at"
    t.index ["target_type", "target_id"], name: "index_admin_activities_on_target_type_and_target_id"
  end

  create_table "blog_posts", force: :cascade do |t|
    t.string "title", null: false
    t.text "content", null: false
    t.text "excerpt"
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "views_count", default: 0, null: false
    t.boolean "archived", default: false, null: false
    t.boolean "featured"
    t.index ["archived"], name: "index_blog_posts_on_archived"
    t.index ["published", "published_at"], name: "index_blog_posts_on_published_and_published_at"
    t.index ["published"], name: "index_blog_posts_on_published"
    t.index ["published_at"], name: "index_blog_posts_on_published_at"
    t.index ["slug"], name: "index_blog_posts_on_slug", unique: true
    t.index ["user_id", "published"], name: "index_blog_posts_on_user_id_and_published"
    t.index ["user_id"], name: "index_blog_posts_on_user_id"
    t.index ["views_count"], name: "index_blog_posts_on_views_count"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "follower_id", null: false
    t.bigint "followee_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followee_id"], name: "index_follows_on_followee_id"
    t.index ["follower_id", "followee_id"], name: "index_follows_on_follower_id_and_followee_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "profile_views", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "visitor_ip"
    t.string "user_agent", limit: 500
    t.string "referrer", limit: 500
    t.datetime "visited_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "visited_at"], name: "index_profile_views_on_user_id_and_visited_at"
    t.index ["user_id"], name: "index_profile_views_on_user_id"
    t.index ["visited_at"], name: "index_profile_views_on_visited_at"
    t.index ["visitor_ip", "user_id", "visited_at"], name: "index_profile_views_on_visitor_ip_and_user_id_and_visited_at"
  end

  create_table "projects", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.text "technologies"
    t.string "github_url"
    t.string "demo_url"
    t.bigint "user_id", null: false
    t.integer "status"
    t.boolean "featured"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "live_url"
    t.string "source_code_url"
    t.integer "display_order"
    t.json "technologies_used", default: []
    t.index ["display_order"], name: "index_projects_on_display_order"
    t.index ["status"], name: "index_projects_on_status"
    t.index ["user_id", "display_order"], name: "index_projects_on_user_id_and_display_order"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "user_digest_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "frequency", default: 2, null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "last_sent_at"
    t.datetime "next_send_at"
    t.boolean "include_blog_posts", default: true, null: false
    t.boolean "include_projects", default: true, null: false
    t.boolean "include_profile_updates", default: false, null: false
    t.time "digest_time", default: "2000-01-01 08:00:00", null: false
    t.string "timezone", default: "UTC", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["frequency", "enabled", "next_send_at"], name: "idx_on_frequency_enabled_next_send_at_d7bc4c43b0"
    t.index ["next_send_at"], name: "index_user_digest_preferences_on_next_send_at"
    t.index ["user_id"], name: "index_user_digest_preferences_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "username", null: false
    t.string "full_name", limit: 100
    t.text "bio"
    t.string "github_url"
    t.string "linkedin_url"
    t.string "website_url"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "job_title"
    t.string "location"
    t.string "twitter_url"
    t.string "resume_url"
    t.string "contact_email"
    t.string "phone"
    t.text "headline"
    t.json "skills"
    t.integer "role", default: 0, null: false
    t.datetime "suspended_at"
    t.text "suspension_reason"
    t.datetime "last_login_at"
    t.text "admin_notes"
    t.integer "account_status", default: 0, null: false
    t.string "invitation_token"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "social_image_version", default: 1, null: false
    t.string "invitation_access_code"
    t.boolean "featured", default: false
    t.datetime "featured_at"
    t.boolean "open_for_work", default: false, null: false
    t.jsonb "work_preferences", default: {}, null: false
    t.index ["account_status"], name: "index_users_on_account_status"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["featured"], name: "index_users_on_featured"
    t.index ["invitation_accepted_at"], name: "index_users_on_invitation_accepted_at"
    t.index ["invitation_access_code"], name: "index_users_on_invitation_access_code"
    t.index ["invitation_sent_at"], name: "index_users_on_invitation_sent_at"
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["last_login_at"], name: "index_users_on_last_login_at"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["slug"], name: "index_users_on_slug", unique: true
    t.index ["suspended_at"], name: "index_users_on_suspended_at"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "visitor_page_views", force: :cascade do |t|
    t.bigint "visitor_id", null: false
    t.string "page_path", null: false
    t.string "page_title"
    t.string "referrer", limit: 500
    t.integer "time_on_page", default: 0
    t.datetime "viewed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_path", "viewed_at"], name: "index_visitor_page_views_on_page_path_and_viewed_at"
    t.index ["viewed_at"], name: "index_visitor_page_views_on_viewed_at"
    t.index ["visitor_id", "viewed_at"], name: "index_visitor_page_views_on_visitor_id_and_viewed_at"
    t.index ["visitor_id"], name: "index_visitor_page_views_on_visitor_id"
  end

  create_table "visitors", force: :cascade do |t|
    t.string "visitor_id", null: false
    t.string "ip_address"
    t.string "user_agent", limit: 500
    t.string "referrer", limit: 500
    t.string "country"
    t.string "city"
    t.datetime "first_visit_at", null: false
    t.datetime "last_visit_at", null: false
    t.integer "visit_count", default: 1
    t.integer "page_views", default: 0
    t.integer "total_time_on_site", default: 0
    t.boolean "converted", default: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_activity_at"
    t.index ["converted"], name: "index_visitors_on_converted"
    t.index ["first_visit_at"], name: "index_visitors_on_first_visit_at"
    t.index ["last_activity_at"], name: "index_visitors_on_last_activity_at"
    t.index ["last_visit_at"], name: "index_visitors_on_last_visit_at"
    t.index ["user_id"], name: "index_visitors_on_user_id"
    t.index ["visitor_id", "first_visit_at"], name: "index_visitors_on_visitor_id_and_first_visit_at"
    t.index ["visitor_id"], name: "index_visitors_on_visitor_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_activities", "users", column: "admin_id"
  add_foreign_key "blog_posts", "users"
  add_foreign_key "follows", "users", column: "followee_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "profile_views", "users"
  add_foreign_key "projects", "users"
  add_foreign_key "user_digest_preferences", "users"
  add_foreign_key "visitor_page_views", "visitors"
  add_foreign_key "visitors", "users"
end
