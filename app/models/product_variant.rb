class ProductVariant < ApplicationRecord
  belongs_to :product
  has_many :order_items, dependent: :restrict_with_error
  has_many :inventory_logs, dependent: :destroy

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }

  scope :in_stock, -> { where("stock_quantity > 0") }
  scope :low_stock, -> { where("stock_quantity <= low_stock_threshold") }

  def price_dollars
    price_cents / 100.0
  end

  def formatted_price
    "AU$ #{format('%.2f', price_dollars)}"
  end

  def formatted_price_with_gst
    "#{formatted_price} inc. GST"
  end

  def in_stock?
    stock_quantity > 0
  end

  def low_stock?
    stock_quantity <= low_stock_threshold
  end

  def adjust_stock!(delta, reason: "Manual Adjustment")
    transaction do
      new_qty = [stock_quantity + delta, 0].max
      update!(stock_quantity: new_qty)
      inventory_logs.create!(
        change_amount: delta,
        new_quantity: new_qty,
        reason: reason
      )
    end
  end
end

