defmodule Overbooked.Schedule.RecurringRule do
  @moduledoc """
  Schema for recurring booking rules.
  
  A recurring rule defines a pattern for repeating bookings:
  - `daily` - every N days
  - `weekly` - specific days of the week, every N weeks
  - `biweekly` - every 2 weeks on specific days
  - `monthly` - same day of month, every N months
  """
  use Ecto.Schema
  import Ecto.Changeset

  @patterns ~w(daily weekly biweekly monthly)

  schema "recurring_rules" do
    field :pattern, :string
    field :interval, :integer, default: 1
    field :days_of_week, {:array, :integer}, default: []
    field :start_date, :date
    field :end_date, :date
    field :max_occurrences, :integer
    field :start_time, :time
    field :end_time, :time

    belongs_to :user, Overbooked.Accounts.User
    belongs_to :resource, Overbooked.Resources.Resource
    has_many :bookings, Overbooked.Schedule.Booking

    timestamps()
  end

  @doc false
  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [
      :pattern,
      :interval,
      :days_of_week,
      :start_date,
      :end_date,
      :max_occurrences,
      :start_time,
      :end_time
    ])
    |> validate_required([:pattern, :interval, :start_date, :start_time, :end_time])
    |> validate_inclusion(:pattern, @patterns)
    |> validate_number(:interval, greater_than: 0)
    |> validate_end_or_occurrences()
    |> validate_days_of_week()
    |> validate_end_after_start_time()
  end

  defp validate_end_or_occurrences(changeset) do
    end_date = get_field(changeset, :end_date)
    max_occurrences = get_field(changeset, :max_occurrences)

    if is_nil(end_date) and is_nil(max_occurrences) do
      add_error(changeset, :end_date, "either end_date or max_occurrences must be set")
    else
      changeset
    end
  end

  defp validate_days_of_week(changeset) do
    pattern = get_field(changeset, :pattern)
    days = get_field(changeset, :days_of_week) || []

    cond do
      pattern in ["weekly", "biweekly"] and Enum.empty?(days) ->
        add_error(changeset, :days_of_week, "must specify days of week for weekly/biweekly patterns")

      not Enum.all?(days, &(&1 >= 1 and &1 <= 7)) ->
        add_error(changeset, :days_of_week, "days must be between 1 (Monday) and 7 (Sunday)")

      true ->
        changeset
    end
  end

  defp validate_end_after_start_time(changeset) do
    start_time = get_field(changeset, :start_time)
    end_time = get_field(changeset, :end_time)

    if start_time && end_time && Time.compare(end_time, start_time) != :gt do
      add_error(changeset, :end_time, "must be after start time")
    else
      changeset
    end
  end

  def put_user(%Ecto.Changeset{} = changeset, %Overbooked.Accounts.User{} = user) do
    put_assoc(changeset, :user, user)
  end

  def put_resource(%Ecto.Changeset{} = changeset, %Overbooked.Resources.Resource{} = resource) do
    put_assoc(changeset, :resource, resource)
  end

  @doc "Returns the list of valid patterns"
  def patterns, do: @patterns
end
