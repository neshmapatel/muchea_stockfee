class DeliveryZone < ApplicationRecord
  validates :name, presence: true
  validates :postcodes, presence: true

  def covers_postcode?(pc)
    return false if pc.blank?
    postcodes.split(",").map(&:strip).include?(pc.to_s.strip)
  end

  def fee_dollars
    fee_cents / 100.0
  end

  def formatted_fee
    if fee_cents.zero?
      "FREE"
    else
      "AU$ #{format('%.2f', fee_dollars)}"
    end
  end

  def self.zone_for(postcode)
    all.find { |z| z.covers_postcode?(postcode) }
  end
end

