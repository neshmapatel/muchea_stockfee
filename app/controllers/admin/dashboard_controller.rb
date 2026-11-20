module Admin
  class DashboardController < BaseController
    before_action -> { authorize!(:view_dashboard) }

    def index
      if can_any?(:view_orders, :manage_orders)
        @recent_orders = Order.recent.limit(10)
        @orders_today_count = Order.where("created_at >= ?", Time.current.beginning_of_day).count
        @active_fulfillments_count = Order.where(status: %w[paid packing dispatched]).count
      else
        @recent_orders = Order.none
      end

      if can?(:view_financials)
        @total_revenue_cents = Order.sum(:total_cents)
      end

      if can_any?(:view_inventory, :manage_inventory, :manage_products)
        @low_stock_variants = ProductVariant.low_stock.includes(:product).limit(8)
        @total_products_count = Product.count
        @total_stock_units = ProductVariant.sum(:stock_quantity)
      else
        @low_stock_variants = ProductVariant.none
      end

      if can_any?(:manage_admin_users, :manage_super_admins)
        @active_staff_count = AdminUser.active.count
        @roles_count = Role.count
      end
    end
  end
end
