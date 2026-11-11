class InventoryLog < ApplicationRecord
  belongs_to :product_variant

  validates :change_amount, presence: true
  validates :new_quantity, presence: true

  default_scope { order(created_at: :desc) }
end

