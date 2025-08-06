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

ActiveRecord::Schema[7.1].define(version: 2024_08_06_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # When using PostgreSQL, you can use native enum types
  # Create enum types (PostgreSQL specific)
  create_enum :user_status, ["active", "inactive", "suspended", "pending_verification", "deleted"]
  create_enum :order_status, ["pending", "processing", "shipped", "delivered", "cancelled", "refunded"]
  create_enum :payment_method, ["credit_card", "debit_card", "paypal", "bank_transfer", "cash_on_delivery", "cryptocurrency"]
  create_enum :priority_level, ["low", "medium", "high", "urgent", "critical"]
  create_enum :ticket_severity, ["trivial", "minor", "major", "critical", "blocker"]
  create_enum :product_category, ["electronics", "clothing", "books", "food", "home_garden", "sports", "toys", "health_beauty"]
  create_enum :notification_type, ["email", "sms", "push", "in_app", "webhook"]

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "username", null: false
    t.string "encrypted_password"
    # Using integer for enum (Rails convention)
    t.integer "status", default: 0, null: false
    # Or using PostgreSQL enum type
    # t.enum "status", enum_type: :user_status, default: "pending_verification", null: false
    t.integer "role", default: 0, null: false
    t.string "first_name"
    t.string "last_name"
    t.date "birth_date"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.integer "sign_in_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
    t.index ["status"], name: "index_users_on_status"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "phone_number"
    t.text "bio"
    t.string "avatar_url"
    t.string "location"
    t.string "website"
    t.jsonb "social_links", default: {}
    t.jsonb "preferences", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    # Using integer for enum
    t.integer "category", null: false
    # Or using PostgreSQL enum
    # t.enum "category", enum_type: :product_category, null: false
    t.integer "stock_quantity", default: 0
    t.string "sku", null: false
    t.boolean "active", default: true
    t.string "image_url"
    t.jsonb "attributes", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_products_on_category"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["active"], name: "index_products_on_active"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "order_number", null: false
    # Using integer for enums
    t.integer "status", default: 0, null: false
    t.integer "payment_method", null: false
    # Or using PostgreSQL enums
    # t.enum "status", enum_type: :order_status, default: "pending", null: false
    # t.enum "payment_method", enum_type: :payment_method, null: false
    t.decimal "subtotal", precision: 10, scale: 2
    t.decimal "tax_amount", precision: 10, scale: 2
    t.decimal "shipping_amount", precision: 10, scale: 2
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.text "shipping_address"
    t.text "billing_address"
    t.text "notes"
    t.datetime "shipped_at"
    t.datetime "delivered_at"
    t.datetime "cancelled_at"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["status"], name: "index_orders_on_status"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "subtotal", precision: 10, scale: 2, null: false
    t.jsonb "customizations", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "support_tickets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ticket_number", null: false
    t.string "title", null: false
    t.text "description", null: false
    # Using integer for enums
    t.integer "priority", default: 1, null: false
    t.integer "severity", default: 1, null: false
    t.integer "status", default: 0, null: false
    # Or using PostgreSQL enums
    # t.enum "priority", enum_type: :priority_level, default: "medium", null: false
    # t.enum "severity", enum_type: :ticket_severity, default: "minor", null: false
    t.bigint "assigned_to_id"
    t.datetime "resolved_at"
    t.text "resolution_notes"
    t.jsonb "tags", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_support_tickets_on_user_id"
    t.index ["assigned_to_id"], name: "index_support_tickets_on_assigned_to_id"
    t.index ["ticket_number"], name: "index_support_tickets_on_ticket_number", unique: true
    t.index ["priority"], name: "index_support_tickets_on_priority"
    t.index ["severity"], name: "index_support_tickets_on_severity"
    t.index ["status"], name: "index_support_tickets_on_status"
  end

  create_table "comments", force: :cascade do |t|
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.boolean "internal", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    # Using integer array for multiple enum values
    t.integer "enabled_types", array: true, default: [0, 3]
    # Or using PostgreSQL enum array
    # t.enum "enabled_types", array: true, enum_type: :notification_type, default: ["email", "in_app"]
    t.integer "email_frequency", default: 0
    t.time "quiet_hours_start"
    t.time "quiet_hours_end"
    t.integer "quiet_days", array: true, default: []
    t.boolean "marketing_emails", default: true
    t.boolean "product_updates", default: true
    t.boolean "newsletter", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notification_preferences_on_user_id", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "payment_method", null: false
    t.integer "status", default: 0, null: false
    t.string "transaction_id"
    t.string "gateway_response"
    t.jsonb "gateway_data", default: {}
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_payments_on_order_id", unique: true
    t.index ["transaction_id"], name: "index_payments_on_transaction_id", unique: true
    t.index ["status"], name: "index_payments_on_status"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "user_id", null: false
    t.integer "rating", null: false
    t.string "title"
    t.text "comment"
    t.boolean "verified_purchase", default: false
    t.integer "helpful_count", default: 0
    t.jsonb "images", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_reviews_on_product_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
    t.index ["rating"], name: "index_reviews_on_rating"
    t.index ["product_id", "user_id"], name: "index_reviews_on_product_id_and_user_id", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "auditable_type", null: false
    t.bigint "auditable_id", null: false
    t.string "action", null: false
    t.bigint "user_id"
    t.jsonb "changes", default: {}
    t.inet "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
    t.index ["action"], name: "index_audit_logs_on_action"
  end

  # Active Storage tables (for file uploads)
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

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  # Foreign Key Constraints
  add_foreign_key "profiles", "users"
  add_foreign_key "orders", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "support_tickets", "users"
  add_foreign_key "support_tickets", "users", column: "assigned_to_id"
  add_foreign_key "comments", "users"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "payments", "orders"
  add_foreign_key "reviews", "products"
  add_foreign_key "reviews", "users"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end