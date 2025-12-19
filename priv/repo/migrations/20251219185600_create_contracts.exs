defmodule Overbooked.Repo.Migrations.CreateContracts do
  use Ecto.Migration

  def change do
    create table(:contracts) do
      add :status, :string, null: false, default: "pending"
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :duration_months, :integer, null: false
      add :monthly_rate_cents, :integer, null: false
      add :total_amount_cents, :integer, null: false

      # Stripe payment fields
      add :stripe_checkout_session_id, :string
      add :stripe_payment_intent_id, :string
      add :stripe_customer_id, :string

      add :resource_id, references(:resources, on_delete: :restrict), null: false
      add :user_id, references(:users, on_delete: :restrict), null: false

      timestamps()
    end

    create index(:contracts, [:resource_id])
    create index(:contracts, [:user_id])
    create index(:contracts, [:status])
    create unique_index(:contracts, [:stripe_checkout_session_id], where: "stripe_checkout_session_id IS NOT NULL")
  end
end
