module Admin
  class ProductsController < BaseController
    def index
      @products = Product.includes(:category, :variants).order(name: :asc)

      if params[:category_id].present?
        @products = @products.where(category_id: params[:category_id])
      end

      if params[:q].present?
        @products = @products.search(params[:q])
      end
    end

    def show
      @product = Product.find(params[:id])
    end
  end
end

