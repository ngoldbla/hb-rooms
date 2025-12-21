defmodule Overbooked.Contracts do
  @moduledoc """
  The Contracts context for managing long-term office space rentals.
  """

  import Ecto.Query, warn: false
  alias Overbooked.Repo

  alias Overbooked.Contracts.Contract
  alias Overbooked.Resources.Resource
  alias Overbooked.Accounts.User
  alias Overbooked.Schedule

  @doc """
  Creates a pending contract before checkout.
  """
  def create_pending_contract(%Resource{} = resource, %User{} = user, duration_months) do
    start_date = Date.utc_today()
    end_date = Date.add(start_date, duration_months * 30)
    monthly_rate = resource.monthly_rate_cents
    total = calculate_total(monthly_rate, duration_months)

    %Contract{}
    |> Contract.changeset(%{
      status: :pending,
      start_date: start_date,
      end_date: end_date,
      duration_months: duration_months,
      monthly_rate_cents: monthly_rate,
      total_amount_cents: total,
      resource_id: resource.id,
      user_id: user.id
    })
    |> Repo.insert()
  end

  @doc """
  Activates a contract after successful payment via webhook.
  """
  def activate_contract_by_session_id(session_id, payment_attrs) do
    case get_contract_by_session_id(session_id) do
      nil ->
        {:error, :contract_not_found}

      contract ->
        Repo.transaction(fn ->
          # Update contract with payment info and activate
          {:ok, contract} =
            contract
            |> Contract.activate_changeset(payment_attrs)
            |> Repo.update()

          # Create the booking to block the calendar
          resource = Repo.get!(Resource, contract.resource_id)
          user = Repo.get!(User, contract.user_id)

          {:ok, _booking} =
            Schedule.book_resource(resource, user, %{
              start_at: DateTime.new!(contract.start_date, ~T[00:00:00], "Etc/UTC"),
              end_at: DateTime.new!(contract.end_date, ~T[23:59:59], "Etc/UTC")
            })

          contract
        end)
    end
  end

  @doc """
  Creates a contract from Stripe checkout metadata and activates it.
  Used when contract wasn't pre-created.
  """
  def create_and_activate_contract(attrs) do
    start_date = Date.utc_today()
    end_date = Date.add(start_date, attrs.duration_months * 30)
    total = calculate_total(attrs.monthly_rate_cents, attrs.duration_months)

    contract_attrs = %{
      status: :active,
      start_date: start_date,
      end_date: end_date,
      duration_months: attrs.duration_months,
      monthly_rate_cents: attrs.monthly_rate_cents,
      total_amount_cents: total,
      resource_id: attrs.resource_id,
      user_id: attrs.user_id,
      stripe_checkout_session_id: attrs.stripe_checkout_session_id,
      stripe_payment_intent_id: attrs.stripe_payment_intent_id,
      stripe_customer_id: attrs.stripe_customer_id
    }

    Repo.transaction(fn ->
      {:ok, contract} =
        %Contract{}
        |> Contract.changeset(contract_attrs)
        |> Repo.insert()

      # Create the booking to block the calendar
      resource = Repo.get!(Resource, attrs.resource_id)
      user = Repo.get!(User, attrs.user_id)

      case Schedule.book_resource(resource, user, %{
             start_at: DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC"),
             end_at: DateTime.new!(end_date, ~T[23:59:59], "Etc/UTC")
           }) do
        {:ok, _booking} ->
          contract

        {:error, :resource_busy} ->
          Repo.rollback(:resource_busy)
      end
    end)
  end

  @doc """
  Updates a contract with Stripe session ID after checkout is initiated.
  """
  def update_contract_session_id(%Contract{} = contract, session_id) do
    contract
    |> Ecto.Changeset.change(%{stripe_checkout_session_id: session_id})
    |> Repo.update()
  end

  @doc """
  Gets a contract by its ID.
  """
  def get_contract!(id) do
    Repo.get!(Contract, id)
    |> Repo.preload([:resource, :user])
  end

  @doc """
  Gets a contract by Stripe checkout session ID.
  """
  def get_contract_by_session_id(session_id) do
    from(c in Contract, where: c.stripe_checkout_session_id == ^session_id)
    |> Repo.one()
  end

  @doc """
  Lists all contracts for a user.
  """
  def list_user_contracts(%User{} = user) do
    from(c in Contract,
      where: c.user_id == ^user.id,
      order_by: [desc: c.inserted_at],
      preload: [:resource]
    )
    |> Repo.all()
  end

  @doc """
  Lists all active contracts.
  """
  def list_active_contracts do
    from(c in Contract,
      where: c.status == :active,
      order_by: [desc: c.start_date],
      preload: [:resource, :user]
    )
    |> Repo.all()
  end

  @doc """
  Lists all contracts with optional status filter.
  For admin view.
  """
  def list_all_contracts(opts \\ []) do
    status_filter = Keyword.get(opts, :status)

    query =
      from(c in Contract,
        order_by: [desc: c.inserted_at],
        preload: [:resource, :user]
      )

    query =
      if status_filter && status_filter != "" && status_filter != "all" do
        status_atom = String.to_existing_atom(status_filter)
        from(c in query, where: c.status == ^status_atom)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets the Stripe customer ID for a user from their most recent contract.
  Returns nil if no customer ID is found.
  """
  def get_stripe_customer_id_for_user(%User{} = user) do
    from(c in Contract,
      where: c.user_id == ^user.id,
      where: not is_nil(c.stripe_customer_id),
      order_by: [desc: c.inserted_at],
      limit: 1,
      select: c.stripe_customer_id
    )
    |> Repo.one()
  end

  @doc """
  Gets a contract by its Stripe payment intent ID.
  """
  def get_contract_by_payment_intent(payment_intent_id) do
    from(c in Contract,
      where: c.stripe_payment_intent_id == ^payment_intent_id,
      preload: [:resource, :user]
    )
    |> Repo.one()
  end

  @doc """
  Admin cancel - cancels a contract without user authorization check.
  """
  def admin_cancel_contract(%Contract{} = contract) do
    contract
    |> Contract.cancel_changeset()
    |> Repo.update()
    |> case do
      {:ok, cancelled_contract} ->
        send_cancellation_email(cancelled_contract)
        {:ok, cancelled_contract}

      error ->
        error
    end
  end

  @doc """
  Checks if a resource is available for a new contract during the given period.
  """
  def resource_available_for_contract?(%Resource{} = resource, start_date, end_date) do
    from(c in Contract,
      where: c.resource_id == ^resource.id,
      where: c.status == :active,
      where: not (c.end_date < ^start_date or c.start_date > ^end_date)
    )
    |> Repo.exists?()
    |> Kernel.not()
  end

  @doc """
  Cancels a contract.
  """
  def cancel_contract(%Contract{} = contract, %User{} = user) do
    if contract.user_id == user.id do
      contract
      |> Contract.cancel_changeset()
      |> Repo.update()
      |> case do
        {:ok, cancelled_contract} ->
          send_cancellation_email(cancelled_contract)
          {:ok, cancelled_contract}

        error ->
          error
      end
    else
      {:error, :unauthorized}
    end
  end

  defp send_cancellation_email(contract) do
    contract = Repo.preload(contract, [:user, :resource])

    case Overbooked.Accounts.UserNotifier.deliver_contract_cancelled(contract.user, contract) do
      {:ok, _email} ->
        :ok

      {:error, reason} ->
        require Logger
        Logger.error("Failed to send contract cancellation email: #{inspect(reason)}")
        :error
    end
  end

  @doc """
  Calculates the total price for a contract.
  3-month contracts get a 10% discount.
  """
  def calculate_total(monthly_rate_cents, 3) do
    trunc(monthly_rate_cents * 3 * 0.9)
  end

  def calculate_total(monthly_rate_cents, months) do
    monthly_rate_cents * months
  end

  @doc """
  Formats a price in cents to a human-readable string.
  """
  def format_price(cents) when is_integer(cents) do
    dollars = cents / 100
    "$#{:erlang.float_to_binary(dollars, decimals: 2)}"
  end

  def format_price(_), do: "$0.00"

  @doc """
  Initiates a refund for a contract through Stripe.
  Amount can be nil for full refund or a specific amount in cents.
  """
  def initiate_refund(%Contract{} = contract, amount_cents \\ nil) do
    unless contract.stripe_payment_intent_id do
      {:error, :no_payment_intent}
    else
      case Overbooked.Stripe.create_refund(contract.stripe_payment_intent_id, amount_cents) do
        {:ok, refund} ->
          record_refund(contract, refund)

        {:error, %Stripe.Error{message: message}} ->
          {:error, message}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Records a refund on a contract (called by webhook or after initiate_refund).
  """
  def record_refund(%Contract{} = contract, refund) do
    attrs = %{
      refund_amount_cents: refund.amount,
      refund_id: refund.id,
      refunded_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    contract
    |> Contract.refund_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_contract} ->
        send_refund_email(updated_contract)
        {:ok, updated_contract}

      error ->
        error
    end
  end

  @doc """
  Records a refund on a contract by payment intent ID (used by webhook).
  """
  def record_refund_by_payment_intent(payment_intent_id, refund) do
    case get_contract_by_payment_intent(payment_intent_id) do
      nil ->
        {:error, :contract_not_found}

      contract ->
        record_refund(contract, refund)
    end
  end

  defp send_refund_email(contract) do
    contract = Repo.preload(contract, [:user, :resource])

    case Overbooked.Accounts.UserNotifier.deliver_refund_notification(contract.user, contract) do
      {:ok, _email} ->
        :ok

      {:error, reason} ->
        require Logger
        Logger.error("Failed to send refund notification email: #{inspect(reason)}")
        :error
    end
  end
end
