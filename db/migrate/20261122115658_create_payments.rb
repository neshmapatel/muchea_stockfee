class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.string :stripe_payment_intent_id
      t.string :stripe_session_id
      t.integer :amount_cents, default: 0, null: false
      t.string :currency, default: "aud", null: false
      t.string :status, default: "pending", null: false
      t.string :payment_method, default: "stripe"
      t.string :stripe_receipt_url
      t.string :customer_email
      t.text :error_message

      t.timestamps
    end
    add_index :payments, :stripe_payment_intent_id
    add_index :payments, :stripe_session_id
  end
end
