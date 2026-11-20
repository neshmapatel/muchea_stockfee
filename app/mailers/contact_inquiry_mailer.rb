class ContactInquiryMailer < ApplicationMailer
  default from: "sales@mucheastockfeed.com.au"

  def new_inquiry_notification(inquiry)
    @inquiry = inquiry
    super_admin_emails = AdminUser.active.super_admins.pluck(:email)
    super_admin_emails = [ "neshmapatel1399@gmail.com" ] if super_admin_emails.empty?

    mail(
      to: super_admin_emails,
      reply_to: @inquiry.email,
      subject: "[Muchea Enquiry] New Rural Message from #{@inquiry.name} (#{@inquiry.location.presence || 'WA'})"
    )
  end

  def customer_confirmation(inquiry)
    @inquiry = inquiry
    mail(
      to: @inquiry.email,
      subject: "We received your enquiry — Muchea Stockfeed & Hardware"
    )
  end
end
