require "test_helper"

class StorefrontFlowTest < ActionDispatch::IntegrationTest
  setup do
    # Load seeds into test database if empty
    Rails.application.load_seed if Category.count.zero?
  end

  test "homepage renders successfully with Australian rural branding and products" do
    get root_path
    assert_response :success
    assert_select "h1", text: /Trusted Animal Feeds/i
    assert_select "nav a", text: /Equine Feed & Nutrition/i
    assert_includes response.body, "48 619 284 921"
    assert_includes response.body, "Drive-Thru Bag Loading"
  end

  test "category and product pages load properly" do
    cat = Category.find_by!(slug: "equine-feed-nutrition")
    get category_path(cat)
    assert_response :success
    assert_select "h1", text: cat.name

    prod = cat.products.first
    get product_path(prod)
    assert_response :success
    assert_select "h1", text: prod.name
    assert_includes response.body, "schema.org"
    assert_includes response.body, "inc. 10% GST"
  end

  test "complete cart, checkout, inventory deduction, and tax invoice flow" do
    variant = ProductVariant.find_by!(sku: "HYG-BAL-20KG")
    initial_stock = variant.stock_quantity

    # 1. Add to Cart
    post add_to_cart_path, params: { variant_id: variant.id, quantity: 2 }
    assert_redirected_to cart_path
    follow_redirect!
    assert_includes response.body, variant.product.name

    # 2. Checkout
    get checkout_path
    assert_response :success

    post process_checkout_path, params: {
      customer_name: "Bruce Sterling",
      customer_email: "bruce@wa-pastoral.com.au",
      customer_phone: "0419 888 777",
      fulfillment_type: "delivery",
      delivery_address: "Lot 88 Chittering Valley Rd",
      suburb: "Lower Chittering",
      postcode: "6084",
      delivery_notes: "Leave near feed shed"
    }

    order = Order.find_by!(customer_email: "bruce@wa-pastoral.com.au")
    assert_redirected_to checkout_success_path(order.order_number)
    follow_redirect!
    assert_includes response.body, order.order_number
    assert_includes response.body, order.tracking_code

    # 3. Check stock decremented
    variant.reload
    assert_equal initial_stock - 2, variant.stock_quantity

    # 4. Check Tax Invoice
    get tax_invoice_path(order.order_number)
    assert_response :success
    assert_includes response.body, "TAX INVOICE"
    assert_includes response.body, "48 619 284 921"

    # 5. Check Live Tracking Portal
    get tracking_path(order.tracking_code)
    assert_response :success
    assert_includes response.body, "Consignment Tracking"
    assert_includes response.body, order.tracking_code
  end

  test "admin authentication flow with default credentials" do
    get admin_root_path
    assert_redirected_to admin_login_path
    follow_redirect!
    assert_includes response.body, "OPERATIONS PORTAL"

    # Wrong credentials
    post admin_login_path, params: { email: "neshmapatel1399@gmail.com", password: "wrongpassword" }
    assert_response :unauthorized
    assert_includes response.body, "Invalid email or password"

    # Correct credentials
    sign_in_admin("neshmapatel1399@gmail.com", "neshma1331")
    get admin_root_path
    assert_response :success
    assert_includes response.body, "Warehouse Operations Center"
    assert_includes response.body, "Neshma Patel"

    # Sign out
    delete admin_logout_path
    assert_redirected_to admin_login_path
  end

  test "warehouse admin dashboard and order advancement" do
    sign_in_admin
    order = Order.first
    get admin_root_path
    assert_response :success
    assert_includes response.body, "Warehouse Operations Center"

    get admin_order_path(order)
    assert_response :success

    initial_status = order.status
    patch advance_status_admin_order_path(order)
    order.reload
    assert_not_equal initial_status, order.status

    get packing_slip_admin_order_path(order)
    assert_response :success
    assert_includes response.body, "PACKING SLIP"
  end

  test "warehouse admin product creation and inventory management" do
    sign_in_admin
    category = Category.first
    get new_admin_product_path
    assert_response :success
    assert_includes response.body, "Add New Product"

    post admin_products_path, params: {
      product: {
        name: "Wesfeeds Golden Yolk Layer Pellets",
        category_id: category.id,
        brand: "Wesfeeds",
        short_description: "Premium WA layer pellets for laying hens.",
        active: "1",
        variants_attributes: {
          "0" => {
            name: "20kg Bag",
            sku: "WES-YOLK-20",
            price_dollars: "24.50",
            stock_quantity: 50,
            low_stock_threshold: 10,
            weight_kg: 20.0
          }
        }
      }
    }

    assert_redirected_to admin_products_path
    follow_redirect!
    assert_includes response.body, "Wesfeeds Golden Yolk Layer Pellets"

    created = Product.find_by(name: "Wesfeeds Golden Yolk Layer Pellets")
    assert_not_nil created
    assert_equal 1, created.variants.count
    assert_equal 50, created.variants.first.stock_quantity
  end

  test "admin barcode scanner and quick restock flow" do
    sign_in_admin
    variant = ProductVariant.first
    old_stock = variant.stock_quantity

    get scanner_admin_inventory_index_path
    assert_response :success
    assert_includes response.body, "Handheld Barcode Restock"

    post scan_adjust_admin_inventory_index_path, params: {
      barcode: variant.sku,
      quantity: 40,
      mode: "add"
    }

    assert_redirected_to scanner_admin_inventory_index_path
    follow_redirect!
    assert_includes response.body, "Scanned: #{variant.product.name}"

    variant.reload
    assert_equal old_stock + 40, variant.stock_quantity
  end

  test "admin bulk csv import flow" do
    sign_in_admin
    variant = ProductVariant.first
    get import_admin_inventory_index_path
    assert_response :success
    assert_includes response.body, "Bulk Stock & Product CSV Import"

    # Create a temporary test CSV file
    csv_file = Tempfile.new(["test_stock", ".csv"])
    csv_file.write("sku,stock_quantity\n#{variant.sku},99\n")
    csv_file.rewind

    uploaded = Rack::Test::UploadedFile.new(csv_file.path, "text/csv")

    post process_import_admin_inventory_index_path, params: {
      file: uploaded
    }

    assert_redirected_to admin_inventory_index_path
    follow_redirect!
    assert_includes response.body, "Bulk Import Complete"

    variant.reload
    assert_equal 99, variant.stock_quantity

    csv_file.close
    csv_file.unlink
  end

  test "admin category creation flow" do
    sign_in_admin
    get new_admin_category_path
    assert_response :success
    assert_includes response.body, "Add New Feed or Supply Category"

    post admin_categories_path, params: {
      category: {
        name: "Goat & Alpaca Feed",
        department: "Stockfeed & Animal Nutrition",
        description: "Specialized WA pastoral feeds for goats and alpacas."
      }
    }
    assert_redirected_to admin_categories_path
    follow_redirect!
    assert_includes response.body, "Goat &amp; Alpaca Feed"
    assert_not_nil Category.find_by(name: "Goat & Alpaca Feed")
  end

  test "sitemap.xml renders valid XML" do
    get "/sitemap.xml"
    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_includes response.body, "<urlset"
  end
end
