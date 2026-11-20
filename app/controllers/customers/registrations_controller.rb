module Customers
  class RegistrationsController < ApplicationController
    def new
      if customer_signed_in?
        redirect_to customer_dashboard_path
        return
      end

      @customer = ::Customer.new
    end

    def create
      @customer = ::Customer.new(customer_params)
      @customer.status = "pending"

      if @customer.save
        # Automatically trigger activation request email to Super Admin and confirmation to customer
        begin
          CustomerActivationMailer.super_admin_activation_request(@customer).deliver_now
          CustomerActivationMailer.customer_welcome_pending(@customer).deliver_now
        rescue StandardError => e
          Rails.logger.error("Failed to send activation emails: #{e.message}")
        end

        session[:customer_id] = @customer.id
        redirect_to customer_dashboard_path, notice: "Thank you! Your profile has been submitted. Our shed management has been notified to review and approve your account."
      else
        flash.now[:alert] = "Please correct the errors below to complete your profile."
        render :new, status: :unprocessable_entity
      end
    end

    private

    def customer_params
      params.require(:customer).permit(
        :first_name,
        :last_name,
        :email,
        :phone,
        :business_name,
        :abn,
        :property_address,
        :suburb,
        :postcode,
        :state,
        :primary_interest,
        :password,
        :password_confirmation
      )
    end
  end
end
