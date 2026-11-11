class StorefrontController < ApplicationController
  def index
    @featured_products = Product.featured.includes(:category, :variants).limit(8)
    @categories = Category.ordered
    @delivery_zones = DeliveryZone.all
    @recent_deliveries_count = Order.where("created_at > ?", 7.days.ago).count + 18
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

