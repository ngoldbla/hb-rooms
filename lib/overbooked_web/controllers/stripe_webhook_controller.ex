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

    # Add accepted terms version if present in metadata
    attrs =
      case metadata["accepted_terms_version"] do
        nil -> attrs
        version -> Map.put(attrs, :accepted_terms_version, String.to_integer(version))
      end

    case Contracts.create_and_activate_contract(attrs) do
      {:ok, contract} ->
        Logger.info("Contract #{contract.id} activated successfully")
        send_contract_confirmation_email(contract)
        :ok

      {:error, :resource_busy} ->
        Logger.error("Failed to activate contract: resource is busy, initiating refund")
        # Initiate automatic refund when resource is not available
        case initiate_automatic_refund(session) do
          {:ok, _refund} ->
            Logger.info("Automatic refund initiated for session #{session.id}")

          {:error, reason} ->
            Logger.error("Failed to initiate automatic refund: #{inspect(reason)}")
        end

        :error

      {:error, reason} ->
        Logger.error("Failed to activate contract: #{inspect(reason)}")
        :error
    end
  end

  defp send_contract_confirmation_email(contract) do
    # Preload associations needed for the email
    contract = Overbooked.Repo.preload(contract, [:user, :resource])

    case Overbooked.Accounts.UserNotifier.deliver_contract_confirmation(contract.user, contract) do
      {:ok, _email} ->
        Logger.info("Contract confirmation email sent for contract #{contract.id}")

      {:error, reason} ->
        Logger.error("Failed to send contract confirmation email: #{inspect(reason)}")
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

  # Handle charge.refunded - record refund on contract
  defp handle_event("charge.refunded", event) do
    charge = event.data.object
    payment_intent_id = charge.payment_intent

    Logger.info("Processing charge.refunded for payment intent #{payment_intent_id}")

    # Get the most recent refund from the charge
    case charge.refunds do
      %{data: [refund | _]} ->
        case Contracts.record_refund_by_payment_intent(payment_intent_id, refund) do
          {:ok, contract} ->
            Logger.info("Refund recorded for contract #{contract.id}")
            :ok

          {:error, :contract_not_found} ->
            Logger.warn("No contract found for payment intent #{payment_intent_id}")
            :ok

          {:error, reason} ->
            Logger.error("Failed to record refund: #{inspect(reason)}")
            :error
        end

      _ ->
        Logger.warn("No refund data in charge.refunded event")
        :ok
    end
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

  # Initiate automatic refund when resource is not available
  defp initiate_automatic_refund(session) do
    case session.payment_intent do
      nil ->
        {:error, :no_payment_intent}

      payment_intent_id ->
        Overbooked.Stripe.create_refund(payment_intent_id, nil, :requested_by_customer)
    end
  end
end
