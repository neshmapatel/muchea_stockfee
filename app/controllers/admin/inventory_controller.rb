require "csv"

module Admin
  class InventoryController < BaseController
    before_action -> { authorize_any!(:view_inventory, :manage_inventory) }, only: [ :index ]
    before_action -> { authorize!(:manage_inventory) }, only: [ :quick_adjust ]
    before_action -> { authorize!(:use_barcode_scanner) }, only: [ :scanner, :scan_adjust ]
    before_action -> { authorize!(:bulk_csv_import) }, only: [ :import, :process_import ]

    def index
      @variants = ProductVariant.joins(:product).includes(product: :category)
                                .order("products.name ASC, product_variants.name ASC")

      if params[:filter] == "low_stock"
        @variants = @variants.low_stock
      end

      if params[:category_id].present?
        @variants = @variants.where(products: { category_id: params[:category_id] })
      end

      if params[:q].present?
        term = "%#{params[:q].strip.downcase}%"
        @variants = @variants.where(
          "LOWER(products.name) LIKE ? OR LOWER(product_variants.sku) LIKE ? OR LOWER(product_variants.name) LIKE ?",
          term, term, term
        )
      end

      @total_variant_count = ProductVariant.count
      @low_stock_count = ProductVariant.low_stock.count
      @categories = Category.ordered
      @recent_logs = InventoryLog.includes(:admin_user, product_variant: :product).limit(10)
    end

    def quick_adjust
      variant = ProductVariant.find(params[:variant_id])
      reason = params[:reason].presence || "Warehouse Adjustment"

      if params[:exact_quantity].present?
        target = [ params[:exact_quantity].to_i, 0 ].max
        variant.set_stock!(target, reason: reason, admin_user: current_admin)
        redirect_back fallback_location: admin_inventory_index_path, notice: "Stock for #{variant.product.name} (#{variant.name}) set to #{variant.stock_quantity}."
      else
        delta = params[:delta].to_i
        variant.adjust_stock!(delta, reason: reason, admin_user: current_admin)
        redirect_back fallback_location: admin_inventory_index_path, notice: "Stock for #{variant.product.name} (#{variant.name}) updated to #{variant.stock_quantity}."
      end
    end

    def scanner
      @recent_scans = InventoryLog.includes(:admin_user, product_variant: :product)
                                  .where("reason LIKE ?", "%Barcode Scanner%")
                                  .limit(8)

      if flash[:scanned_variant_id].present?
        @last_scanned = ProductVariant.includes(:product).find_by(id: flash[:scanned_variant_id])
      end
    end

    def scan_adjust
      code = params[:barcode].to_s.strip
      qty = [ params[:quantity].to_i, 1 ].max
      mode = params[:mode].presence || "add"

      if code.blank?
        redirect_to scanner_admin_inventory_index_path, alert: "Please scan a barcode or enter a SKU."
        return
      end

      normalized = code.upcase
      variant = ProductVariant.includes(:product).where("UPPER(sku) = ?", normalized).first
      variant ||= ProductVariant.joins(:product).includes(:product)
                                .where("UPPER(products.name) LIKE ?", "%#{normalized}%").first

      if variant
        old_qty = variant.stock_quantity
        apply_scanner_mode!(variant, mode, qty)

        flash[:scanned_variant_id] = variant.id
        flash[:scanned_qty] = qty
        flash[:notice] = "✅ BEEP! Scanned: #{variant.product.name} (#{variant.name}) — SKU: #{variant.sku} | Stock: #{old_qty} ➜ #{variant.stock_quantity}"
      else
        flash[:alert] = "❌ No product found for Barcode / SKU '#{code}'. Please verify the barcode or add it via Products Catalog."
      end

      redirect_to scanner_admin_inventory_index_path
    end

    def import
    end

    def process_import
      file = params[:file]
      if file.blank?
        redirect_to import_admin_inventory_index_path, alert: "Please select a .csv file to upload."
        return
      end

      updated_count, created_count, errors = import_csv_rows(file.path)
      summary = "Bulk Import Complete: #{updated_count} stock items updated, #{created_count} new products created."

      if errors.any?
        redirect_to admin_inventory_index_path, notice: summary, alert: errors.take(3).join(" | ")
      else
        redirect_to admin_inventory_index_path, notice: summary
      end
    rescue => e
      redirect_to import_admin_inventory_index_path, alert: "CSV Parsing Error: #{e.message}"
    end

    private

    def apply_scanner_mode!(variant, mode, qty)
      case mode
      when "set"
        variant.set_stock!(qty, reason: "Barcode Scanner Stocktake Count (=#{qty})", admin_user: current_admin)
      when "deduct"
        variant.adjust_stock!(-qty, reason: "Barcode Scanner Manual Deduct (-#{qty})", admin_user: current_admin)
      else
        variant.adjust_stock!(qty, reason: "Barcode Scanner Restock (+#{qty})", admin_user: current_admin)
      end
    end

    def import_csv_rows(file_path)
      rows = CSV.read(file_path, headers: true, header_converters: :symbol)
      skus = rows.filter_map { |r| r[:sku].to_s.strip.upcase.presence }.uniq

      # Preload lookup tables to eliminate N+1 queries during batch imports
      variants_by_sku = if skus.any?
        ProductVariant.where("UPPER(sku) IN (?)", skus).index_by { |v| v.sku.upcase }
      else
        {}
      end
      categories_by_name = Category.all.index_by { |c| c.name.downcase }
      fallback_category = Category.ordered.first

      updated_count = 0
      created_count = 0
      errors = []

      ActiveRecord::Base.transaction do
        rows.each_with_index do |row, idx|
          row_num = idx + 2
          sku = row[:sku].to_s.strip.upcase
          next if sku.blank?

          variant = variants_by_sku[sku]
          if variant
            updated_count += 1 if update_variant_from_csv!(variant, row)
          elsif row[:product_name].present?
            new_variant = create_product_from_csv!(row, sku, categories_by_name, fallback_category)
            variants_by_sku[sku] = new_variant
            created_count += 1
          else
            errors << "Row #{row_num}: SKU '#{sku}' not found in catalog (provide product_name & category to create it)."
          end
        end
      end

      [ updated_count, created_count, errors ]
    end

    def update_variant_from_csv!(variant, row)
      changed = false

      if row[:stock_quantity].present?
        variant.set_stock!([ row[:stock_quantity].to_i, 0 ].max, reason: "Bulk CSV Stocktake Import", admin_user: current_admin)
        changed = true
      elsif row[:quantity].present? || row[:add_quantity].present?
        add_qty = (row[:quantity] || row[:add_quantity]).to_i
        variant.adjust_stock!(add_qty, reason: "Bulk CSV Restock (+#{add_qty})", admin_user: current_admin)
        changed = true
      end

      price_raw = row[:price_inc_gst] || row[:price]
      if price_raw.present?
        cleaned = price_raw.to_s.gsub(/[^0-9.]/, "")
        variant.update!(price_dollars: cleaned.to_f) if cleaned.present?
      end

      changed
    end

    def create_product_from_csv!(row, sku, categories_by_name, fallback_category)
      cat_key = (row[:category].presence || "Equine Feed & Nutrition").strip.downcase
      category = categories_by_name[cat_key] || fallback_category
      product_name = row[:product_name].strip

      product = Product.find_or_create_by!(name: product_name) do |p|
        p.category = category
        p.brand = row[:brand].presence || "Muchea Stockfeed"
        p.short_description = row[:description].presence || "#{p.name} stocked at Muchea Warehouse."
      end

      p_cents = ((row[:price_inc_gst] || row[:price] || 25.0).to_f * 100).round
      stock = [ (row[:stock_quantity] || row[:quantity] || 0).to_i, 0 ].max

      variant = product.variants.create!(
        name: row[:variant_name].presence || "Standard",
        sku: sku,
        price_cents: p_cents,
        stock_quantity: stock,
        weight_kg: (row[:weight_kg] || 20.0).to_f,
        is_default: true
      )

      if stock.positive?
        variant.inventory_logs.create!(
          change_amount: stock,
          new_quantity: stock,
          reason: "Bulk CSV New Product Import",
          admin_user: current_admin
        )
      end

      variant
    end
  end
end
