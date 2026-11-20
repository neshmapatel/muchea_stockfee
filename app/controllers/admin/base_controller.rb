module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_admin!

    helper_method :current_admin, :admin_signed_in?, :can?, :can_any?

    private

    def current_admin
      return @current_admin if defined?(@current_admin)

      @current_admin = if session[:admin_user_id].present?
        AdminUser.includes(:role).find_by(id: session[:admin_user_id], active: true)
      end
    end

    def admin_signed_in?
      current_admin.present?
    end

    def can?(permission)
      current_admin&.can?(permission) == true
    end

    def can_any?(*permissions)
      current_admin&.can_any?(*permissions) == true
    end

    def authenticate_admin!
      return if admin_signed_in?

      session[:admin_user_id] = nil
      session[:admin_return_to] = request.fullpath if request.method == "GET"
      redirect_to admin_login_path, alert: "Please sign in with an active staff account to access Warehouse Admin."
    end

    def authorize!(permission)
      return true if can?(permission)

      deny_access
      false
    end

    def authorize_any!(*permissions)
      return true if can_any?(*permissions)

      deny_access
      false
    end

    def require_super_admin!
      return true if current_admin&.super_admin?

      deny_access("Only Super Admins are authorized to perform this action.")
      false
    end

    def deny_access(message = nil)
      msg = message || "Access denied: your role (#{current_admin&.role_name}) does not include permission for this section."
      respond_to do |format|
        format.html do
          fallback = admin_first_accessible_path
          if fallback == request.path || fallback.nil?
            session[:admin_user_id] = nil
            redirect_to admin_login_path, alert: "Your role currently has no accessible admin sections configured."
          else
            redirect_to fallback, alert: msg
          end
        end
        format.json { render json: { error: msg }, status: :forbidden }
      end
    end

    def admin_first_accessible_path(admin = current_admin)
      return admin_login_path unless admin

      candidates = [
        [ :view_dashboard, admin_root_path ],
        [ :manage_orders, admin_orders_path ],
        [ :view_orders, admin_orders_path ],
        [ :use_barcode_scanner, scanner_admin_inventory_index_path ],
        [ :view_inventory, admin_inventory_index_path ],
        [ :manage_inventory, admin_inventory_index_path ],
        [ :bulk_csv_import, import_admin_inventory_index_path ],
        [ :manage_products, admin_products_path ],
        [ :manage_categories, admin_categories_path ],
        [ :manage_admin_users, admin_users_path ],
        [ :manage_super_admins, admin_users_path ],
        [ :manage_roles, admin_roles_path ]
      ]

      match = candidates.find { |perm, _| admin.can?(perm) }
      match&.last
    end
  end
end
