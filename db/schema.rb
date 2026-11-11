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

ActiveRecord::Schema[8.1].define(version: 2026_10_30_000001) do
  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "department", null: false
    t.text "description"
    t.string "icon"
    t.integer "display_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "delivery_zones", force: :cascade do |t|
    t.string "name", null: false
    t.text "postcodes", null: false
    t.integer "fee_cents", default: 0
    t.integer "free_threshold_cents"
    t.string "scheduled_days"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inventory_logs", force: :cascade do |t|
    t.integer "product_variant_id", null: false
    t.integer "change_amount", null: false
    t.integer "new_quantity", null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_variant_id"], name: "index_inventory_logs_on_product_variant_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_variant_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price_cents", null: false
    t.integer "total_price_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_variant_id"], name: "index_order_items_on_product_variant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "order_number", null: false
    t.string "customer_name", null: false
    t.string "customer_email", null: false
    t.string "customer_phone", null: false
    t.string "fulfillment_type", default: "delivery"
    t.text "delivery_address"
    t.string "suburb"
    t.string "postcode"
    t.text "delivery_notes"
    t.string "status", default: "paid"
    t.string "payment_status", default: "completed"
    t.string "payment_method", default: "Credit Card"
    t.string "stripe_payment_intent_id"
    t.string "tracking_code"
    t.string "carrier_name", default: "Muchea Rural Fleet"
    t.integer "subtotal_cents", default: 0
    t.integer "gst_cents", default: 0
    t.integer "delivery_fee_cents", default: 0
    t.integer "total_cents", default: 0
    t.datetime "estimated_delivery_at"
    t.datetime "dispatched_at"
    t.datetime "delivered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["status"], name: "index_orders_on_status"
    t.index ["tracking_code"], name: "index_orders_on_tracking_code"
  end

  create_table "product_variants", force: :cascade do |t|
    t.integer "product_id", null: false
    t.string "name", null: false
    t.string "sku", null: false
    t.integer "price_cents", null: false
    t.integer "compare_at_price_cents"
    t.decimal "weight_kg", precision: 8, scale: 2, default: "20.0"
    t.integer "stock_quantity", default: 0
    t.integer "low_stock_threshold", default: 5
    t.boolean "is_default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_variants_on_product_id"
    t.index ["sku"], name: "index_product_variants_on_sku", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.integer "category_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "brand"
    t.text "short_description"
    t.text "full_description"
    t.text "specifications"
    t.boolean "featured", default: false
    t.boolean "active", default: true
    t.string "hero_image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand"], name: "index_products_on_brand"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["slug"], name: "index_products_on_slug", unique: true
  end

  add_foreign_key "inventory_logs", "product_variants"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "product_variants"
  add_foreign_key "product_variants", "products"
  add_foreign_key "products", "categories"
end
