class CheckoutController < ApplicationController
  def new
    if current_cart.empty?
      redirect_to cart_path, alert: "Your cart is empty. Please add products before checking out."
      return
    end

    @order = Order.new(
      fulfillment_type: current_cart.fulfillment_type,
      postcode: current_cart.postcode
    )
  end

  def create
    if current_cart.empty?
      redirect_to cart_path, alert: "Your cart is empty."
      return
    end

    fulfillment_type = params[:fulfillment_type] || "delivery"
    postcode = params[:postcode].to_s.strip

    current_cart.fulfillment_type = fulfillment_type
    current_cart.postcode = postcode

    @order = Order.new(
      customer_name: params[:customer_name],
      customer_email: params[:customer_email],
      customer_phone: params[:customer_phone],
      fulfillment_type: fulfillment_type,
      delivery_address: params[:delivery_address],
      suburb: params[:suburb],
      postcode: postcode,
      delivery_notes: params[:delivery_notes],
      status: "paid",
      payment_status: "completed",
      payment_method: params[:payment_method].presence || "Stripe (Card / Apple Pay / Afterpay)",
      stripe_payment_intent_id: "pi_stripe_#{SecureRandom.hex(8)}",
      carrier_name: fulfillment_type == "pickup" ? "Muchea Warehouse Drive-Thru Bay" : "Muchea Rural Fleet (Truck)",
      subtotal_cents: current_cart.subtotal_cents,
      delivery_fee_cents: current_cart.delivery_fee_cents,
      estimated_delivery_at: fulfillment_type == "pickup" ? 1.hour.from_now : 2.days.from_now
    )

    # 10% GST is included in Australian retail prices (1/11th of total)
    total_cents = @order.subtotal_cents + @order.delivery_fee_cents
    @order.gst_cents = (total_cents / 11.0).round
    @order.total_cents = total_cents

    if @order.save
      # Create line items
      current_cart.items.each do |item|
        @order.items.create!(
          product_variant: item[:variant],
          quantity: item[:quantity],
          unit_price_cents: item[:unit_price_cents],
          total_price_cents: item[:total_price_cents]
        )
      end

      # Deduct inventory & record logs
      @order.deduct_inventory!

      # Clear cart
      current_cart.clear

      redirect_to checkout_success_path(@order.order_number), notice: "Payment successful! Your order has been placed."
    else
      flash.now[:alert] = "Please complete all required fields."
      render :new, status: :unprocessable_entity
    end
  end

  def success
    @order = Order.find_by!(order_number: params[:order_number])
  end

  def invoice
    @order = Order.find_by!(order_number: params[:order_number])
    render layout: false
  end
end

