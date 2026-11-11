module Admin
  class OrdersController < BaseController
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
    end

    def show
      @order = Order.find(params[:id])
    end

    def advance_status
      @order = Order.find(params[:id])
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
      @order = Order.find(params[:id])
      if @order.update(order_params)
        redirect_to admin_order_path(@order), notice: "Order updated successfully."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def packing_slip
      @order = Order.find(params[:id])
      render layout: false
    end

    private

    def order_params
      params.require(:order).permit(:status, :carrier_name, :delivery_notes)
    end
  end
end

