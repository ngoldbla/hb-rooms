defmodule Overbooked.Repo.Migrations.AddRecurringRuleToBookings do
  use Ecto.Migration

  def change do
    alter table(:bookings) do
      add :recurring_rule_id, references(:recurring_rules, on_delete: :delete_all)
    end

    create index(:bookings, [:recurring_rule_id])
  end
end
