class CustomerActivationMailer < ApplicationMailer
  default from: "sales@mucheastockfeed.com.au"

  def super_admin_activation_request(customer)
    @customer = customer
    super_admin_emails = AdminUser.active.super_admins.pluck(:email)
    super_admin_emails = [ "neshmapatel1399@gmail.com" ] if super_admin_emails.empty?

    mail(
      to: super_admin_emails,
      subject: "[Action Required] New Account Activation Request - #{@customer.name} (#{@customer.business_name.presence || 'Rural Member'})"
    )
  end

  def customer_welcome_pending(customer)
    @customer = customer
    mail(
      to: @customer.email,
      subject: "Your Muchea Stockfeed & Hardware Account is Pending Activation"
    )
  end

  def customer_approved(customer)
    @customer = customer
    mail(
      to: @customer.email,
      subject: "🎉 Your Account Has Been Approved! Live Prices & Ordering Unlocked"
    )
  end

  def customer_rejected(customer)
    @customer = customer
    mail(
      to: @customer.email,
      subject: "Update on Your Muchea Stockfeed & Hardware Membership Request"
    )
  end
end
