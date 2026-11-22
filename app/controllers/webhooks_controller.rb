# frozen_string_literal: true

class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = StripeConfig.webhook_secret

    event = nil

    if endpoint_secret.present? && sig_header.present?
      begin
        event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
      rescue JSON::ParserError, Stripe::SignatureVerificationError => e
        Rails.logger.warn "Stripe webhook signature error: #{e.message}"
        render json: { error: e.message }, status: :bad_request
        return
      end
    else
      begin
        data = JSON.parse(payload)
        event = Stripe::Event.construct_from(data)
      rescue JSON::ParserError => e
        render json: { error: e.message }, status: :bad_request
        return
      end
    end

    case event.type
    when "checkout.session.completed"
      session_obj = event.data.object
      order = Order.find_by(stripe_session_id: session_obj.id)

      if order
        order.update!(
          payment_status: "completed",
          status: "paid",
          stripe_payment_intent_id: session_obj.payment_intent.presence || order.stripe_payment_intent_id
        )

        payment = order.payments.find_or_initialize_by(stripe_session_id: session_obj.id)
        payment.update!(
          stripe_payment_intent_id: session_obj.payment_intent,
          amount_cents: session_obj.amount_total || order.total_cents,
          currency: session_obj.currency || "aud",
          status: "succeeded",
          payment_method: "Stripe Checkout",
          customer_email: session_obj.customer_details&.email || order.customer_email
        )
        Rails.logger.info "Order ##{order.order_number} and Payment marked succeeded via webhook checkout.session.completed"
      end

    when "payment_intent.succeeded"
      payment_intent = event.data.object
      payment = Payment.find_by(stripe_payment_intent_id: payment_intent.id)
      order = payment&.order || Order.find_by(stripe_payment_intent_id: payment_intent.id)

      if order
        order.update!(payment_status: "completed", status: "paid")
      end

      if payment
        payment.update!(status: "succeeded")
      elsif order
        order.payments.create!(
          stripe_payment_intent_id: payment_intent.id,
          amount_cents: payment_intent.amount,
          currency: payment_intent.currency,
          status: "succeeded",
          payment_method: "Stripe",
          customer_email: order.customer_email
        )
      end
      Rails.logger.info "PaymentIntent #{payment_intent.id} marked succeeded via webhook"

    when "payment_intent.payment_failed"
      payment_intent = event.data.object
      payment = Payment.find_by(stripe_payment_intent_id: payment_intent.id)
      order = payment&.order || Order.find_by(stripe_payment_intent_id: payment_intent.id)

      if order
        order.update!(payment_status: "failed")
      end

      if payment
        payment.update!(
          status: "failed",
          error_message: payment_intent.last_payment_error&.message
        )
      elsif order
        order.payments.create!(
          stripe_payment_intent_id: payment_intent.id,
          amount_cents: payment_intent.amount,
          currency: payment_intent.currency,
          status: "failed",
          payment_method: "Stripe",
          customer_email: order.customer_email,
          error_message: payment_intent.last_payment_error&.message
        )
      end
      Rails.logger.warn "PaymentIntent #{payment_intent.id} failed via webhook"
    end

    render json: { received: true }, status: :ok
  end
end
