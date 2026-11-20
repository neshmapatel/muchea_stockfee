module Admin
  class RolesController < BaseController
    before_action -> { authorize!(:manage_roles) }
    before_action :set_role, only: [ :edit, :update, :destroy ]
    before_action :guard_super_admin_role!, only: [ :edit, :update, :destroy ]

    def index
      @roles = Role.ordered
      @user_counts_by_role = AdminUser.group(:role_id).count
    end

    def new
      @role = Role.new(permissions: %w[view_dashboard view_inventory])
    end

    def create
      @role = Role.new(role_params)
      @role.is_super_admin = false unless current_admin.super_admin?

      if @role.save
        redirect_to admin_roles_path, notice: "Role '#{@role.name}' created with #{@role.is_super_admin? ? 'full Super Admin' : @role.permissions.size} permission(s)."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = role_params
      attrs[:is_super_admin] = @role.is_super_admin unless current_admin.super_admin?
      # Keep built-in super_admin role unrestricted
      attrs[:is_super_admin] = true if @role.system_role? && @role.slug == "super_admin"

      if @role.update(attrs)
        redirect_to admin_roles_path, notice: "Permissions updated for role '#{@role.name}'."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if !@role.deletable?
        redirect_to admin_roles_path, alert: "Core system roles cannot be deleted."
      elsif @role.admin_users.exists?
        redirect_to admin_roles_path, alert: "Cannot delete '#{@role.name}' while staff accounts are assigned to it. Reassign those users first."
      else
        @role.destroy
        redirect_to admin_roles_path, notice: "Custom role '#{@role.name}' deleted."
      end
    end

    private

    def set_role
      @role = Role.find_by(slug: params[:id]) || Role.find_by(id: params[:id])
      redirect_to admin_roles_path, alert: "Role not found." unless @role
    end

    def guard_super_admin_role!
      return if @role.nil?
      return if current_admin.super_admin?

      if @role.is_super_admin?
        deny_access("Only Super Admins may modify a Super Admin role.")
      end
    end

    def role_params
      permitted = params.require(:role).permit(:name, :description, :display_order, permissions: [])
      permitted[:permissions] ||= []
      if current_admin.super_admin? && params[:role][:is_super_admin].present?
        permitted[:is_super_admin] = ActiveModel::Type::Boolean.new.cast(params[:role][:is_super_admin])
      end
      permitted
    end
  end
end
