defmodule Overbooked.Contracts.Contract do
  @moduledoc """
  Schema for long-term office space rental contracts.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "contracts" do
    field :status, Ecto.Enum, values: [:pending, :active, :cancelled, :expired], default: :pending
    field :start_date, :date
    field :end_date, :date
    field :duration_months, :integer
    field :monthly_rate_cents, :integer
    field :total_amount_cents, :integer

    # Stripe payment fields
    field :stripe_checkout_session_id, :string
    field :stripe_payment_intent_id, :string
    field :stripe_customer_id, :string

    belongs_to :resource, Overbooked.Resources.Resource
    belongs_to :user, Overbooked.Accounts.User

    timestamps()
  end

  @required_fields [:start_date, :end_date, :duration_months, :monthly_rate_cents, :total_amount_cents, :resource_id, :user_id]
  @optional_fields [:status, :stripe_checkout_session_id, :stripe_payment_intent_id, :stripe_customer_id]

  @doc false
  def changeset(contract, attrs) do
    contract
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:duration_months, [1, 3])
    |> validate_number(:monthly_rate_cents, greater_than: 0)
    |> validate_number(:total_amount_cents, greater_than: 0)
    |> validate_dates()
    |> foreign_key_constraint(:resource_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:stripe_checkout_session_id)
  end

  @doc """
  Changeset for activating a contract after successful payment.
  """
  def activate_changeset(contract, attrs) do
    contract
    |> cast(attrs, [:status, :stripe_checkout_session_id, :stripe_payment_intent_id, :stripe_customer_id])
    |> put_change(:status, :active)
  end

  @doc """
  Changeset for cancelling a contract.
  """
  def cancel_changeset(contract) do
    contract
    |> change()
    |> put_change(:status, :cancelled)
  end

  defp validate_dates(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && Date.compare(end_date, start_date) != :gt do
      add_error(changeset, :end_date, "must be after start date")
    else
      changeset
    end
  end
end
