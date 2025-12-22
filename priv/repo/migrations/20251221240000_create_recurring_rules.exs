defmodule Overbooked.Repo.Migrations.CreateRecurringRules do
  use Ecto.Migration

  def change do
    create table(:recurring_rules) do
      add :pattern, :string, null: false
      add :interval, :integer, null: false, default: 1
      add :days_of_week, {:array, :integer}, default: []
      add :start_date, :date, null: false
      add :end_date, :date
      add :max_occurrences, :integer
      add :start_time, :time, null: false
      add :end_time, :time, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :resource_id, references(:resources, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:recurring_rules, [:user_id])
    create index(:recurring_rules, [:resource_id])
  end
end
