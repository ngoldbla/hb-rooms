defmodule Overbooked.Repo.Migrations.CreateStripeSettings do
  use Ecto.Migration

  def change do
    create table(:stripe_settings) do
      add :enabled, :boolean, default: false
      add :secret_key, :string
      add :publishable_key, :string
      add :webhook_secret, :string
      add :environment, :string, default: "test"

      timestamps()
    end

    # Ensure only one row exists (singleton pattern)
    create unique_index(:stripe_settings, [:id], name: :stripe_settings_singleton, where: "id IS NOT NULL")
  end
end
