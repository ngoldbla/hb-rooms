defmodule Overbooked.Repo.Migrations.AddReminderSentToBookings do
  use Ecto.Migration

  def change do
    alter table(:bookings) do
      add :reminder_sent_at, :utc_datetime
    end

    create index(:bookings, [:reminder_sent_at])
    create index(:bookings, [:start_at])
  end
end
