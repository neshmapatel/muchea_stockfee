require "test_helper"

class AdminRbacTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_seed if Category.count.zero? || AdminUser.count.zero?
    @neshma = AdminUser.find_by!(email: "neshmapatel1399@gmail.com")
    @super_role = Role.find_by!(slug: "super_admin")
    @store_admin_role = Role.find_by!(slug: "store_admin")
    @inventory_role = Role.find_by!(slug: "inventory_manager")
    @accountant_role = Role.find_by!(slug: "accountant")
    @staff_role = Role.find_by!(slug: "warehouse_staff")
  end

  test "neshma is configured as active Super Admin with full authority" do
    assert @neshma.super_admin?
    assert @neshma.active?
    assert_equal "Super Admin", @neshma.role_name
    Role::ALL_PERMISSION_KEYS.each do |perm|
      assert @neshma.can?(perm), "Expected Neshma to have #{perm}"
    end
  end

  test "super admin can create another super admin and role-based admins" do
    sign_in_admin

    # Create another Super Admin (e.g. Store Owner / Mama)
    post admin_users_path, params: {
      admin_user: {
        name: "Rajesh Mama",
        email: "mama@mucheastockfeed.com.au",
        phone: "0412 000 111",
        role_id: @super_role.id,
        active: "1",
        password: "Password123!",
        password_confirmation: "Password123!"
      }
    }
    assert_redirected_to admin_users_path
    mama = AdminUser.find_by!(email: "mama@mucheastockfeed.com.au")
    assert mama.super_admin?
    assert_equal @neshma.id, mama.created_by_id

    # Create an Accountant
    post admin_users_path, params: {
      admin_user: {
        name: "Priya Tax Accountant",
        email: "priya@mucheastockfeed.com.au",
        role_id: @accountant_role.id,
        active: "1",
        password: "Password123!",
        password_confirmation: "Password123!"
      }
    }
    assert_redirected_to admin_users_path
    priya = AdminUser.find_by!(email: "priya@mucheastockfeed.com.au")
    assert_not priya.super_admin?
    assert_equal "Accountant", priya.role_name

    # Verify list renders both users
    get admin_users_path
    assert_response :success
    assert_includes response.body, "Rajesh Mama"
    assert_includes response.body, "Priya Tax Accountant"
  end

  test "super admin can create custom roles with granular permissions" do
    sign_in_admin

    get new_admin_role_path
    assert_response :success

    post admin_roles_path, params: {
      role: {
        name: "Yard Scanner Operator",
        description: "Only scans incoming stock pallets at the Muchea shed.",
        permissions: [ "view_inventory", "use_barcode_scanner" ]
      }
    }
    assert_redirected_to admin_roles_path
    custom_role = Role.find_by!(name: "Yard Scanner Operator")
    assert custom_role.allows?(:use_barcode_scanner)
    assert custom_role.allows?(:view_inventory)
    assert_not custom_role.allows?(:view_financials)
    assert_not custom_role.allows?(:manage_products)

    # Create staff member on custom role and sign in as them
    operator = AdminUser.create!(
      name: "Sam Yardhand",
      email: "sam@mucheastockfeed.com.au",
      role: custom_role,
      password: "Password123!"
    )

    delete admin_logout_path
    post admin_login_path, params: { email: operator.email, password: "Password123!" }
    # Operator lacks view_dashboard so lands directly on barcode scanner!
    assert_redirected_to scanner_admin_inventory_index_path
    follow_redirect!
    assert_response :success

    # Operator can scan stock and record audit attribution
    variant = ProductVariant.first
    post scan_adjust_admin_inventory_index_path, params: { barcode: variant.sku, quantity: 5, mode: "add" }
    assert_redirected_to scanner_admin_inventory_index_path
    assert_equal operator.id, InventoryLog.first.admin_user_id

    # Operator is blocked from bulk CSV, product edits, and staff management
    get import_admin_inventory_index_path
    assert_redirected_to scanner_admin_inventory_index_path
    get new_admin_product_path
    assert_redirected_to scanner_admin_inventory_index_path
    get admin_users_path
    assert_redirected_to scanner_admin_inventory_index_path
  end

  test "accountant has read-only financial & order visibility without mutation authority" do
    accountant = AdminUser.create!(
      name: "Meera Accounts",
      email: "accounts@mucheastockfeed.com.au",
      role: @accountant_role,
      password: "Password123!"
    )
    sign_in_admin(accountant.email, "Password123!")

    get admin_root_path
    assert_response :success
    assert_includes response.body, "Total Sales (AUD)"
    assert_not_includes response.body, "Advance Status"

    get admin_orders_path
    assert_response :success

    order = Order.first
    original_status = order.status
    patch advance_status_admin_order_path(order)
    assert_redirected_to admin_root_path
    assert_equal original_status, order.reload.status

    get scanner_admin_inventory_index_path
    assert_redirected_to admin_root_path
  end

  test "store admin can create warehouse staff but cannot escalate privilege to super admin" do
    store_admin = AdminUser.create!(
      name: "Store Manager Dan",
      email: "dan@mucheastockfeed.com.au",
      role: @store_admin_role,
      password: "Password123!"
    )
    sign_in_admin(store_admin.email, "Password123!")

    # Allowed: create Warehouse Staff
    post admin_users_path, params: {
      admin_user: {
        name: "Loader Bob",
        email: "bob@mucheastockfeed.com.au",
        role_id: @staff_role.id,
        active: "1",
        password: "Password123!",
        password_confirmation: "Password123!"
      }
    }
    assert_redirected_to admin_users_path
    assert AdminUser.exists?(email: "bob@mucheastockfeed.com.au")

    # Blocked: attempt to create a Super Admin
    post admin_users_path, params: {
      admin_user: {
        name: "Rogue Super",
        email: "rogue@mucheastockfeed.com.au",
        role_id: @super_role.id,
        active: "1",
        password: "Password123!",
        password_confirmation: "Password123!"
      }
    }
    assert_response :forbidden
    assert_not AdminUser.exists?(email: "rogue@mucheastockfeed.com.au")

    # Blocked: attempt to edit or deactivate Neshma (Super Admin)
    get edit_admin_user_path(@neshma)
    assert_redirected_to admin_root_path

    patch toggle_active_admin_user_path(@neshma)
    assert_redirected_to admin_root_path
    assert @neshma.reload.active?

    # Blocked: manage roles page
    get admin_roles_path
    assert_redirected_to admin_root_path
  end

  test "deactivated user is blocked from login and last active super admin cannot be deactivated" do
    inactive = AdminUser.create!(
      name: "Former Staff",
      email: "former@mucheastockfeed.com.au",
      role: @staff_role,
      active: false,
      password: "Password123!"
    )

    post admin_login_path, params: { email: inactive.email, password: "Password123!" }
    assert_response :forbidden
    assert_includes response.body, "deactivated"

    # Model guard prevents leaving 0 active Super Admins
    assert_not @neshma.update(active: false)
    assert_includes @neshma.errors.full_messages.to_sentence, "last remaining active Super Admin"
  end
end
