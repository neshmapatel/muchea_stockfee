module Admin
  class DashboardController < BaseController
    def index
      @recent_orders = Order.recent.limit(10)
      @low_stock_variants = ProductVariant.low_stock.includes(:product).limit(8)
      @total_revenue_cents = Order.sum(:total_cents)
      @orders_today_count = Order.where("created_at >= ?", Time.current.beginning_of_day).count
      @active_fulfillments_count = Order.where(status: %w[paid packing dispatched]).count
      @total_products_count = Product.count
      @total_stock_units = ProductVariant.sum(:stock_quantity)
    end
  end
end

