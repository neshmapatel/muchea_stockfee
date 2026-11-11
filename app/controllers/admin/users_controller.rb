module Admin
  class UsersController < BaseController
    before_action -> { authorize_any!(:manage_admin_users, :manage_super_admins) }
    before_action :set_admin_user, only: [ :edit, :update, :toggle_active ]
    before_action :authorize_target_management!, only: [ :edit, :update, :toggle_active ]

    def index
      @admin_users = AdminUser.includes(:role, :created_by).ordered

      if params[:role_id].present?
        @admin_users = @admin_users.where(role_id: params[:role_id])
      end

      if params[:status] == "active"
        @admin_users = @admin_users.where(active: true)
      elsif params[:status] == "inactive"
        @admin_users = @admin_users.where(active: false)
      end

      if params[:q].present?
        term = "%#{params[:q].strip.downcase}%"
        @admin_users = @admin_users.where("LOWER(admin_users.name) LIKE ? OR LOWER(admin_users.email) LIKE ?", term, term)
      end

      @roles = Role.ordered
      @role_user_counts = AdminUser.group(:role_id).count
      @total_users_count = @role_user_counts.values.sum
    end

    def new
      default_role = assignable_roles.find_by(slug: "warehouse_staff") || assignable_roles.last
      @admin_user = AdminUser.new(active: true, role: default_role)
      @assignable_roles = assignable_roles
    end

    def create
      @admin_user = AdminUser.new(filtered_user_params)
      @admin_user.created_by = current_admin

      if assigning_restricted_super_admin_role?(@admin_user.role_id)
        @assignable_roles = assignable_roles
        @admin_user.errors.add(:role_id, "cannot be assigned — only Super Admins may create Super Admin accounts.")
        render :new, status: :forbidden
        return
      end

      if @admin_user.save
        redirect_to admin_users_path, notice: "Account created for #{@admin_user.name} (#{@admin_user.role_name})."
      else
        @assignable_roles = assignable_roles
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @assignable_roles = assignable_roles
    end

    def update
      attrs = filtered_user_params
      if attrs[:password].blank?
        attrs = attrs.except(:password, :password_confirmation)
      end

      if @admin_user == current_admin && attrs.key?(:active) && !ActiveModel::Type::Boolean.new.cast(attrs[:active])
        @assignable_roles = assignable_roles
        @admin_user.errors.add(:active, "— you cannot deactivate your own active session account.")
        render :edit, status: :unprocessable_entity
        return
      end

      if assigning_restricted_super_admin_role?(attrs[:role_id])
        @assignable_roles = assignable_roles
        @admin_user.errors.add(:role_id, "cannot be elevated — only Super Admins may assign Super Admin authority.")
        render :edit, status: :forbidden
        return
      end

      if @admin_user.update(attrs)
        redirect_to admin_users_path, notice: "Updated account for #{@admin_user.name} (#{@admin_user.role_name})."
      else
        @assignable_roles = assignable_roles
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_active
      if @admin_user == current_admin
        redirect_to admin_users_path, alert: "You cannot deactivate your own currently signed-in account."
        return
      end

      if @admin_user.update(active: !@admin_user.active?)
        state = @admin_user.active? ? "activated" : "deactivated"
        redirect_to admin_users_path, notice: "#{@admin_user.name} has been #{state}."
      else
        redirect_to admin_users_path, alert: @admin_user.errors.full_messages.to_sentence
      end
    end

    private

    def set_admin_user
      @admin_user = AdminUser.includes(:role).find_by(id: params[:id])
      redirect_to admin_users_path, alert: "Staff account not found." unless @admin_user
    end

    def authorize_target_management!
      return if @admin_user.nil?
      return if current_admin.super_admin?

      # If user has manage_super_admins specifically, allow; otherwise block managing super admins
      if @admin_user.role&.is_super_admin? && !can?(:manage_super_admins)
        deny_access("Only Super Admins may modify a Super Admin account.")
      end
    end

    def can_manage_super_admins?
      current_admin.super_admin? || can?(:manage_super_admins)
    end

    def assignable_roles
      @assignable_roles ||= if can_manage_super_admins?
        Role.ordered
      else
        Role.where(is_super_admin: false).ordered
      end
    end

    def assigning_restricted_super_admin_role?(role_id)
      return false if role_id.blank? || can_manage_super_admins?

      Role.where(id: role_id, is_super_admin: true).exists?
    end

    def filtered_user_params
      params.require(:admin_user).permit(:name, :email, :phone, :role_id, :active, :password, :password_confirmation)
    end
  end
end
