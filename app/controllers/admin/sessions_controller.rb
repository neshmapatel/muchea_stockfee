module Admin
  class SessionsController < ApplicationController
    layout false

    def new
      if session[:admin_user_id].present? && AdminUser.active.exists?(session[:admin_user_id])
        redirect_to admin_root_path
      end
    end

    def create
      email = params[:email].to_s.strip.downcase
      admin = AdminUser.includes(:role).find_by("LOWER(email) = ?", email)

      if admin&.authenticate(params[:password])
        unless admin.active?
          flash.now[:alert] = "Your staff account is currently deactivated. Please contact a Super Admin."
          render :new, status: :forbidden
          return
        end

        session[:admin_user_id] = admin.id
        admin.update_column(:last_sign_in_at, Time.current)
        return_to = session.delete(:admin_return_to) || landing_path_for(admin)
        redirect_to return_to, notice: "Welcome back, #{admin.name} (#{admin.role_name})!"
      else
        flash.now[:alert] = "Invalid email or password. Please check credentials and try again."
        render :new, status: :unauthorized
      end
    end

    def destroy
      session[:admin_user_id] = nil
      session.delete(:admin_return_to)
      redirect_to admin_login_path, notice: "You have been signed out of Warehouse Admin."
    end

    private

    def landing_path_for(admin)
      return admin_root_path if admin.can?(:view_dashboard)
      return admin_orders_path if admin.can_any?(:view_orders, :manage_orders)
      return scanner_admin_inventory_index_path if admin.can?(:use_barcode_scanner)
      return admin_inventory_index_path if admin.can_any?(:view_inventory, :manage_inventory)
      return admin_products_path if admin.can?(:manage_products)
      return admin_categories_path if admin.can?(:manage_categories)
      return admin_users_path if admin.can_any?(:manage_admin_users, :manage_super_admins)

      admin_root_path
    end
  end
end
