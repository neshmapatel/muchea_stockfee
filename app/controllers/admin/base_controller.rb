module Admin
  class BaseController < ApplicationController
    layout "admin"
    before_action :authenticate_admin!
    helper_method :current_admin, :admin_signed_in?

    private

    def current_admin
      @current_admin ||= AdminUser.find_by(id: session[:admin_user_id]) if session[:admin_user_id]
    end

    def admin_signed_in?
      current_admin.present?
    end

    def authenticate_admin!
      unless admin_signed_in?
        session[:admin_return_to] = request.fullpath if request.get?
        redirect_to admin_login_path, alert: "Please sign in to access the Warehouse Admin Portal."
      end
    end
  end
end
