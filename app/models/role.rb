require "set"

class Role < ApplicationRecord
  # Canonical, extensible registry of role-based permissions.
  # To add permissions for future site modules, append to the appropriate group below.
  PERMISSION_CATALOG = {
    "Operations & Financial Reporting" => {
      "view_dashboard" => {
        label: "View Operations Dashboard",
        description: "Access the main warehouse operations summary and activity overview."
      },
      "view_financials" => {
        label: "View Revenue & Financial Figures",
        description: "View AUD sales totals, 10% GST breakdowns, and financial summaries."
      }
    },
    "Orders & Dispatch" => {
      "view_orders" => {
        label: "View Orders & Packing Slips",
        description: "Inspect customer orders, delivery details, and print warehouse packing slips."
      },
      "manage_orders" => {
        label: "Process & Dispatch Orders",
        description: "Advance fulfillment statuses, assign carriers, and update delivery notes."
      }
    },
    "Warehouse Stock & Inventory" => {
      "view_inventory" => {
        label: "View Live Inventory & Audit Logs",
        description: "Monitor stock counts, low-stock warnings, and movement history."
      },
      "manage_inventory" => {
        label: "Adjust Warehouse Stock Counts",
        description: "Perform manual +/- restock adjustments and exact stocktake overrides."
      },
      "use_barcode_scanner" => {
        label: "Barcode Scanner Terminal",
        description: "Use handheld barcode / SKU scanner mode for rapid pallet restocking."
      },
      "bulk_csv_import" => {
        label: "Bulk CSV / Excel Sync",
        description: "Upload CSV spreadsheets to update stock levels or create catalog items in bulk."
      }
    },
    "Product & Category Catalog" => {
      "manage_products" => {
        label: "Manage Products & Pricing",
        description: "Create, edit, price (AUD inc. GST), and remove catalog products and variants."
      },
      "manage_categories" => {
        label: "Manage Categories & Departments",
        description: "Add, edit, and organize feed and hardware categories."
      }
    },
    "Security, Staff & Role Administration" => {
      "manage_admin_users" => {
        label: "Manage Store Staff & Admins",
        description: "Add, edit, or deactivate non-super-admin staff, accountants, and managers."
      },
      "manage_roles" => {
        label: "Manage Roles & Permissions",
        description: "Create custom roles and configure modular permission access levels."
      },
      "manage_super_admins" => {
        label: "Manage Super Admin Accounts",
        description: "Create, promote, edit, or deactivate Super Admin accounts."
      }
    }
  }.freeze

  ALL_PERMISSION_KEYS = PERMISSION_CATALOG.values.flat_map(&:keys).freeze

  DEFAULT_DEFINITIONS = [
    {
      slug: "super_admin",
      name: "Super Admin",
      description: "Full unrestricted authority across all store operations, financials, roles, and Super Admin accounts.",
      is_super_admin: true,
      system_role: true,
      display_order: 1,
      permissions: ALL_PERMISSION_KEYS
    },
    {
      slug: "store_admin",
      name: "Store Administrator",
      description: "Full day-to-day store management covering orders, stock, products, financials, and standard staff accounts.",
      is_super_admin: false,
      system_role: true,
      display_order: 2,
      permissions: %w[
        view_dashboard view_financials view_orders manage_orders
        view_inventory manage_inventory use_barcode_scanner bulk_csv_import
        manage_products manage_categories manage_admin_users
      ]
    },
    {
      slug: "inventory_manager",
      name: "Inventory Manager",
      description: "Controls stock levels, barcode scanner restocks, bulk CSV supplier imports, products, and categories.",
      is_super_admin: false,
      system_role: true,
      display_order: 3,
      permissions: %w[
        view_dashboard view_inventory manage_inventory
        use_barcode_scanner bulk_csv_import manage_products manage_categories
      ]
    },
    {
      slug: "accountant",
      name: "Accountant",
      description: "Financial oversight with access to revenue totals, GST breakdowns, customer orders, and inventory valuation.",
      is_super_admin: false,
      system_role: true,
      display_order: 4,
      permissions: %w[view_dashboard view_financials view_orders view_inventory]
    },
    {
      slug: "warehouse_staff",
      name: "Warehouse Staff",
      description: "Floor and yard operations: pack and dispatch orders, print packing slips, and scan incoming pallets.",
      is_super_admin: false,
      system_role: true,
      display_order: 5,
      permissions: %w[view_dashboard view_orders manage_orders view_inventory manage_inventory use_barcode_scanner]
    }
  ].freeze

  serialize :permissions, coder: JSON

  has_many :admin_users, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug
  before_validation :sanitize_permissions

  scope :ordered, -> { order(is_super_admin: :desc, display_order: :asc, name: :asc) }
  scope :assignable_by, ->(actor) { actor&.super_admin? ? all : where(is_super_admin: false) }

  def self.bootstrap_defaults!
    DEFAULT_DEFINITIONS.each do |attrs|
      role = find_or_initialize_by(slug: attrs[:slug])
      role.name ||= attrs[:name]
      role.description = attrs[:description] if role.description.blank?
      role.is_super_admin = attrs[:is_super_admin]
      role.system_role = attrs[:system_role]
      role.display_order = attrs[:display_order] if role.display_order.zero?
      role.permissions = attrs[:permissions] if role.new_record?
      role.save!
    end
  end

  def self.permission_meta(key)
    key_str = key.to_s
    PERMISSION_CATALOG.each_value do |group|
      return group[key_str] if group.key?(key_str)
    end
    nil
  end

  def to_param
    slug
  end

  def permissions=(value)
    @permission_set = nil
    super(Array(value).map(&:to_s))
  end

  def permission_set
    @permission_set ||= Set.new(Array(permissions).map(&:to_s))
  end

  def allows?(permission)
    return true if is_super_admin?

    key = permission.to_s
    return true if permission_set.include?(key)

    # Implicit hierarchical view access when manage access is granted
    return permission_set.include?("manage_orders") if key == "view_orders"
    return permission_set.include?("manage_inventory") if key == "view_inventory"

    false
  end

  def deletable?
    !system_role? && !is_super_admin?
  end

  private

  def generate_slug
    return if slug.present? || name.blank?

    base = name.parameterize(separator: "_")
    candidate = base
    counter = 1
    while Role.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}_#{counter}"
      counter += 1
    end
    self.slug = candidate
  end

  def sanitize_permissions
    if is_super_admin?
      self.permissions = ALL_PERMISSION_KEYS
    else
      valid_keys = Set.new(ALL_PERMISSION_KEYS)
      cleaned = Array(permissions).map(&:to_s).select { |k| valid_keys.include?(k) }.uniq
      @permission_set = nil
      self.permissions = cleaned
    end
  end
end

