# frozen_string_literal: true

require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @order = Order.create!(
      customer_name: "Bruce Sterling",
      customer_email: "bruce@wa-pastoral.com.au",
      customer_phone: "0419 888 777",
      fulfillment_type: "delivery",
      status: "paid",
      payment_status: "completed",
      subtotal_cents: 8000,
      total_cents: 8000
    )
  end

  test "valid payment can be created and associated with order" do
    payment = @order.payments.create!(
      stripe_session_id: "cs_test_abc123",
      stripe_payment_intent_id: "pi_test_xyz789",
      amount_cents: 8000,
      currency: "aud",
      status: "succeeded",
      payment_method: "Stripe Checkout",
      customer_email: "bruce@wa-pastoral.com.au"
    )

    assert payment.persisted?
    assert_equal @order, payment.order
    assert_equal 80.0, payment.amount_dollars
    assert_equal "AU$ 80.00", payment.formatted_amount
    assert payment.succeeded?
    assert_not payment.failed?
    assert_includes @order.payments, payment
    assert_equal payment, @order.latest_payment
  end

  test "payment requires non-negative amount_cents" do
    payment = @order.payments.build(amount_cents: -50, currency: "aud")
    assert_not payment.valid?
    assert_includes payment.errors[:amount_cents], "must be greater than or equal to 0"
  end
end
