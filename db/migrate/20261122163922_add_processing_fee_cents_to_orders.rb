class AddProcessingFeeCentsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :processing_fee_cents, :integer, default: 0, null: false
  end
end
