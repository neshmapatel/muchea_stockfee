class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product_variant

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price_cents, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_total_price

  def unit_price_dollars
    unit_price_cents / 100.0
  end

  def total_price_dollars
    total_price_cents / 100.0
  end

  def formatted_total
    "AU$ #{format('%.2f', total_price_dollars)}"
  end

  private

  def set_total_price
    self.total_price_cents = (unit_price_cents || 0) * (quantity || 1)
  end
end

