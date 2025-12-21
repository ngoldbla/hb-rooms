defmodule Overbooked.Workers.BookingReminderWorker do
  @moduledoc """
  Oban worker that sends booking reminder emails.
  Triggered by the NotificationSweeper for bookings starting in ~24 hours.
  """
  use Oban.Worker, queue: :notifications, max_attempts: 3

  alias Overbooked.Repo
  alias Overbooked.Schedule.Booking
  alias Overbooked.Accounts.UserNotifier

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"booking_id" => booking_id}}) do
    booking =
      Repo.get(Booking, booking_id)
      |> Repo.preload([:resource, :user])

    case booking do
      nil ->
        Logger.warning("BookingReminderWorker: Booking #{booking_id} not found")
        :ok

      %Booking{reminder_sent_at: sent} when not is_nil(sent) ->
        Logger.info("BookingReminderWorker: Reminder already sent for booking #{booking_id}")
        :ok

      booking ->
        send_reminder(booking)
    end
  end

  defp send_reminder(booking) do
    case UserNotifier.deliver_booking_reminder(booking.user, booking) do
      {:ok, _email} ->
        # Mark reminder as sent
        booking
        |> Ecto.Changeset.change(%{reminder_sent_at: DateTime.utc_now() |> DateTime.truncate(:second)})
        |> Repo.update!()

        Logger.info("BookingReminderWorker: Sent reminder for booking #{booking.id}")
        :ok

      {:error, reason} ->
        Logger.error("BookingReminderWorker: Failed to send reminder for booking #{booking.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
