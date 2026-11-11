class Cart
  attr_reader :session

  def initialize(session)
    @session = session
    @session[:cart] ||= {}
    @session[:fulfillment_type] ||= "delivery"
    @session[:postcode] ||= ""
  end

  def items
    raw_cart = @session[:cart] || {}
    variants = ProductVariant.includes(:product).where(id: raw_cart.keys)

    variants.map do |variant|
      qty = raw_cart[variant.id.to_s].to_i
      next if qty <= 0

      {
        variant: variant,
        product: variant.product,
        quantity: qty,
        unit_price_cents: variant.price_cents,
        total_price_cents: variant.price_cents * qty,
        weight_kg: (variant.weight_kg || 20.0) * qty
      }
    end.compact
  end

  def item_count
    (@session[:cart] || {}).values.sum(&:to_i)
  end

  def empty?
    item_count.zero?
  end

  def subtotal_cents
    items.sum { |i| i[:total_price_cents] }
  end

  def total_weight_kg
    items.sum { |i| i[:weight_kg] }
  end

  def fulfillment_type
    @session[:fulfillment_type] || "delivery"
  end

  def fulfillment_type=(type)
    @session[:fulfillment_type] = type
  end

  def postcode
    @session[:postcode]
  end

  def postcode=(pc)
    @session[:postcode] = pc.to_s.strip
  end

  def delivery_zone
    return nil if fulfillment_type == "pickup" || postcode.blank?
    DeliveryZone.zone_for(postcode)
  end

  def delivery_fee_cents
    return 0 if fulfillment_type == "pickup"

    zone = delivery_zone
    if zone
      if zone.free_threshold_cents.present? && subtotal_cents >= zone.free_threshold_cents
        0
      else
        zone.fee_cents
      end
    else
      # Default WA regional standard delivery if postcode not specifically mapped
      postcode.present? ? 3500 : 2500
    end
  end

  # Australian GST is 10%, included in prices (1/11th of total inc GST)
  def gst_cents
    ((subtotal_cents + delivery_fee_cents) / 11.0).round
  end

  def total_cents
    subtotal_cents + delivery_fee_cents
  end

  def add_item(variant_id, qty = 1)
    vid = variant_id.to_s
    current_qty = (@session[:cart][vid] || 0).to_i
    @session[:cart][vid] = current_qty + qty.to_i
  end

  def update_item(variant_id, qty)
    vid = variant_id.to_s
    new_qty = qty.to_i
    if new_qty > 0
      @session[:cart][vid] = new_qty
    else
      @session[:cart].delete(vid)
    end
  end

  def remove_item(variant_id)
    @session[:cart].delete(variant_id.to_s)
  end

  def clear
    @session[:cart] = {}
  end
end

