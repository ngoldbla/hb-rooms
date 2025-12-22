defmodule Overbooked.Schedule do
  @moduledoc """
  The Schedule context.
  """

  import Ecto.Query, warn: false
  alias Overbooked.Repo
  alias Ecto.Multi

  alias Overbooked.Schedule.Booking
  alias Overbooked.Schedule.RecurringRule
  alias Overbooked.Schedule.RecurringExpander
  alias Overbooked.Resources.Resource
  alias Overbooked.Accounts.User

  def resource_busy?(%Resource{} = resource, start_at, end_at) do
    from(b in Booking,
      where: b.resource_id == ^resource.id,
      where:
        (^start_at >= b.start_at and ^start_at < b.end_at) or
          (^end_at > b.start_at and ^end_at <= b.end_at)
    )
    |> Repo.exists?()
  end

  def resource_busy?(%Resource{} = resource, start_at, end_at, booking) do
    from(b in Booking,
      where: b.resource_id == ^resource.id,
      where:
        (^start_at >= b.start_at and ^start_at < b.end_at) or
          (^end_at > b.start_at and ^end_at <= b.end_at),
      where: b.id != ^booking.id
    )
    |> Repo.exists?()
  end

  def book_resource(%Resource{} = resource, %User{} = user, attrs \\ %{}) do
    end_at = attrs["end_at"] || attrs[:end_at]
    start_at = attrs["start_at"] || attrs[:start_at]

    if resource_busy?(resource, start_at, end_at) do
      {:error, :resource_busy}
    else
      %Booking{}
      |> Booking.changeset(attrs)
      |> Booking.put_resource(resource)
      |> Booking.put_user(user)
      |> Repo.insert()
    end
  end

  def list_bookings(start_at, end_at) do
    from(b in Booking,
      where: ^start_at <= b.end_at and b.start_at <= ^end_at,
      order_by: b.start_at,
      preload: [resource: [:resource_type], user: [], recurring_rule: []]
    )
    |> Repo.all()
  end

  def list_bookings(start_at, end_at, %Resource{} = resource) do
    from(b in Booking,
      where: b.resource_id == ^resource.id,
      where: ^start_at <= b.end_at and b.start_at <= ^end_at,
      order_by: b.start_at,
      preload: [resource: [:resource_type], user: [], recurring_rule: []]
    )
    |> Repo.all()
  end

  def list_bookings(start_at, end_at, %User{} = user) do
    from(b in Booking,
      where: b.user_id == ^user.id,
      where: ^start_at <= b.end_at and b.start_at <= ^end_at,
      order_by: b.start_at,
      preload: [resource: [:resource_type], user: [], recurring_rule: []]
    )
    |> Repo.all()
  end

  def booking_groups(bookings, :hourly) do
    bookings
    |> Enum.map(fn b ->
      Timex.Interval.new(from: b.start_at, until: b.end_at, step: [minutes: 15])
      |> Enum.map(fn d -> {d, b} end)
    end)
    |> List.flatten()
    |> Enum.group_by(fn {d, _} -> Timex.day(d) end)
    |> Enum.map(fn {d, slots} ->
      slots =
        slots
        |> Enum.sort_by(fn {_d, b} -> Map.fetch!(b, :id) end)
        |> Enum.group_by(
          fn {d, _} ->
            Timex.format!(d, "%H:%M", :strftime)
          end,
          fn {_, b} ->
            b
          end
        )

      {d, slots}
    end)
    |> Enum.map(fn {d, slots} -> Map.put(%{}, d, slots) end)
    |> Enum.reduce(%{}, fn slots, map ->
      Map.merge(slots, map, fn _k, v1, v2 -> v2 ++ v1 end)
    end)
  end

  def booking_groups(bookings, :daily) do
    bookings
    |> Enum.map(fn b ->
      Timex.Interval.new(from: b.start_at, until: b.end_at, step: [days: 1])
      |> Enum.map(fn i -> {i, b} end)
      |> Enum.group_by(
        fn {i, _b} -> Timex.day(i) end,
        fn {_, b} ->
          b
        end
      )
    end)
    |> List.flatten()
    |> Enum.reduce(%{}, fn slots, map ->
      Map.merge(slots, map, fn _k, v1, v2 -> v2 ++ v1 end)
    end)
  end

  def get_booking!(id), do: Repo.get!(Booking, id) |> Repo.preload([:recurring_rule])

  def update_booking(
        %Booking{user_id: user_id} = booking,
        %Resource{} = resource,
        %User{id: user_id},
        attrs
      ) do
    if resource_busy?(resource, attrs[:start_at], attrs[:end_at], booking) do
      {:error, :resource_busy}
    else
      booking
      |> Booking.changeset(attrs)
      |> Repo.update()
    end
  end

  def delete_booking(%Booking{user_id: user_id} = booking, %User{id: user_id}) do
    Repo.delete(booking)
  end

  def change_booking(%Booking{} = booking, attrs \\ %{}) do
    Booking.changeset(booking, attrs)
  end

  # ============================================================================
  # Recurring Bookings
  # ============================================================================

  @doc """
  Creates a recurring booking rule and all its expanded bookings atomically.
  
  Returns `{:ok, %{rule: rule, bookings: bookings}}` on success.
  Returns `{:error, :conflict, conflicting_booking}` if any date conflicts.
  Returns `{:error, step, changeset, changes}` on validation failure.
  """
  def create_recurring_booking(%Resource{} = resource, %User{} = user, attrs) do
    changeset =
      %RecurringRule{}
      |> RecurringRule.changeset(attrs)
      |> RecurringRule.put_user(user)
      |> RecurringRule.put_resource(resource)

    if changeset.valid? do
      # Build the rule struct to expand
      rule = Ecto.Changeset.apply_changes(changeset)
      
      # Expand to get all booking dates
      booking_attrs_list = RecurringExpander.expand_rule(rule)
      
      # Check for conflicts first
      case find_conflicts(resource, booking_attrs_list) do
        {:conflict, conflicting} ->
          {:error, :conflict, conflicting}
          
        :ok ->
          # Build the multi transaction
          multi =
            Multi.new()
            |> Multi.insert(:rule, changeset)
            |> insert_recurring_bookings(resource, user, booking_attrs_list)
          
          Repo.transaction(multi)
      end
    else
      {:error, :rule, changeset, %{}}
    end
  end

  defp insert_recurring_bookings(multi, resource, user, booking_attrs_list) do
    booking_attrs_list
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {attrs, index}, acc ->
      Multi.insert(acc, {:booking, index}, fn %{rule: rule} ->
        %Booking{}
        |> Booking.changeset(attrs)
        |> Booking.put_resource(resource)
        |> Booking.put_user(user)
        |> Ecto.Changeset.put_assoc(:recurring_rule, rule)
      end)
    end)
  end

  defp find_conflicts(resource, booking_attrs_list) do
    Enum.find_value(booking_attrs_list, :ok, fn attrs ->
      if resource_busy?(resource, attrs.start_at, attrs.end_at) do
        {:conflict, attrs}
      else
        nil
      end
    end)
  end

  @doc """
  Previews the dates for a recurring booking without creating it.
  Returns list of dates that would be booked.
  """
  def preview_recurring_dates(attrs) do
    changeset = RecurringRule.changeset(%RecurringRule{}, attrs)
    
    if changeset.valid? do
      rule = Ecto.Changeset.apply_changes(changeset)
      dates = RecurringExpander.generate_occurrences(rule)
      {:ok, dates}
    else
      {:error, changeset}
    end
  end

  @doc """
  Deletes a single occurrence from a recurring series.
  The rule remains and other bookings are kept.
  """
  def delete_single_occurrence(%Booking{user_id: user_id} = booking, %User{id: user_id}) do
    Repo.delete(booking)
  end

  @doc """
  Deletes an entire recurring series (rule and all bookings).
  Due to cascade delete, deleting the rule removes all bookings.
  """
  def delete_recurring_series(%RecurringRule{user_id: user_id} = rule, %User{id: user_id}) do
    Repo.delete(rule)
  end

  def delete_recurring_series(%Booking{recurring_rule_id: rule_id, user_id: user_id}, %User{id: user_id}) when not is_nil(rule_id) do
    rule = Repo.get!(RecurringRule, rule_id)
    Repo.delete(rule)
  end

  @doc """
  Lists all recurring rules for a user.
  """
  def list_recurring_rules(%User{} = user) do
    from(r in RecurringRule,
      where: r.user_id == ^user.id,
      order_by: [desc: r.inserted_at],
      preload: [:resource, :bookings]
    )
    |> Repo.all()
  end

  @doc """
  Gets a recurring rule by ID.
  """
  def get_recurring_rule!(id) do
    Repo.get!(RecurringRule, id)
    |> Repo.preload([:resource, :user, :bookings])
  end

  @doc """
  Changes a recurring rule for form presentation.
  """
  def change_recurring_rule(%RecurringRule{} = rule, attrs \\ %{}) do
    RecurringRule.changeset(rule, attrs)
  end

  @doc """
  Checks if a booking is part of a recurring series.
  """
  def recurring_booking?(%Booking{recurring_rule_id: nil}), do: false
  def recurring_booking?(%Booking{recurring_rule_id: _}), do: true
end

