defmodule Overbooked.Repo.Migrations.AddRefundFieldsToContracts do
  use Ecto.Migration

  def change do
    alter table(:contracts) do
      add :refund_amount_cents, :integer
      add :refund_id, :string
      add :refunded_at, :utc_datetime
    end

    create index(:contracts, [:refund_id])
  end
end
