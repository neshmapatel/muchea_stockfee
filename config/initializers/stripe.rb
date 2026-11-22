# frozen_string_literal: true

require "stripe"

# Configure Stripe credentials from environment variables or encrypted credentials
publishable_key = ENV["STRIPE_PUBLISHABLE_KEY"].presence ||
                  Rails.application.credentials.dig(:stripe, :publishable_key).presence

secret_key = ENV["STRIPE_SECRET_KEY"].presence ||
             Rails.application.credentials.dig(:stripe, :secret_key).presence

webhook_secret = ENV["STRIPE_WEBHOOK_SECRET"].presence ||
                 Rails.application.credentials.dig(:stripe, :webhook_secret).presence

Rails.configuration.stripe = {
  publishable_key: publishable_key,
  secret_key: secret_key,
  webhook_secret: webhook_secret
}

Stripe.api_key = secret_key

module StripeConfig
  def self.publishable_key
    Rails.configuration.stripe[:publishable_key]
  end

  def self.secret_key
    Rails.configuration.stripe[:secret_key]
  end

  def self.webhook_secret
    Rails.configuration.stripe[:webhook_secret]
  end

  def self.configured?
    publishable_key.present? && secret_key.present?
  end

  def self.test_mode?
    return true unless configured?
    publishable_key.to_s.start_with?("pk_test_") || secret_key.to_s.start_with?("sk_test_")
  end

  def self.surcharge_enabled?
    ENV.fetch("STRIPE_SURCHARGE_ENABLED", "true") == "true"
  end

  def self.surcharge_percent
    ENV.fetch("STRIPE_SURCHARGE_PERCENT", "1.75").to_f
  end

  def self.surcharge_fixed_cents
    ENV.fetch("STRIPE_SURCHARGE_FIXED_CENTS", "30").to_i
  end
end
