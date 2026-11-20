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
    price_cents.present? ? price_cents / 100.0 : nil
  end

  def price_dollars=(val)
    self.price_cents = (val.to_f * 100).round if val.present?
  end

  def compare_at_price_dollars
    compare_at_price_cents.present? ? compare_at_price_cents / 100.0 : nil
  end

  def compare_at_price_dollars=(val)
    self.compare_at_price_cents = val.present? ? (val.to_f * 100).round : nil
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

  def adjust_stock!(delta, reason: "Manual Adjustment", admin_user: nil)
    target_qty = [ stock_quantity + delta, 0 ].max
    apply_stock_change!(target_qty, delta, reason, admin_user)
  end

  def set_stock!(new_qty, reason: "Stocktake Count", admin_user: nil)
    target_qty = [ new_qty.to_i, 0 ].max
    delta = target_qty - stock_quantity
    apply_stock_change!(target_qty, delta, reason, admin_user)
  end

  private

  def apply_stock_change!(target_qty, delta, reason, admin_user)
    transaction do
      update!(stock_quantity: target_qty)
      inventory_logs.create!(
        change_amount: delta,
        new_quantity: target_qty,
        reason: reason,
        admin_user: admin_user
      )
    end
  end
end
