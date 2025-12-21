defmodule Overbooked.Workers.NotificationSweeper do
  @moduledoc """
  Oban cron worker that finds bookings and contracts needing notifications
  and enqueues individual notification jobs.

  Runs every 15 minutes via Oban.Plugins.Cron.

  - Booking reminders: Sent 24 hours before start time
  - Contract expiration warnings: Sent 7 days before end date
  """
  use Oban.Worker, queue: :default, max_attempts: 1

  import Ecto.Query
  alias Overbooked.Repo
  alias Overbooked.Schedule.Booking
  alias Overbooked.Contracts.Contract
  alias Overbooked.Workers.{BookingReminderWorker, ContractExpirationWorker}

  require Logger

  @booking_reminder_hours 24
  @contract_warning_days 7

  @impl Oban.Worker
  def perform(_job) do
    Logger.info("NotificationSweeper: Starting sweep")

    booking_count = sweep_booking_reminders()
    contract_count = sweep_contract_expirations()

    Logger.info("NotificationSweeper: Queued #{booking_count} booking reminders, #{contract_count} contract warnings")

    :ok
  end

  defp sweep_booking_reminders do
    now = DateTime.utc_now()
    reminder_window_start = DateTime.add(now, @booking_reminder_hours, :hour)
    # Give a 20-minute buffer for the 15-minute sweep interval
    reminder_window_end = DateTime.add(reminder_window_start, 20, :minute)

    bookings =
      from(b in Booking,
        where: is_nil(b.reminder_sent_at),
        where: b.start_at >= ^reminder_window_start,
        where: b.start_at < ^reminder_window_end,
        select: b.id
      )
      |> Repo.all()

    Enum.each(bookings, fn booking_id ->
      %{booking_id: booking_id}
      |> BookingReminderWorker.new()
      |> Oban.insert()
    end)

    length(bookings)
  end

  defp sweep_contract_expirations do
    today = Date.utc_today()
    warning_date = Date.add(today, @contract_warning_days)

    contracts =
      from(c in Contract,
        where: c.status == :active,
        where: is_nil(c.expiration_warning_sent_at),
        where: c.end_date == ^warning_date,
        select: c.id
      )
      |> Repo.all()

    Enum.each(contracts, fn contract_id ->
      %{contract_id: contract_id, days_remaining: @contract_warning_days}
      |> ContractExpirationWorker.new()
      |> Oban.insert()
    end)

    length(contracts)
  end
end
