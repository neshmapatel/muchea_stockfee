# frozen_string_literal: true

require "test_helper"

class StripePaymentTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_seed if Category.count.zero?
    @customer = sign_in_customer("bruce@wa-pastoral.com.au")
    @variant = ProductVariant.find_by!(sku: "HYG-BAL-20KG")
  end

  test "checkout page renders Stripe checkout details and NO dummy credit card inputs" do
    post add_to_cart_path, params: { variant_id: @variant.id, quantity: 1 }

    get checkout_path
    assert_response :success
    assert_includes response.body, "Proceed to Stripe Checkout"
    assert_includes response.body, "VISA"
    assert_includes response.body, "Mastercard"
    assert_includes response.body, "256-bit SSL encrypted Stripe session"

    # Verify dummy credit card inputs are completely removed
    assert_not_includes response.body, 'placeholder="•••• •••• •••• 4242"'
    assert_not_includes response.body, 'value="4242 •••• •••• 4242"'
    assert_not_includes response.body, 'value="312"'
  end

  test "completing checkout creates Order and associated Payment entity" do
    initial_stock = @variant.stock_quantity
    post add_to_cart_path, params: { variant_id: @variant.id, quantity: 2 }

    test_payment_intent_id = "pi_3Mtest#{SecureRandom.hex(10)}"

    post process_checkout_path, params: {
      customer_name: "Bruce Sterling",
      customer_email: @customer.email,
      customer_phone: "0419 888 777",
      fulfillment_type: "delivery",
      delivery_address: "Lot 88 Chittering Valley Rd",
      suburb: "Lower Chittering",
      postcode: "6084",
      delivery_notes: "Leave in feed shed",
      stripe_payment_intent_id: test_payment_intent_id,
      payment_method: "Stripe Checkout"
    }

    order = Order.find_by!(customer_email: @customer.email, stripe_payment_intent_id: test_payment_intent_id)
    assert_redirected_to checkout_success_path(order.order_number)

    assert_equal "paid", order.status
    assert_equal "completed", order.payment_status
    assert_equal test_payment_intent_id, order.stripe_payment_intent_id

    # Verify Payment entity was created and connected to Order
    assert_equal 1, order.payments.count
    payment = order.payments.first
    assert_equal test_payment_intent_id, payment.stripe_payment_intent_id
    assert_equal order.total_cents, payment.amount_cents
    assert_equal "aud", payment.currency
    assert_equal "succeeded", payment.status
    assert_equal order, payment.order

    @variant.reload
    assert_equal initial_stock - 2, @variant.stock_quantity
  end

  test "Stripe return endpoint creates Payment entity and updates Order" do
    # Create an order awaiting return
    order = Order.create!(
      customer_name: "Bruce Sterling",
      customer_email: @customer.email,
      customer_phone: "0419 888 777",
      fulfillment_type: "delivery",
      delivery_address: "Lot 88 Chittering Valley Rd",
      suburb: "Lower Chittering",
      postcode: "6084",
      status: "pending",
      payment_status: "pending",
      stripe_session_id: "cs_test_mock_return_999",
      subtotal_cents: 6000,
      total_cents: 6000
    )

    # Mock Stripe session retrieval
    mock_session = Struct.new(:id, :payment_status, :payment_intent, :currency, :amount_total, :metadata, :customer_details).new(
      "cs_test_mock_return_999",
      "paid",
      "pi_mock_return_intent_111",
      "aud",
      6000,
      {},
      Struct.new(:name, :email).new("Bruce Sterling", @customer.email)
    )

    original_retrieve = Stripe::Checkout::Session.method(:retrieve)
    Stripe::Checkout::Session.define_singleton_method(:retrieve) do |id|
      mock_session
    end

    begin
      get checkout_stripe_return_path, params: { session_id: "cs_test_mock_return_999" }
      assert_redirected_to checkout_success_path(order.order_number)

      order.reload
      assert_equal "paid", order.status
      assert_equal "completed", order.payment_status
      assert_equal "pi_mock_return_intent_111", order.stripe_payment_intent_id

      # Verify Payment record
      payment = order.payments.find_by(stripe_session_id: "cs_test_mock_return_999")
      assert_not_nil payment
      assert_equal "succeeded", payment.status
      assert_equal "pi_mock_return_intent_111", payment.stripe_payment_intent_id
      assert_equal 6000, payment.amount_cents
      assert_equal "aud", payment.currency
    ensure
      Stripe::Checkout::Session.define_singleton_method(:retrieve, original_retrieve)
    end
  end

  test "Stripe webhook checkout.session.completed creates/updates Payment entity" do
    order = Order.create!(
      customer_name: "Webhook Customer",
      customer_email: "webhook@example.com",
      customer_phone: "0400 000 000",
      fulfillment_type: "delivery",
      status: "pending",
      payment_status: "pending",
      stripe_session_id: "cs_webhook_sess_777",
      subtotal_cents: 5000,
      total_cents: 5000
    )

    webhook_payload = {
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_webhook_sess_777",
          payment_intent: "pi_webhook_pi_777",
          payment_status: "paid",
          amount_total: 5000,
          currency: "aud",
          customer_details: { email: "webhook@example.com" }
        }
      }
    }.to_json

    post stripe_webhook_path, params: webhook_payload, headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :ok

    order.reload
    assert_equal "paid", order.status
    assert_equal "completed", order.payment_status

    payment = order.payments.find_by(stripe_session_id: "cs_webhook_sess_777")
    assert_not_nil payment
    assert_equal "succeeded", payment.status
    assert_equal "pi_webhook_pi_777", payment.stripe_payment_intent_id
    assert_equal 5000, payment.amount_cents
  end

  test "Stripe webhook payment_intent.succeeded marks payment succeeded" do
    order = Order.create!(
      customer_name: "PI Test Customer",
      customer_email: "pi@example.com",
      customer_phone: "0400 000 000",
      fulfillment_type: "delivery",
      status: "pending",
      payment_status: "pending",
      stripe_payment_intent_id: "pi_webhook_test_12345",
      subtotal_cents: 5000,
      total_cents: 5000
    )

    payment = order.payments.create!(
      stripe_payment_intent_id: "pi_webhook_test_12345",
      amount_cents: 5000,
      currency: "aud",
      status: "pending"
    )

    webhook_payload = {
      type: "payment_intent.succeeded",
      data: {
        object: {
          id: "pi_webhook_test_12345",
          amount: 5000,
          currency: "aud",
          status: "succeeded"
        }
      }
    }.to_json

    post stripe_webhook_path, params: webhook_payload, headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :ok

    order.reload
    payment.reload
    assert_equal "completed", order.payment_status
    assert_equal "paid", order.status
    assert_equal "succeeded", payment.status
  end

  test "Stripe webhook payment_intent.payment_failed marks payment as failed" do
    order = Order.create!(
      customer_name: "Failed Customer",
      customer_email: "failed@example.com",
      customer_phone: "0400 000 000",
      fulfillment_type: "delivery",
      status: "paid",
      payment_status: "pending",
      stripe_payment_intent_id: "pi_webhook_fail_99999",
      subtotal_cents: 3000,
      total_cents: 3000
    )

    payment = order.payments.create!(
      stripe_payment_intent_id: "pi_webhook_fail_99999",
      amount_cents: 3000,
      currency: "aud",
      status: "pending"
    )

    webhook_payload = {
      type: "payment_intent.payment_failed",
      data: {
        object: {
          id: "pi_webhook_fail_99999",
          amount: 3000,
          currency: "aud",
          last_payment_error: { message: "Card declined by bank" }
        }
      }
    }.to_json

    post stripe_webhook_path, params: webhook_payload, headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :ok

    order.reload
    payment.reload
    assert_equal "failed", order.payment_status
    assert_equal "failed", payment.status
    assert_equal "Card declined by bank", payment.error_message
  end

  test "validate_postcode endpoint identifies valid local zone postcode" do
    post add_to_cart_path, params: { variant_id: @variant.id, quantity: 1 }

    get checkout_validate_postcode_path, params: { postcode: "6501" }, headers: { "Accept" => "application/json" }
    assert_response :success
    data = JSON.parse(response.body)

    assert data["valid"]
    assert_equal "matched_zone", data["status"]
    assert_includes data["zone_name"], "Zone 1"
    assert_equal 1500, data["fee_cents"]
    assert_equal "AU$ 15.00", data["formatted_fee"]
    assert_includes data["scheduled_days"], "Monday"
  end

  test "validate_postcode endpoint identifies regional WA postcode" do
    post add_to_cart_path, params: { variant_id: @variant.id, quantity: 1 }

    get checkout_validate_postcode_path, params: { postcode: "6330" }, headers: { "Accept" => "application/json" }
    assert_response :success
    data = JSON.parse(response.body)

    assert data["valid"]
    assert_equal "regional_wa", data["status"]
    assert_equal 3500, data["fee_cents"]
    assert_equal "AU$ 35.00", data["formatted_fee"]
  end

  test "validate_postcode endpoint rejects interstate postcode outside WA" do
    get checkout_validate_postcode_path, params: { postcode: "2000" }, headers: { "Accept" => "application/json" }
    assert_response :success
    data = JSON.parse(response.body)

    assert_not data["valid"]
    assert_equal "interstate", data["status"]
    assert_includes data["message"], "outside Western Australia"
  end

  test "validate_postcode endpoint rejects invalid format" do
    get checkout_validate_postcode_path, params: { postcode: "abc1" }, headers: { "Accept" => "application/json" }
    assert_response :success
    data = JSON.parse(response.body)

    assert_not data["valid"]
    assert_equal "invalid_format", data["status"]
    assert_includes data["message"], "4 digits"
  end

  test "checkout rejects invalid or interstate postcode for rural truck delivery" do
    post add_to_cart_path, params: { variant_id: @variant.id, quantity: 1 }

    # Interstate postcode for delivery
    post process_checkout_path, params: {
      customer_name: "Bruce Sterling",
      customer_email: @customer.email,
      customer_phone: "0419 888 777",
      fulfillment_type: "delivery",
      delivery_address: "123 Sydney Rd",
      suburb: "Sydney",
      postcode: "2000",
      delivery_notes: "Leave near door"
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Delivery is only available in Western Australia"

    # Malformed postcode for delivery
    post process_checkout_path, params: {
      customer_name: "Bruce Sterling",
      customer_email: @customer.email,
      customer_phone: "0419 888 777",
      fulfillment_type: "delivery",
      delivery_address: "Lot 88 Chittering Valley Rd",
      suburb: "Lower Chittering",
      postcode: "99",
      delivery_notes: "Leave near door"
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Please enter a valid 4-digit WA postcode"
  end

  test "Method 2 card processing surcharge is calculated, saved to order, and shown on invoice" do
    post add_to_cart_path, params: { variant_id: @variant.id, quantity: 1 }

    get checkout_path
    assert_response :success
    assert_includes response.body, "Card Processing Surcharge"

    # Place order
    post process_checkout_path, params: {
      customer_name: "Bruce Sterling",
      customer_email: @customer.email,
      customer_phone: "0419 888 777",
      fulfillment_type: "delivery",
      delivery_address: "Lot 88 Chittering Valley Rd",
      suburb: "Lower Chittering",
      postcode: "6084",
      delivery_notes: "Leave near feed shed"
    }

    order = Order.find_by!(customer_email: @customer.email)
    assert_redirected_to checkout_success_path(order.order_number)

    # Calculate expected surcharge using Method 2 (1.75% + 30c)
    base_cents = order.subtotal_cents + order.delivery_fee_cents
    expected_surcharge = ((base_cents * 0.0175) + 30).round
    assert_operator order.processing_fee_cents, :>, 0
    assert_equal expected_surcharge, order.processing_fee_cents
    assert_equal base_cents + expected_surcharge, order.total_cents
    assert_equal ((base_cents + expected_surcharge) / 11.0).round, order.gst_cents

    # Check Tax Invoice displays the surcharge
    get tax_invoice_path(order.order_number)
    assert_response :success
    assert_includes response.body, "Card Processing Surcharge"
    assert_includes response.body, order.formatted_processing_fee
  end
end
