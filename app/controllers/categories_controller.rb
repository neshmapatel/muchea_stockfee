class CategoriesController < ApplicationController
  def show
    @category = Category.find_by!(slug: params[:slug])
    @products = @category.products.active.includes(:variants)

    if params[:brand].present?
      @products = @products.where(brand: params[:brand])
    end

    if params[:sort] == "price_asc"
      @products = @products.joins(:variants).group("products.id").order("MIN(product_variants.price_cents) ASC")
    elsif params[:sort] == "price_desc"
      @products = @products.joins(:variants).group("products.id").order("MAX(product_variants.price_cents) DESC")
    else
      @products = @products.order(featured: :desc, name: :asc)
    end

    @available_brands = @category.products.active.pluck(:brand).compact.uniq
    @other_categories = Category.where.not(id: @category.id).ordered
  end
end

