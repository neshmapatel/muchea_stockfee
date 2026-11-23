module Admin
  class CustomersController < BaseController
    before_action :require_super_admin!, only: [ :approve, :reject, :edit, :update ]

    def index
      @customers = Customer.includes(:approved_by).order(created_at: :desc)

      @status_filter = params[:status].presence || "all"
      if Customer::STATUSES.include?(@status_filter)
        @customers = @customers.where(status: @status_filter)
      end

      if params[:q].present?
        q = "%#{params[:q].strip.downcase}%"
        @customers = @customers.where(
          "LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ? OR LOWER(phone) LIKE ? OR LOWER(business_name) LIKE ? OR LOWER(abn) LIKE ?",
          q, q, q, q, q, q
        )
      end

      @pending_count = Customer.pending.count
      @approved_count = Customer.approved.count
      @rejected_count = Customer.rejected.count
    end

    def show
      @customer = Customer.includes(:approved_by).find(params[:id])
    end

    def edit
      @customer = Customer.find(params[:id])
    end

    def update
      @customer = Customer.find(params[:id])
      clean_params = customer_params
      clean_params.delete(:password) if clean_params[:password].blank?

      if @customer.update(clean_params)
        redirect_to admin_customer_path(@customer), notice: "✅ Customer profile for #{@customer.name} (#{@customer.email}) was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def approve
      @customer = Customer.find(params[:id])
      @customer.approve!(current_admin)

      begin
        CustomerActivationMailer.customer_approved(@customer).deliver_now
      rescue StandardError => e
        Rails.logger.error("Failed to send customer approval email: #{e.message}")
      end

      redirect_back fallback_location: admin_customers_path,
                    notice: "✅ Account for #{@customer.name} (#{@customer.email}) has been APPROVED. Live prices and ordering are now enabled for this member."
    end

    def reject
      @customer = Customer.find(params[:id])
      reason = params[:rejection_reason].presence || "Does not meet current membership criteria."
      @customer.reject!(current_admin, reason: reason)

      begin
        CustomerActivationMailer.customer_rejected(@customer).deliver_now
      rescue StandardError => e
        Rails.logger.error("Failed to send customer rejection email: #{e.message}")
      end

      redirect_back fallback_location: admin_customers_path,
                    alert: "Account activation request for #{@customer.name} has been DECLINED."
    end

    private

    def customer_params
      params.require(:customer).permit(
        :first_name, :last_name, :email, :phone,
        :business_name, :abn, :property_address,
        :suburb, :postcode, :state, :primary_interest,
        :status, :password
      )
    end
  end
end
