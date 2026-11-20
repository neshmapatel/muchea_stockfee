module Admin
  class OrdersController < BaseController
    before_action -> { authorize_any!(:view_orders, :manage_orders) }, only: [ :index, :show, :packing_slip ]
    before_action -> { authorize!(:manage_orders) }, only: [ :advance_status, :update ]
    before_action :set_order, only: [ :show, :advance_status, :update, :packing_slip ]

    def index
      @orders = Order.recent

      if params[:status].present?
        @orders = @orders.where(status: params[:status])
      end

      if params[:q].present?
        term = "%#{params[:q].strip.downcase}%"
        @orders = @orders.where(
          "LOWER(order_number) LIKE ? OR LOWER(customer_name) LIKE ? OR LOWER(customer_email) LIKE ? OR LOWER(tracking_code) LIKE ?",
          term, term, term, term
        )
      end

      order_ids = @orders.pluck(:id)
      @item_quantities_by_order = if order_ids.any?
        OrderItem.where(order_id: order_ids).group(:order_id).sum(:quantity)
      else
        {}
      end
    end

    def show
    end

    def advance_status
      next_status = case @order.status
      when "paid" then "packing"
      when "packing" then "dispatched"
      when "dispatched" then "delivered"
      else @order.status
      end

      updates = { status: next_status }
      updates[:dispatched_at] = Time.current if next_status == "dispatched"
      updates[:delivered_at] = Time.current if next_status == "delivered"

      @order.update!(updates)
      redirect_back fallback_location: admin_order_path(@order), notice: "Order ##{@order.order_number} status updated to #{next_status.titleize}."
    end

    def update
      if @order.update(order_params)
        redirect_to admin_order_path(@order), notice: "Order updated successfully."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def packing_slip
      render layout: false
    end

    private

    def set_order
      @order = Order.includes(items: { product_variant: :product }).find(params[:id])
    end

    def order_params
      params.require(:order).permit(:status, :carrier_name, :delivery_notes)
    end
  end
end
