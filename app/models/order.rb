class Order < ApplicationRecord
  has_many :items, class_name: "OrderItem", dependent: :destroy
  has_many :product_variants, through: :items

  validates :customer_name, presence: true
  validates :customer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :customer_phone, presence: true

  before_validation :generate_order_number, on: :create
  before_validation :generate_tracking_code, on: :create

  STATUSES = %w[paid packing dispatched delivered cancelled].freeze
  PAYMENT_STATUSES = %w[pending completed failed refunded].freeze
  FULFILLMENT_TYPES = %w[delivery pickup].freeze

  scope :recent, -> { order(created_at: :desc) }
  scope :actionable, -> { where(status: %w[paid packing dispatched]) }

  def total_dollars
    total_cents / 100.0
  end

  def formatted_total
    "AU$ #{format('%.2f', total_dollars)}"
  end

  def subtotal_dollars
    subtotal_cents / 100.0
  end

  def gst_dollars
    gst_cents / 100.0
  end

  def delivery_fee_dollars
    delivery_fee_cents / 100.0
  end

  def pickup?
    fulfillment_type == "pickup"
  end

  def delivery?
    fulfillment_type == "delivery"
  end

  def step_number
    case status
    when "paid" then 1
    when "packing" then 2
    when "dispatched" then 3
    when "delivered" then 4
    else 1
    end
  end

  def status_badge_class
    case status
    when "paid" then "bg-amber-100 text-amber-800 border-amber-300"
    when "packing" then "bg-blue-100 text-blue-800 border-blue-300"
    when "dispatched" then "bg-purple-100 text-purple-800 border-purple-300"
    when "delivered" then "bg-emerald-100 text-emerald-800 border-emerald-300"
    when "cancelled" then "bg-rose-100 text-rose-800 border-rose-300"
    else "bg-gray-100 text-gray-800"
    end
  end

  def status_label
    case status
    when "paid" then "Order Confirmed / Queued"
    when "packing" then "Packing at Muchea Warehouse"
    when "dispatched" then pickup? ? "Ready for Drive-Thru Pickup" : "Dispatched on Rural Delivery Truck"
    when "delivered" then pickup? ? "Collected by Customer" : "Delivered to Property / Shed"
    when "cancelled" then "Cancelled"
    else status.titleize
    end
  end

  def recalculate_totals!
    self.subtotal_cents = items.sum(&:total_price_cents)
    # Australian GST is 10% (1/11th of GST-inclusive price)
    self.gst_cents = ((subtotal_cents + delivery_fee_cents) / 11.0).round
    self.total_cents = subtotal_cents + delivery_fee_cents
    save!
  end

  def deduct_inventory!
    items.each do |item|
      item.product_variant.adjust_stock!(-item.quantity, reason: "Order ##{order_number}")
    end
  end

  private

  def generate_order_number
    return if order_number.present?
    loop do
      self.order_number = "MSH-#{Time.current.year}-#{SecureRandom.random_number(100_000..999_999)}"
      break unless Order.exists?(order_number: order_number)
    end
  end

  def generate_tracking_code
    return if tracking_code.present?
    loop do
      self.tracking_code = "WA#{SecureRandom.hex(4).upcase}AU"
      break unless Order.exists?(tracking_code: tracking_code)
    end
  end
end

