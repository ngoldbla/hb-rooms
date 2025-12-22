defmodule Overbooked.Repo.Migrations.AddBookingIndexes do
  use Ecto.Migration

  def change do
    # Performance indexes for availability search queries
    create index(:bookings, [:start_at])
    create index(:bookings, [:end_at])
    create index(:bookings, [:resource_id, :start_at, :end_at])
  end
end
