class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_cart,
                :current_customer,
                :customer_signed_in?,
                :customer_pending?,
                :customer_approved?,
                :can_view_prices?,
                :current_admin,
                :admin_signed_in?,
                :stripe_publishable_key,
                :stripe_configured?,
                :stripe_test_mode?

  def stripe_publishable_key
    StripeConfig.publishable_key
  end

  def stripe_configured?
    StripeConfig.configured?
  end

  def stripe_test_mode?
    StripeConfig.test_mode?
  end

  def current_cart
    @current_cart ||= Cart.new(session)
  end

  def current_customer
    @current_customer ||= Customer.find_by(id: session[:customer_id]) if session[:customer_id].present?
  end

  def current_admin
    @current_admin ||= AdminUser.active.find_by(id: session[:admin_user_id]) if session[:admin_user_id].present?
  end

  def customer_signed_in?
    current_customer.present?
  end

  def customer_pending?
    current_customer&.pending? == true
  end

  def customer_approved?
    current_customer&.approved? == true
  end

  def admin_signed_in?
    current_admin.present?
  end

  # Price gating toggle:
  # When false (default), prices and online checkout are publicly viewable (required for initial Stripe merchant verification).
  # When true, prices and checkout are strictly gated for approved member accounts.
  # Can be toggled at any time via ENV['REQUIRE_PRICE_GATE'] or by changing this method.
  def self.price_gating_enabled?
    ENV.fetch("REQUIRE_PRICE_GATE", "false") == "true"
  end

  def can_view_prices?
    return true unless self.class.price_gating_enabled?
    customer_approved?
  end

  def require_approved_customer!
    return if can_view_prices?

    if customer_pending?
      redirect_to customer_dashboard_path, alert: "Your account is currently pending approval. Prices and online checkout will unlock once approved by our shed management."
    else
      redirect_to customer_login_path(return_to: request.fullpath), alert: "Please log in to your approved member account to view prices and order."
    end
  end
end
