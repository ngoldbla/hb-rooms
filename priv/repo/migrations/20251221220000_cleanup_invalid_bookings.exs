defmodule Overbooked.Repo.Migrations.CleanupInvalidBookings do
  use Ecto.Migration

  def up do
    # Delete bookings where end_at is before or equal to start_at
    # These are invalid and cause internal server errors
    execute """
    DELETE FROM bookings
    WHERE end_at <= start_at
    """
  end

  def down do
    # Cannot restore deleted bookings
    :ok
  end
end
