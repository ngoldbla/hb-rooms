defmodule Overbooked.Stripe do
  @moduledoc """
  Stripe integration for office space contracts.
  Handles checkout session creation and payment processing.

  Configuration is read from the database (via Settings context) with
  fallback to environment variables.
  """

  alias Overbooked.Contracts
  alias Overbooked.Resources.Resource
  alias Overbooked.Accounts.User
  alias Overbooked.Settings

  @doc """
  Creates a Stripe Checkout Session for a contract.

  ## Parameters
    - resource: The office space resource being rented
    - duration_months: Contract duration (1 or 3 months)
    - user: The user making the purchase
    - success_url: URL to redirect to on successful payment
    - cancel_url: URL to redirect to if payment is cancelled
    - accepted_terms_version: The version of contract terms the user accepted

  ## Returns
    - `{:ok, session}` on success with the Stripe session
    - `{:error, reason}` on failure
  """
  def create_checkout_session(%Resource{} = resource, duration_months, %User{} = user, success_url, cancel_url, accepted_terms_version \\ nil) do
    config = Settings.get_stripe_config()

    unless config.secret_key do
      {:error, "Stripe is not configured. Please configure Stripe in Admin → Settings."}
    else
      monthly_rate = resource.monthly_rate_cents
      total = Contracts.calculate_total(monthly_rate, duration_months)
      start_date = Date.utc_today()
      end_date = Date.add(start_date, duration_months * 30)

      line_item_name = "#{resource.name} - #{duration_months} Month Contract"

      line_item_description =
        "Office space rental from #{format_date(start_date)} to #{format_date(end_date)}"

      metadata = %{
        resource_id: to_string(resource.id),
        user_id: to_string(user.id),
        duration_months: to_string(duration_months),
        monthly_rate_cents: to_string(monthly_rate)
      }

      # Add accepted terms version to metadata if provided
      metadata =
        if accepted_terms_version do
          Map.put(metadata, :accepted_terms_version, to_string(accepted_terms_version))
        else
          metadata
        end

      params = %{
        mode: "payment",
        customer_email: user.email,
        line_items: [
          %{
            price_data: %{
              currency: "usd",
              unit_amount: total,
              product_data: %{
                name: line_item_name,
                description: line_item_description
              }
            },
            quantity: 1
          }
        ],
        metadata: metadata,
        success_url: success_url,
        cancel_url: cancel_url
      }

      Stripe.Checkout.Session.create(params, api_key: config.secret_key)
    end
  end

  @doc """
  Retrieves a Stripe Checkout Session by ID.
  """
  def get_checkout_session(session_id) do
    config = Settings.get_stripe_config()
    Stripe.Checkout.Session.retrieve(session_id, api_key: config.secret_key)
  end

  @doc """
  Constructs and validates a Stripe webhook event.
  Uses the webhook secret from Settings (DB) or environment.
  """
  def construct_webhook_event(payload, signature) do
    config = Settings.get_stripe_config()

    unless config.webhook_secret do
      {:error, "Webhook secret not configured"}
    else
      Stripe.Webhook.construct_event(payload, signature, config.webhook_secret)
    end
  end

  @doc """
  Constructs and validates a Stripe webhook event with explicit secret.
  Kept for backwards compatibility.
  """
  def construct_webhook_event(payload, signature, webhook_secret) do
    Stripe.Webhook.construct_event(payload, signature, webhook_secret)
  end

  @doc """
  Returns the current Stripe configuration source (:database or :environment).
  """
  def config_source do
    Settings.get_stripe_config().source
  end

  @doc """
  Creates a Stripe Billing Portal session for a customer to manage their billing.

  ## Parameters
    - customer_id: The Stripe customer ID
    - return_url: URL to redirect to when they're done

  ## Returns
    - `{:ok, session}` with the portal session URL
    - `{:error, reason}` on failure
  """
  def create_portal_session(customer_id, return_url) do
    config = Settings.get_stripe_config()

    unless config.secret_key do
      {:error, "Stripe is not configured. Please configure Stripe in Admin → Settings."}
    else
      params = %{
        customer: customer_id,
        return_url: return_url
      }

      Stripe.BillingPortal.Session.create(params, api_key: config.secret_key)
    end
  end

  @doc """
  Creates a refund for a payment intent.

  ## Parameters
    - payment_intent_id: The Stripe payment intent ID
    - amount_cents: Optional amount to refund (nil for full refund)
    - reason: Optional reason (:duplicate, :fraudulent, :requested_by_customer)

  ## Returns
    - `{:ok, refund}` on success
    - `{:error, reason}` on failure
  """
  def create_refund(payment_intent_id, amount_cents \\ nil, reason \\ :requested_by_customer) do
    config = Settings.get_stripe_config()

    unless config.secret_key do
      {:error, "Stripe is not configured. Please configure Stripe in Admin → Settings."}
    else
      params = %{payment_intent: payment_intent_id, reason: reason}

      params =
        if amount_cents do
          Map.put(params, :amount, amount_cents)
        else
          params
        end

      Stripe.Refund.create(params, api_key: config.secret_key)
    end
  end

  @doc """
  Retrieves a payment intent by ID.
  """
  def get_payment_intent(payment_intent_id) do
    config = Settings.get_stripe_config()
    Stripe.PaymentIntent.retrieve(payment_intent_id, %{}, api_key: config.secret_key)
  end

  defp format_date(%Date{} = date) do
    Calendar.strftime(date, "%B %d, %Y")
  end
end
