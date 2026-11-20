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
    assert_includes response.body, "Activate Account to View Prices"

    prod = cat.products.first
    get product_path(prod)
    assert_response :success
    assert_select "h1", text: prod.name
    assert_includes response.body, "schema.org"
    assert_match(/Activate your account to view prices/i, response.body)

    # Now verify that when signed in as an approved member, prices and GST are visible
    sign_in_customer("approved_tester@farm.com.au")
    get product_path(prod)
    assert_response :success
    assert_includes response.body, "inc. 10% GST"
    assert_includes response.body, "$"
  end

  test "complete cart, checkout, inventory deduction, and tax invoice flow" do
    sign_in_customer("bruce@wa-pastoral.com.au")
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

  test "storefront and admin render dynamic brand color palette from config" do
    get root_path
    assert_response :success
    assert_includes response.body, 'id="muchea-brand-theme"'
    assert_includes response.body, "--brand-primary:"
    assert_includes response.body, "window.BRAND_PALETTE"
    assert_includes response.body, "bg-brand-primary"

    get admin_login_path
    assert_response :success
    assert_includes response.body, 'id="muchea-brand-theme"'
    assert_includes response.body, "--brand-primary:"

    assert_equal "#c91820", ApplicationController.helpers.brand_palette[:primary]
    assert_equal "#0f1112", ApplicationController.helpers.brand_palette[:dark]
    assert_equal "#d49b28", ApplicationController.helpers.brand_palette[:accent]
  end

  test "guest visitor cannot view prices and cannot add to cart" do
    get root_path
    assert_response :success
    assert_includes response.body, "Activate Account to View Prices"

    variant = ProductVariant.first
    post add_to_cart_path, params: { variant_id: variant.id, quantity: 1 }
    assert_redirected_to customer_login_path(return_to: add_to_cart_path)
    follow_redirect!
    assert_includes response.body, "Please log in to your approved member account to view prices and order."
  end

  test "customer registration creates pending profile, triggers super admin email, and keeps prices locked" do
    ActionMailer::Base.deliveries.clear

    get customer_register_path
    assert_response :success
    assert_includes response.body, "Complete Profile"

    post customer_register_path, params: {
      customer: {
        first_name: "Sarah",
        last_name: "Connor",
        email: "sarah@ginginfarm.com.au",
        phone: "0422 999 888",
        business_name: "Gingin Citrus & Cattle",
        abn: "12 345 678 901",
        property_address: "Lot 44 Brand Highway",
        suburb: "Gingin",
        postcode: "6503",
        state: "WA",
        primary_interest: "Livestock & Cattle Feed",
        password: "securepassword123",
        password_confirmation: "securepassword123"
      }
    }

    customer = Customer.find_by!(email: "sarah@ginginfarm.com.au")
    assert_equal "pending", customer.status
    assert_not customer.can_view_prices?

    assert_redirected_to customer_dashboard_path
    follow_redirect!
    assert_includes response.body, "Your profile has been submitted"
    assert_includes response.body, "Pending Approval"

    # Verify emails triggered: 1 to Super Admin, 1 to Customer
    assert_equal 2, ActionMailer::Base.deliveries.count
    admin_mail = ActionMailer::Base.deliveries.find { |m| m.to.include?("neshmapatel1399@gmail.com") }
    customer_mail = ActionMailer::Base.deliveries.find { |m| m.to.include?("sarah@ginginfarm.com.au") }

    assert_not_nil admin_mail, "Super Admin must receive activation request notification"
    assert_includes admin_mail.subject, "New Account Activation Request"
    admin_body = admin_mail.text_part ? admin_mail.text_part.body.to_s : admin_mail.body.to_s
    assert_includes admin_body, "sarah@ginginfarm.com.au"
    assert_includes admin_body, "Gingin Citrus & Cattle"

    assert_not_nil customer_mail, "Customer must receive welcome pending confirmation"
    assert_includes customer_mail.subject, "Pending Activation"

    # Verify pending customer visiting storefront cannot see prices
    get root_path
    assert_response :success
    assert_includes response.body, "Sarah (Pending)"
    assert_includes response.body, "Price Pending Approval"
    assert_includes response.body, "Awaiting Super Admin review"
  end

  test "super admin approval workflow unlocks pricing and notifies customer" do
    customer = Customer.create!(
      first_name: "David",
      last_name: "Miller",
      email: "david@chitteringpastoral.com.au",
      phone: "0411 222 333",
      business_name: "Chittering Pastoral Co",
      property_address: "77 Muchea East Rd",
      suburb: "Lower Chittering",
      postcode: "6084",
      state: "WA",
      primary_interest: "Equine & Horse Feeds",
      password: "password123",
      status: "pending"
    )

    # 1. Staff with non-super-admin role cannot approve
    sign_in_admin("warehouse@muchea.com.au", "password123", role_slug: "warehouse_staff", name: "Bob Clerk")
    patch approve_admin_customer_path(customer)
    assert_redirected_to admin_root_path
    follow_redirect!
    assert_includes response.body, "Only Super Admins are authorized to perform this action."
    assert customer.reload.pending?

    # 2. Super Admin approves customer
    sign_in_admin("neshmapatel1399@gmail.com", "neshma1331", role_slug: "super_admin", name: "Neshma Patel")
    get admin_customers_path
    assert_response :success
    assert_includes response.body, "Customer Accounts &amp; Price Approvals"
    assert_includes response.body, "david@chitteringpastoral.com.au"

    ActionMailer::Base.deliveries.clear
    patch approve_admin_customer_path(customer)
    assert_redirected_to admin_customers_path
    follow_redirect!
    assert_includes response.body, "APPROVED"

    customer.reload
    assert_equal "approved", customer.status
    assert customer.can_view_prices?
    assert_not_nil customer.approved_at

    # Check approval email sent to customer
    approval_mail = ActionMailer::Base.deliveries.find { |m| m.to.include?("david@chitteringpastoral.com.au") }
    assert_not_nil approval_mail
    assert_includes approval_mail.subject, "Approved"

    # 3. Customer logs in and views prices
    delete admin_logout_path
    post customer_login_path, params: { email: "david@chitteringpastoral.com.au", password: "password123" }
    assert_redirected_to root_path

    get root_path
    assert_response :success
    assert_includes response.body, "👤 David"
    assert_includes response.body, "$"
    assert_not_includes response.body, "Prices Locked • Member Login Required"
  end

  test "empty cart displays AU$ 0.00 and zero delivery charges" do
    get root_path
    assert_response :success
    assert_includes response.body, "AU$ 0.00"

    get cart_path
    assert_response :success
    assert_includes response.body, "Your cart is currently empty"
  end

  test "logged in admin browsing public storefront does not bypass member price gate" do
    sign_in_admin("neshmapatel1399@gmail.com", "neshma1331", role_slug: "super_admin", name: "Neshma Patel")
    
    # Staff navigates to public storefront without an approved customer session
    get root_path
    assert_response :success
    assert_includes response.body, "Activate Account to View Prices"
    assert_not_includes response.body, "From AU$"

    cat = Category.first
    get category_path(cat)
    assert_response :success
    assert_includes response.body, "Activate Account to View Prices"
  end

  test "contact enquiry form submission creates record, sends email, and is viewable in admin portal" do
    ActionMailer::Base.deliveries.clear

    get contact_path
    assert_response :success
    assert_includes response.body, "Send an Enquiry or Quote Request"

    post contact_path, params: {
      contact_inquiry: {
        name: "Murray Campbell",
        phone: "0418 901 234",
        email: "murray@station.com.au",
        location: "Lower Chittering (6084)",
        message: "Looking for 5 rolls of 4x4 oaten hay and 10 bags of Hygain Balanced."
      }
    }

    assert_redirected_to contact_path
    follow_redirect!
    assert_includes response.body, "Thank you, Murray Campbell!"

    inquiry = ContactInquiry.find_by!(email: "murray@station.com.au")
    assert_equal "Murray Campbell", inquiry.name
    assert_equal "new", inquiry.status

    # Verify notification emails
    assert_equal 2, ActionMailer::Base.deliveries.count
    admin_mail = ActionMailer::Base.deliveries.find { |m| m.to.include?("neshmapatel1399@gmail.com") }
    assert_not_nil admin_mail
    assert_includes admin_mail.subject, "New Rural Message from Murray Campbell"

    customer_mail = ActionMailer::Base.deliveries.find { |m| m.to.include?("murray@station.com.au") }
    assert_not_nil customer_mail
    assert_includes customer_mail.subject, "We received your enquiry"

    # Verify viewing in Admin Operations Hub
    sign_in_admin("neshmapatel1399@gmail.com", "neshma1331")
    get admin_inquiries_path
    assert_response :success
    assert_includes response.body, "Customer Enquiries &amp; Quote Requests"
    assert_includes response.body, "Murray Campbell"
    assert_includes response.body, "0418 901 234"

    get admin_inquiry_path(inquiry)
    assert_response :success
    assert_includes response.body, "Looking for 5 rolls of 4x4 oaten hay"

    patch resolve_admin_inquiry_path(inquiry)
    assert_redirected_to admin_inquiry_path(inquiry)
    assert inquiry.reload.resolved?
  end
end
