defmodule OverbookedWeb.BillingController do
  @moduledoc """
  Controller for redirecting users to Stripe Billing Portal.
  """
  use OverbookedWeb, :controller

  alias Overbooked.Contracts
  alias Overbooked.Stripe

  @doc """
  Redirects the user to Stripe's Customer Portal for managing billing.
  Requires the user to have at least one contract with a Stripe customer ID.
  """
  def portal(conn, _params) do
    user = conn.assigns.current_user
    return_url = OverbookedWeb.Endpoint.url() <> "/contracts"

    case Contracts.get_stripe_customer_id_for_user(user) do
      nil ->
        conn
        |> put_flash(:error, "No billing information found. You need an active contract to manage billing.")
        |> redirect(to: "/contracts")

      customer_id ->
        case Stripe.create_portal_session(customer_id, return_url) do
          {:ok, session} ->
            redirect(conn, external: session.url)

          {:error, %Stripe.Error{message: message}} ->
            conn
            |> put_flash(:error, "Could not access billing portal: #{message}")
            |> redirect(to: "/contracts")

          {:error, message} when is_binary(message) ->
            conn
            |> put_flash(:error, message)
            |> redirect(to: "/contracts")
        end
    end
  end
end
