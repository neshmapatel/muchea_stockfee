module Admin
  module NavigationHelper
    def admin_nav_items
      items = []
      items << { label: "Dashboard", path: admin_root_path, active: current_page?(admin_root_path) } if can?(:view_dashboard)
      items << { label: "Orders", desktop_label: "Orders & Dispatch", path: admin_orders_path, active: controller_name == "orders" } if can_any?(:view_orders, :manage_orders)
      items << { label: "Inventory", desktop_label: "Live Inventory", path: admin_inventory_index_path, active: controller_name == "inventory" && action_name == "index" } if can_any?(:view_inventory, :manage_inventory)
      items << { label: "⚡ Scanner", desktop_label: "⚡ Barcode Scanner", path: scanner_admin_inventory_index_path, active: controller_name == "inventory" && action_name == "scanner", highlight: true } if can?(:use_barcode_scanner)
      items << { label: "CSV Import", desktop_label: "Bulk Import", path: import_admin_inventory_index_path, active: controller_name == "inventory" && action_name == "import" } if can?(:bulk_csv_import)
      items << { label: "Products", path: admin_products_path, active: controller_name == "products" } if can_any?(:manage_products, :view_inventory, :manage_inventory)
      items << { label: "Categories", path: admin_categories_path, active: controller_name == "categories" } if can?(:manage_categories)
      items << { label: "Team", desktop_label: "Team & Admins", path: admin_users_path, active: controller_name == "users" } if can_any?(:manage_admin_users, :manage_super_admins)
      items << { label: "Roles", path: admin_roles_path, active: controller_name == "roles" } if can?(:manage_roles)
      items
    end
  end
end
