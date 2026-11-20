module Admin
  class ProductsController < BaseController
    before_action -> { authorize_any!(:manage_products, :view_inventory, :manage_inventory) }, only: [ :index, :show ]
    before_action -> { authorize!(:manage_products) }, only: [ :new, :create, :edit, :update, :destroy ]
    before_action :set_product, only: [ :show, :edit, :update, :destroy ]

    def index
      @products = Product.includes(:category, :variants).order(name: :asc)

      if params[:category_id].present?
        @products = @products.where(category_id: params[:category_id])
      end

      if params[:q].present?
        @products = @products.search(params[:q])
      end

      @categories = Category.ordered
      @category_product_counts = Product.group(:category_id).count
      @total_products_count = @category_product_counts.values.sum
    end

    def show
    end

    def new
      @product = Product.new
      @product.variants.build(
        name: "20kg Bag",
        weight_kg: 20.0,
        is_default: true,
        stock_quantity: 20,
        low_stock_threshold: 5
      )
      @categories = Category.ordered
    end

    def create
      @product = Product.new(product_params)

      if @product.save
        redirect_to admin_products_path, notice: "Product '#{@product.name}' was successfully created with #{@product.variants.count} variant(s)."
      else
        @categories = Category.ordered
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @categories = Category.ordered
      if @product.variants.empty?
        @product.variants.build(name: "Standard", is_default: true, stock_quantity: 0)
      end
    end

    def update
      if @product.update(product_params)
        redirect_to admin_products_path, notice: "Product '#{@product.name}' was successfully updated."
      else
        @categories = Category.ordered
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      product_name = @product.name
      @product.destroy
      redirect_to admin_products_path, notice: "Product '#{product_name}' was removed from catalog."
    end

    private

    def set_product
      @product = Product.includes(:category, :variants).find_by(slug: params[:id]) ||
                 Product.includes(:category, :variants).find_by(id: params[:id])
      unless @product
        redirect_to admin_products_path, alert: "Product not found."
      end
    end

    def product_params
      params.require(:product).permit(
        :name,
        :category_id,
        :brand,
        :short_description,
        :full_description,
        :specifications,
        :hero_image_url,
        :featured,
        :active,
        variants_attributes: [
          :id,
          :name,
          :sku,
          :price_dollars,
          :compare_at_price_dollars,
          :weight_kg,
          :stock_quantity,
          :low_stock_threshold,
          :is_default,
          :_destroy
        ]
      )
    end
  end
end
