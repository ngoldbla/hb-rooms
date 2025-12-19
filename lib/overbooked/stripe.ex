defmodule Overbooked.Stripe do
  @moduledoc """
  Stripe integration for office space contracts.
  Handles checkout session creation and payment processing.
  """

  alias Overbooked.Contracts
  alias Overbooked.Resources.Resource
  alias Overbooked.Accounts.User

  @doc """
  Creates a Stripe Checkout Session for a contract.

  ## Parameters
    - resource: The office space resource being rented
    - duration_months: Contract duration (1 or 3 months)
    - user: The user making the purchase
    - success_url: URL to redirect to on successful payment
    - cancel_url: URL to redirect to if payment is cancelled

  ## Returns
    - `{:ok, session}` on success with the Stripe session
    - `{:error, reason}` on failure
  """
  def create_checkout_session(%Resource{} = resource, duration_months, %User{} = user, success_url, cancel_url) do
    monthly_rate = resource.monthly_rate_cents
    total = Contracts.calculate_total(monthly_rate, duration_months)
    start_date = Date.utc_today()
    end_date = Date.add(start_date, duration_months * 30)

    line_item_name = "#{resource.name} - #{duration_months} Month Contract"

    line_item_description =
      "Office space rental from #{format_date(start_date)} to #{format_date(end_date)}"

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
      metadata: %{
        resource_id: to_string(resource.id),
        user_id: to_string(user.id),
        duration_months: to_string(duration_months),
        monthly_rate_cents: to_string(monthly_rate)
      },
      success_url: success_url,
      cancel_url: cancel_url
    }

    Stripe.Checkout.Session.create(params)
  end

  @doc """
  Retrieves a Stripe Checkout Session by ID.
  """
  def get_checkout_session(session_id) do
    Stripe.Checkout.Session.retrieve(session_id)
  end

  @doc """
  Constructs and validates a Stripe webhook event.
  """
  def construct_webhook_event(payload, signature, webhook_secret) do
    Stripe.Webhook.construct_event(payload, signature, webhook_secret)
  end

  defp format_date(%Date{} = date) do
    Calendar.strftime(date, "%B %d, %Y")
  end
end
