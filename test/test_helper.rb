ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def sign_in_admin(email = "neshmapatel1399@gmail.com", password = "neshma1331", role_slug: "super_admin", name: "Neshma Patel")
      Role.bootstrap_defaults!
      role = Role.find_by!(slug: role_slug)
      admin = AdminUser.find_by(email: email)
      admin ||= AdminUser.create!(name: name, email: email, password: password, role: role, active: true)
      post admin_login_path, params: { email: email, password: password }
      admin
    end

    def sign_in_customer(email = "member@wafarmer.com.au", password = "password123", status = "approved")
      customer = Customer.find_by(email: email)
      customer ||= Customer.create!(
        first_name: "Jack",
        last_name: "Thompson",
        email: email,
        phone: "0418 123 456",
        business_name: "Thompson Pastoral Co",
        property_address: "Lot 12 Great Northern Hwy",
        suburb: "Muchea",
        postcode: "6501",
        state: "WA",
        primary_interest: "Cattle & Hay",
        password: password,
        status: status,
        approved_at: (status == "approved" ? Time.current : nil)
      )
      post customer_login_path, params: { email: email, password: password }
      customer
    end
  end
end
