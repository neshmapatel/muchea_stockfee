class TrackingController < ApplicationController
  def index
    if params[:query].present?
      q = params[:query].to_s.strip
      order = Order.find_by("LOWER(order_number) = ? OR LOWER(tracking_code) = ?", q.downcase, q.downcase)
      if order
        redirect_to tracking_path(order.tracking_code)
      else
        flash.now[:alert] = "No order found matching '#{q}'. Please check your order confirmation email or invoice."
      end
    end
  end

  def show
    code = params[:code].to_s.strip
    @order = Order.find_by("LOWER(tracking_code) = ? OR LOWER(order_number) = ?", code.downcase, code.downcase)

    unless @order
      redirect_to tracking_lookup_path, alert: "Tracking code '#{code}' not found."
    end
  end
end

