module Admin
  class SessionsController < ApplicationController
    layout false

    def new
      if session[:admin_user_id].present? && AdminUser.exists?(session[:admin_user_id])
        redirect_to admin_root_path
      end
    end

    def create
      email = params[:email].to_s.strip.downcase
      admin = AdminUser.find_by("LOWER(email) = ?", email)

      if admin&.authenticate(params[:password])
        session[:admin_user_id] = admin.id
        admin.update_column(:last_sign_in_at, Time.current)
        return_to = session.delete(:admin_return_to) || admin_root_path
        redirect_to return_to, notice: "Welcome back, #{admin.name}! Warehouse Operations Portal is live."
      else
        flash.now[:alert] = "Invalid email or password. Please check credentials and try again."
        render :new, status: :unauthorized
      end
    end

    def destroy
      session[:admin_user_id] = nil
      redirect_to admin_login_path, notice: "You have been signed out of Warehouse Admin."
    end
  end
end
