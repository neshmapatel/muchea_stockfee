class StorefrontController < ApplicationController
  def index
    @live_categories = Category.live
    @coming_soon_categories = Category.coming_soon
    @featured_feed_products = Product.live.featured.includes(:category, :variants).limit(8)
    @coming_soon_hardware_products = Product.coming_soon.includes(:category, :variants).limit(4)
    @delivery_zones = DeliveryZone.all
    @recent_deliveries_count = Order.where("created_at > ?", 7.days.ago).count + 24
  end

  def delivery_schedule
    @delivery_zones = DeliveryZone.all
  end

  def drive_thru_pickup
  end

  def about
  end

  def contact
  end
end
