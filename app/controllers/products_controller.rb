class ProductsController < ApplicationController
  def index
    @categories = Category.ordered
    @products = Product.active.includes(:category, :variants)

    if params[:q].present?
      @products = @products.search(params[:q])
    end

    if params[:category].present?
      cat = Category.find_by(slug: params[:category])
      @products = @products.where(category: cat) if cat
    end

    if params[:department].present?
      @products = @products.joins(:category).where(categories: { department: params[:department] })
    end

    @total_count = @products.count
    @products = @products.order(featured: :desc, name: :asc)
  end

  def show
    @product = Product.active.find_by!(slug: params[:slug])
    @variants = @product.variants.order(price_cents: :asc)
    @selected_variant = if params[:variant_id].present?
                          @variants.find_by(id: params[:variant_id]) || @product.default_variant
                        else
                          @product.default_variant
                        end
    @related_products = @product.category.products.active.where.not(id: @product.id).limit(4)
    @delivery_zones = DeliveryZone.all
  end
end

