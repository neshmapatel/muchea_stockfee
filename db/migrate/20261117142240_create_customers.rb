class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone, null: false
      t.string :business_name
      t.string :abn
      t.string :property_address
      t.string :suburb
      t.string :postcode
      t.string :state, default: "WA"
      t.string :primary_interest
      t.text :notes
      t.string :password_digest, null: false

      # Membership status: 'pending', 'approved', 'rejected'
      t.string :status, default: "pending", null: false

      t.datetime :approved_at
      t.references :approved_by, foreign_key: { to_table: :admin_users }
      t.text :rejection_reason

      t.timestamps
    end

    add_index :customers, :email, unique: true
    add_index :customers, :status
  end
end
