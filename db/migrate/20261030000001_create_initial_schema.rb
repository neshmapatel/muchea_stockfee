class CreateInitialSchema < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :department, null: false
      t.text :description
      t.string :icon
      t.integer :display_order, default: 0
      t.timestamps
    end
    add_index :categories, :slug, unique: true

    create_table :products do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :brand
      t.text :short_description
      t.text :full_description
      t.text :specifications
      t.boolean :featured, default: false
      t.boolean :active, default: true
      t.string :hero_image_url
      t.timestamps
    end
    add_index :products, :slug, unique: true
    add_index :products, :featured
    add_index :products, :brand

    create_table :product_variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.string :sku, null: false
      t.integer :price_cents, null: false
      t.integer :compare_at_price_cents
      t.decimal :weight_kg, precision: 8, scale: 2, default: 20.0
      t.integer :stock_quantity, default: 0
      t.integer :low_stock_threshold, default: 5
      t.boolean :is_default, default: false
      t.timestamps
    end
    add_index :product_variants, :sku, unique: true

    create_table :orders do |t|
      t.string :order_number, null: false
      t.string :customer_name, null: false
      t.string :customer_email, null: false
      t.string :customer_phone, null: false
      t.string :fulfillment_type, default: "delivery"
      t.text :delivery_address
      t.string :suburb
      t.string :postcode
      t.text :delivery_notes
      t.string :status, default: "paid"
      t.string :payment_status, default: "completed"
      t.string :payment_method, default: "Credit Card"
      t.string :stripe_payment_intent_id
      t.string :tracking_code
      t.string :carrier_name, default: "Muchea Rural Fleet"
      t.integer :subtotal_cents, default: 0
      t.integer :gst_cents, default: 0
      t.integer :delivery_fee_cents, default: 0
      t.integer :total_cents, default: 0
      t.datetime :estimated_delivery_at
      t.datetime :dispatched_at
      t.datetime :delivered_at
      t.timestamps
    end
    add_index :orders, :order_number, unique: true
    add_index :orders, :tracking_code
    add_index :orders, :status

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product_variant, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.integer :unit_price_cents, null: false
      t.integer :total_price_cents, null: false
      t.timestamps
    end

    create_table :inventory_logs do |t|
      t.references :product_variant, null: false, foreign_key: true
      t.integer :change_amount, null: false
      t.integer :new_quantity, null: false
      t.string :reason
      t.timestamps
    end

    create_table :delivery_zones do |t|
      t.string :name, null: false
      t.text :postcodes, null: false
      t.integer :fee_cents, default: 0
      t.integer :free_threshold_cents
      t.string :scheduled_days
      t.text :description
      t.timestamps
    end
  end
end

