require "csv"

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
      @recent_logs = InventoryLog.includes(product_variant: :product).order(created_at: :desc).limit(10)
    end

    def quick_adjust
      variant = ProductVariant.find(params[:variant_id])
      reason = params[:reason].presence || "Warehouse Adjustment"

      if params[:exact_quantity].present?
        target = [params[:exact_quantity].to_i, 0].max
        variant.set_stock!(target, reason: reason)
        redirect_back fallback_location: admin_inventory_index_path, notice: "Stock for #{variant.product.name} (#{variant.name}) set to #{variant.stock_quantity}."
      else
        delta = params[:delta].to_i
        variant.adjust_stock!(delta, reason: reason)
        redirect_back fallback_location: admin_inventory_index_path, notice: "Stock for #{variant.product.name} (#{variant.name}) updated to #{variant.stock_quantity}."
      end
    end

    # Fast Barcode Scanner Mode for Handheld Scanner Guns & Counter Tablets
    def scanner
      @recent_scans = InventoryLog.includes(product_variant: :product)
                                  .where("reason LIKE ?", "%Barcode Scanner%")
                                  .order(created_at: :desc)
                                  .limit(8)

      if flash[:scanned_variant_id].present?
        @last_scanned = ProductVariant.includes(:product).find_by(id: flash[:scanned_variant_id])
      end
    end

    def scan_adjust
      code = params[:barcode].to_s.strip
      qty = [params[:quantity].to_i, 1].max
      mode = params[:mode].presence || "add"

      if code.blank?
        redirect_to scanner_admin_inventory_index_path, alert: "Please scan a barcode or enter a SKU."
        return
      end

      variant = ProductVariant.where("UPPER(sku) = ?", code.upcase).first
      variant ||= ProductVariant.joins(:product).where("UPPER(product_variants.sku) = ? OR UPPER(products.name) LIKE ?", code.upcase, "%#{code.upcase}%").first

      if variant
        old_qty = variant.stock_quantity

        case mode
        when "set"
          variant.set_stock!(qty, reason: "Barcode Scanner Stocktake Count (=#{qty})")
        when "deduct"
          variant.adjust_stock!(-qty, reason: "Barcode Scanner Manual Deduct (-#{qty})")
        else # "add"
          variant.adjust_stock!(qty, reason: "Barcode Scanner Restock (+#{qty})")
        end

        flash[:scanned_variant_id] = variant.id
        flash[:scanned_qty] = qty
        flash[:notice] = "✅ BEEP! Scanned: #{variant.product.name} (#{variant.name}) — SKU: #{variant.sku} | Stock: #{old_qty} ➜ #{variant.stock_quantity}"
      else
        flash[:alert] = "❌ No product found for Barcode / SKU '#{code}'. Please verify the barcode or add it via Products Catalog."
      end

      redirect_to scanner_admin_inventory_index_path
    end

    # Bulk CSV / Excel Import Interface
    def import
    end

    def process_import
      file = params[:file]
      if file.blank?
        redirect_to import_admin_inventory_index_path, alert: "Please select a .csv file to upload."
        return
      end

      updated_count = 0
      created_count = 0
      errors = []
      row_idx = 1

      begin
        CSV.foreach(file.path, headers: true, header_converters: :symbol) do |row|
          row_idx += 1
          sku = row[:sku].to_s.strip.upcase
          next if sku.blank?

          variant = ProductVariant.where("UPPER(sku) = ?", sku).first

          if variant
            if row[:stock_quantity].present?
              new_stock = [row[:stock_quantity].to_i, 0].max
              variant.set_stock!(new_stock, reason: "Bulk CSV Stocktake Import")
              updated_count += 1
            elsif row[:quantity].present? || row[:add_quantity].present?
              add_qty = (row[:quantity] || row[:add_quantity]).to_i
              variant.adjust_stock!(add_qty, reason: "Bulk CSV Restock (+#{add_qty})")
              updated_count += 1
            end

            # Optionally update price if provided in CSV
            if row[:price_inc_gst].present? || row[:price].present?
              p_val = (row[:price_inc_gst] || row[:price]).to_s.gsub(/[^0-9.]/, "")
              variant.update(price_dollars: p_val.to_f) if p_val.present?
            end
          else
            # Try to create product and variant if product_name and category exist
            if row[:product_name].present?
              cat_name = row[:category].presence || "Equine Feed & Nutrition"
              category = Category.find_by("LOWER(name) = ?", cat_name.strip.downcase) || Category.first
              product = Product.find_or_create_by!(name: row[:product_name].strip) do |p|
                p.category = category
                p.brand = row[:brand].presence || "Muchea Stockfeed"
                p.short_description = row[:description].presence || "#{p.name} stocked at Muchea Warehouse."
              end

              p_cents = ((row[:price_inc_gst] || row[:price] || 25.0).to_f * 100).round
              stock = (row[:stock_quantity] || row[:quantity] || 0).to_i

              product.variants.create!(
                name: row[:variant_name].presence || "Standard",
                sku: sku,
                price_cents: p_cents,
                stock_quantity: stock,
                weight_kg: (row[:weight_kg] || 20.0).to_f,
                is_default: true
              )
              created_count += 1
            else
              errors << "Row #{row_idx}: SKU '#{sku}' not found in catalog (provide product_name & category to create it)."
            end
          end
        end

        summary = "Bulk Import Complete: #{updated_count} stock items updated, #{created_count} new products created."
        if errors.any?
          redirect_to admin_inventory_index_path, notice: summary, alert: errors.take(3).join(" | ")
        else
          redirect_to admin_inventory_index_path, notice: summary
        end
      rescue => e
        redirect_to import_admin_inventory_index_path, alert: "CSV Parsing Error: #{e.message}"
      end
    end
  end
end
