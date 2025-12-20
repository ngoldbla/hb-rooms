defmodule OverbookedWeb.StripeWebhookController do
  @moduledoc """
  Handles Stripe webhook events for payment processing.
  """
  use OverbookedWeb, :controller

  alias Overbooked.Contracts

  require Logger

  @doc """
  Webhook endpoint for Stripe events.
  Verifies the webhook signature and processes supported events.
  Webhook secret is read from Settings (DB) with fallback to env vars.
  """
  def webhook(conn, _params) do
    payload = conn.assigns[:raw_body]
    signature = get_stripe_signature(conn)

    # Use the 2-arity version which gets secret from Settings
    case Overbooked.Stripe.construct_webhook_event(payload, signature) do
      {:ok, %Stripe.Event{type: type} = event} ->
        handle_event(type, event)
        send_resp(conn, 200, "OK")

      {:error, reason} ->
        Logger.error("Stripe webhook error: #{inspect(reason)}")
        send_resp(conn, 400, "Webhook Error")
    end
  end

  # Handle checkout.session.completed - payment successful
  defp handle_event("checkout.session.completed", event) do
    session = event.data.object

    Logger.info("Processing checkout.session.completed for session #{session.id}")

    metadata = session.metadata

    attrs = %{
      resource_id: String.to_integer(metadata["resource_id"]),
      user_id: String.to_integer(metadata["user_id"]),
      duration_months: String.to_integer(metadata["duration_months"]),
      monthly_rate_cents: String.to_integer(metadata["monthly_rate_cents"]),
      stripe_checkout_session_id: session.id,
      stripe_payment_intent_id: session.payment_intent,
      stripe_customer_id: session.customer
    }

    case Contracts.create_and_activate_contract(attrs) do
      {:ok, contract} ->
        Logger.info("Contract #{contract.id} activated successfully")
        # TODO: Send confirmation email
        :ok

      {:error, :resource_busy} ->
        Logger.error("Failed to activate contract: resource is busy")
        # TODO: Handle refund scenario
        :error

      {:error, reason} ->
        Logger.error("Failed to activate contract: #{inspect(reason)}")
        :error
    end
  end

  # Handle payment_intent.succeeded - additional confirmation
  defp handle_event("payment_intent.succeeded", event) do
    Logger.info("Payment intent succeeded: #{event.data.object.id}")
    :ok
  end

  # Handle payment_intent.payment_failed - payment failed
  defp handle_event("payment_intent.payment_failed", event) do
    Logger.warn("Payment failed: #{event.data.object.id}")
    :ok
  end

  # Ignore other events
  defp handle_event(type, _event) do
    Logger.debug("Ignoring Stripe event: #{type}")
    :ok
  end

  defp get_stripe_signature(conn) do
    case get_req_header(conn, "stripe-signature") do
      [signature | _] -> signature
      [] -> ""
    end
  end
end
