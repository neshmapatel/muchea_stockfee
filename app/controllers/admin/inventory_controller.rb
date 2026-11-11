module Admin
  class InventoryController < BaseController
    def index
      @variants = ProductVariant.includes(:product).order("products.name ASC, product_variants.name ASC")

      if params[:filter] == "low_stock"
        @variants = @variants.where("stock_quantity <= low_stock_threshold")
      end

      if params[:category_id].present?
        @variants = @variants.joins(:product).where(products: { category_id: params[:category_id] })
      end

      if params[:q].present?
        term = "%#{params[:q].strip.downcase}%"
        @variants = @variants.joins(:product).where(
          "LOWER(products.name) LIKE ? OR LOWER(product_variants.sku) LIKE ? OR LOWER(product_variants.name) LIKE ?",
          term, term, term
        )
      end

      @categories = Category.ordered
      @recent_logs = InventoryLog.includes(product_variant: :product).limit(10)
    end

    def quick_adjust
      variant = ProductVariant.find(params[:variant_id])
      delta = params[:delta].to_i
      reason = params[:reason].presence || "Warehouse Adjustment"

      variant.adjust_stock!(delta, reason: reason)
      redirect_back fallback_location: admin_inventory_index_path, notice: "Stock for #{variant.product.name} (#{variant.name}) updated to #{variant.stock_quantity}."
    end
  end
end

