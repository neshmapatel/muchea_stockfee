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
    def sign_in_admin(email = "neshmapatel1399@gmail.com", password = "neshma1331")
      admin = AdminUser.find_by(email: email)
      admin ||= AdminUser.create!(name: "Neshma Patel", email: email, password: password, role: "super_admin")
      post admin_login_path, params: { email: email, password: password }
      admin
    end
  end
end
