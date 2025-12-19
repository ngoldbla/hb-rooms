defmodule Overbooked.Repo.Migrations.AddPricingToResources do
  use Ecto.Migration

  def change do
    alter table(:resources) do
      add :is_rentable, :boolean, default: false
      add :monthly_rate_cents, :integer
      add :description, :text
    end

    create index(:resources, [:is_rentable])
  end
end
