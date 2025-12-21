defmodule Overbooked.Repo.Migrations.AddExpirationWarningToContracts do
  use Ecto.Migration

  def change do
    alter table(:contracts) do
      add :expiration_warning_sent_at, :utc_datetime
    end

    create index(:contracts, [:expiration_warning_sent_at])
    create index(:contracts, [:end_date])
  end
end
