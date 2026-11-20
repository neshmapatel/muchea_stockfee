module Admin
  class InquiriesController < BaseController
    def index
      @status_filter = params[:status].presence || "all"
      @inquiries = ContactInquiry.recent_first

      if ContactInquiry::STATUSES.include?(@status_filter)
        @inquiries = @inquiries.where(status: @status_filter)
      end

      if params[:q].present?
        q = "%#{params[:q].strip.downcase}%"
        @inquiries = @inquiries.where(
          "LOWER(name) LIKE ? OR LOWER(email) LIKE ? OR LOWER(phone) LIKE ? OR LOWER(location) LIKE ? OR LOWER(message) LIKE ?",
          q, q, q, q, q
        )
      end

      @new_count = ContactInquiry.where(status: "new").count
      @in_progress_count = ContactInquiry.where(status: "in_progress").count
      @resolved_count = ContactInquiry.where(status: "resolved").count
    end

    def show
      @inquiry = ContactInquiry.find(params[:id])
      # Mark as in_progress if currently new
      @inquiry.mark_in_progress! if @inquiry.new?
    end

    def resolve
      @inquiry = ContactInquiry.find(params[:id])
      @inquiry.mark_resolved!
      redirect_back fallback_location: admin_inquiry_path(@inquiry), notice: "Enquiry marked as resolved."
    end

    def reopen
      @inquiry = ContactInquiry.find(params[:id])
      @inquiry.mark_in_progress!
      redirect_back fallback_location: admin_inquiry_path(@inquiry), notice: "Enquiry reopened as in-progress."
    end
  end
end
