class Product < ApplicationRecord
  belongs_to :category
  has_many :variants, class_name: "ProductVariant", dependent: :destroy
  has_many :order_items, through: :variants

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  scope :active, -> { where(active: true) }
  scope :featured, -> { active.where(featured: true) }
  scope :by_brand, ->(brand) { where(brand: brand) if brand.present? }
  scope :search, ->(term) {
    if term.present?
      wildcard = "%#{term.strip.downcase}%"
      where("LOWER(name) LIKE ? OR LOWER(brand) LIKE ? OR LOWER(short_description) LIKE ?", wildcard, wildcard, wildcard)
    end
  }

  def to_param
    slug
  end

  def default_variant
    variants.find_by(is_default: true) || variants.order(price_cents: :asc).first
  end

  def min_price_cents
    variants.minimum(:price_cents) || 0
  end

  def max_price_cents
    variants.maximum(:price_cents) || 0
  end

  def min_price_dollars
    format("%.2f", min_price_cents / 100.0)
  end

  def price_display
    if variants.count > 1 && min_price_cents != max_price_cents
      "From AU$ #{format('%.2f', min_price_cents / 100.0)} inc. GST"
    elsif default_variant
      "AU$ #{format('%.2f', default_variant.price_cents / 100.0)} inc. GST"
    else
      "POA"
    end
  end

  def in_stock?
    variants.any?(&:in_stock?)
  end

  def total_stock
    variants.sum(:stock_quantity)
  end

  def low_stock?
    variants.any?(&:low_stock?)
  end

  def schema_json_ld
    {
      "@context": "https://schema.org/",
      "@type": "Product",
      "name": name,
      "image": [hero_image_url.presence || "/images/muchea_logo.jpg"],
      "description": short_description,
      "brand": {
        "@type": "Brand",
        "name": brand.presence || "Muchea Stockfeed & Hardware"
      },
      "offers": {
        "@type": "AggregateOffer",
        "priceCurrency": "AUD",
        "lowPrice": format("%.2f", min_price_cents / 100.0),
        "highPrice": format("%.2f", max_price_cents / 100.0),
        "priceValidUntil": "2027-12-31",
        "availability": in_stock? ? "https://schema.org/InStock" : "https://schema.org/OutOfStock",
        "itemCondition": "https://schema.org/NewCondition"
      }
    }
  end

  private

  def generate_slug
    self.slug = name.parameterize if slug.blank? && name.present?
  end
end

