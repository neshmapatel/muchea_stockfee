class CartController < ApplicationController
  def show
    @delivery_zones = DeliveryZone.all
  end

  def add_item
    variant = ProductVariant.find(params[:variant_id])
    quantity = (params[:quantity] || 1).to_i

    current_cart.add_item(variant.id, quantity)
    flash[:notice] = "Added #{variant.product.name} (#{variant.name}) to cart."

    redirect_back fallback_location: cart_path
  end

  def update_item
    variant = ProductVariant.find(params[:variant_id])
    quantity = params[:quantity].to_i

    current_cart.update_item(variant.id, quantity)
    if params[:fulfillment_type].present?
      current_cart.fulfillment_type = params[:fulfillment_type]
    end
    if params[:postcode].present?
      current_cart.postcode = params[:postcode]
    end

    redirect_to cart_path
  end

  def remove_item
    current_cart.remove_item(params[:variant_id])
    flash[:notice] = "Item removed from your cart."
    redirect_to cart_path
  end

  def clear
    current_cart.clear
    flash[:notice] = "Your cart is now empty."
    redirect_to cart_path
  end
end

