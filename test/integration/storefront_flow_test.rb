require "test_helper"

class StorefrontFlowTest < ActionDispatch::IntegrationTest
  setup do
    # Load seeds into test database if empty
    Rails.application.load_seed if Category.count.zero?
  end

  test "homepage renders successfully with Australian rural branding and products" do
    get root_path
    assert_response :success
    assert_select "h1", text: /Western Australia’s/i
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

  test "warehouse admin dashboard and order advancement" do
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

  test "sitemap.xml renders valid XML" do
    get "/sitemap.xml"
    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_includes response.body, "<urlset"
  end
end
