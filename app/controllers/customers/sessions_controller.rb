module Customers
  class SessionsController < ApplicationController
    def new
      if customer_signed_in?
        redirect_to customer_dashboard_path
        return
      end

      @return_to = params[:return_to]
    end

    def create
      email = params[:email].to_s.strip.downcase
      customer = ::Customer.find_by("LOWER(email) = ?", email)

      if customer&.authenticate(params[:password])
        session[:customer_id] = customer.id
        target = params[:return_to].presence || (customer.approved? ? root_path : customer_dashboard_path)

        if customer.pending?
          redirect_to customer_dashboard_path, notice: "Signed in. Your account is currently pending approval by our shed management."
        elsif customer.rejected?
          redirect_to customer_dashboard_path, alert: "Your account request was declined. Please call our shed on (08) 9571 8840."
        else
          redirect_to target, notice: "Welcome back, #{customer.first_name}! Live product pricing and ordering are unlocked."
        end
      else
        flash.now[:alert] = "Invalid email or password. Please try again."
        @return_to = params[:return_to]
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session[:customer_id] = nil
      redirect_to root_path, notice: "You have signed out."
    end
  end
end
