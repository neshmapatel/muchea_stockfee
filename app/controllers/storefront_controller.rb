class StorefrontController < ApplicationController
  def index
    @live_categories = Category.live
    @coming_soon_categories = Category.coming_soon
    @featured_feed_products = Product.live.featured.includes(:category, :variants).limit(8)
    @coming_soon_hardware_products = Product.coming_soon.includes(:category, :variants).limit(4)
    @delivery_zones = DeliveryZone.all
    @recent_deliveries_count = Order.where("created_at > ?", 7.days.ago).count + 24
  end

  def delivery_schedule
    @delivery_zones = DeliveryZone.all
  end

  def drive_thru_pickup
  end

  def about
  end

  def contact
    @inquiry = ContactInquiry.new
  end

  def submit_contact
    @inquiry = ContactInquiry.new(inquiry_params)
    if @inquiry.save
      begin
        ContactInquiryMailer.new_inquiry_notification(@inquiry).deliver_now
        ContactInquiryMailer.customer_confirmation(@inquiry).deliver_now
      rescue StandardError => e
        Rails.logger.error("Failed to send contact inquiry emails: #{e.message}")
      end

      redirect_to contact_path, notice: "Thank you, #{@inquiry.name}! Your enquiry has been received. Our Muchea shed team will contact you on #{@inquiry.phone} shortly."
    else
      flash.now[:alert] = "Please complete all required fields marked with an asterisk (*)."
      render :contact, status: :unprocessable_entity
    end
  end

  private

  def inquiry_params
    params.require(:contact_inquiry).permit(:name, :phone, :email, :location, :message)
  end
end
