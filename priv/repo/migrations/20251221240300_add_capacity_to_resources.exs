defmodule Overbooked.Repo.Migrations.AddCapacityToResources do
  use Ecto.Migration

  def change do
    alter table(:resources) do
      add :capacity, :integer, default: 1
    end

    create index(:resources, [:capacity])
  end
end
