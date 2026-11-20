module Customers
  class DashboardController < ApplicationController
    before_action :require_customer!

    def show
      @customer = current_customer
    end

    private

    def require_customer!
      unless customer_signed_in?
        redirect_to customer_login_path, alert: "Please sign in to access your customer account."
      end
    end
  end
end
