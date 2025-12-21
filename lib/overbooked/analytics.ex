defmodule Overbooked.Analytics do
  @moduledoc """
  The Analytics context for revenue tracking and space utilization metrics.
  """

  import Ecto.Query, warn: false
  alias Overbooked.Repo
  alias Overbooked.Contracts.Contract
  alias Overbooked.Schedule.Booking
  alias Overbooked.Resources.Resource

  @doc """
  Gets monthly revenue from active contracts for a specific year and month.
  Returns the total revenue in cents for contracts that were active during that month.
  """
  def monthly_revenue(year, month) do
    start_date = Date.new!(year, month, 1)
    end_date = Date.end_of_month(start_date)

    from(c in Contract,
      where: c.status == :active,
      where: c.start_date <= ^end_date,
      where: c.end_date >= ^start_date,
      select: sum(c.total_amount_cents)
    )
    |> Repo.one()
    |> case do
      nil -> 0
      amount -> amount
    end
  end

  @doc """
  Gets revenue by resource for a date range.
  Returns a list of %{resource_id, resource_name, revenue_cents}.
  """
  def revenue_by_resource(start_date, end_date) do
    from(c in Contract,
      join: r in Resource,
      on: c.resource_id == r.id,
      where: c.status == :active,
      where: c.start_date <= ^end_date,
      where: c.end_date >= ^start_date,
      group_by: [r.id, r.name],
      select: %{
        resource_id: r.id,
        resource_name: r.name,
        revenue_cents: sum(c.total_amount_cents)
      },
      order_by: [desc: sum(c.total_amount_cents)]
    )
    |> Repo.all()
  end

  @doc """
  Gets revenue trend over the last N months.
  Returns a list of %{month, year, revenue_cents} for charting.
  """
  def revenue_trend(months \\ 12) do
    today = Date.utc_today()
    start_date = Date.add(today, -months * 30)

    from(c in Contract,
      where: c.status == :active,
      where: c.start_date >= ^start_date,
      select: %{
        month: fragment("EXTRACT(MONTH FROM ?)", c.start_date),
        year: fragment("EXTRACT(YEAR FROM ?)", c.start_date),
        revenue_cents: sum(c.total_amount_cents)
      },
      group_by: [
        fragment("EXTRACT(YEAR FROM ?)", c.start_date),
        fragment("EXTRACT(MONTH FROM ?)", c.start_date)
      ],
      order_by: [
        fragment("EXTRACT(YEAR FROM ?)", c.start_date),
        fragment("EXTRACT(MONTH FROM ?)", c.start_date)
      ]
    )
    |> Repo.all()
  end

  @doc """
  Calculates space utilization percentage for a resource over a date range.
  Formula: (booked_minutes / available_minutes) * 100

  Assumes 24/7 availability for now. For business hours only,
  adjust available_minutes calculation accordingly.
  """
  def space_utilization(resource_id, start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
    end_datetime = DateTime.new!(end_date, ~T[23:59:59], "Etc/UTC")

    # Calculate total booked minutes
    booked_minutes =
      from(b in Booking,
        where: b.resource_id == ^resource_id,
        where: b.start_at >= ^start_datetime,
        where: b.end_at <= ^end_datetime,
        select:
          sum(
            fragment(
              "EXTRACT(EPOCH FROM (? - ?)) / 60",
              b.end_at,
              b.start_at
            )
          )
      )
      |> Repo.one()
      |> case do
        nil -> 0
        %Decimal{} = minutes -> minutes |> Decimal.to_float() |> trunc()
        minutes -> trunc(minutes)
      end

    # Calculate total available minutes (24/7)
    available_minutes = DateTime.diff(end_datetime, start_datetime, :minute)

    # Calculate utilization percentage
    if available_minutes > 0 do
      utilization = booked_minutes / available_minutes * 100
      %{
        booked_minutes: booked_minutes,
        available_minutes: available_minutes,
        utilization_percentage: Float.round(utilization, 2)
      }
    else
      %{
        booked_minutes: 0,
        available_minutes: 0,
        utilization_percentage: 0.0
      }
    end
  end

  @doc """
  Gets utilization for all resources over a date range.
  Returns a list of %{resource_id, resource_name, utilization_percentage}.
  """
  def all_resources_utilization(start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
    end_datetime = DateTime.new!(end_date, ~T[23:59:59], "Etc/UTC")
    available_minutes = DateTime.diff(end_datetime, start_datetime, :minute)

    # Get all resources with their booking minutes
    from(r in Resource,
      left_join: b in Booking,
      on: b.resource_id == r.id and b.start_at >= ^start_datetime and b.end_at <= ^end_datetime,
      group_by: [r.id, r.name],
      select: %{
        resource_id: r.id,
        resource_name: r.name,
        booked_minutes:
          sum(
            fragment(
              "EXTRACT(EPOCH FROM (COALESCE(?, ?) - COALESCE(?, ?))) / 60",
              b.end_at,
              ^start_datetime,
              b.start_at,
              ^start_datetime
            )
          )
      }
    )
    |> Repo.all()
    |> Enum.map(fn resource ->
      booked = case resource.booked_minutes do
        nil -> 0
        %Decimal{} = minutes -> minutes |> Decimal.to_float()
        minutes when is_number(minutes) -> minutes
        _ -> 0
      end
      utilization = if available_minutes > 0, do: booked / available_minutes * 100, else: 0.0

      %{
        resource_id: resource.resource_id,
        resource_name: resource.resource_name,
        utilization_percentage: Float.round(utilization, 2)
      }
    end)
    |> Enum.sort_by(& &1.utilization_percentage, :desc)
  end

  @doc """
  Gets total revenue from all active contracts.
  """
  def total_revenue do
    from(c in Contract,
      where: c.status == :active,
      select: sum(c.total_amount_cents)
    )
    |> Repo.one()
    |> case do
      nil -> 0
      amount -> amount
    end
  end

  @doc """
  Gets count of active contracts.
  """
  def active_contracts_count do
    from(c in Contract,
      where: c.status == :active,
      select: count(c.id)
    )
    |> Repo.one()
  end

  @doc """
  Gets overall utilization percentage across all resources for a date range.
  """
  def overall_utilization(start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
    end_datetime = DateTime.new!(end_date, ~T[23:59:59], "Etc/UTC")

    # Count total resources
    resource_count = Repo.aggregate(Resource, :count, :id)

    # Calculate total booked minutes across all resources
    total_booked =
      from(b in Booking,
        where: b.start_at >= ^start_datetime,
        where: b.end_at <= ^end_datetime,
        select:
          sum(
            fragment(
              "EXTRACT(EPOCH FROM (? - ?)) / 60",
              b.end_at,
              b.start_at
            )
          )
      )
      |> Repo.one()
      |> case do
        nil -> 0
        %Decimal{} = minutes -> minutes |> Decimal.to_float() |> trunc()
        minutes -> trunc(minutes)
      end

    # Calculate total available minutes (all resources * time range)
    minutes_in_range = DateTime.diff(end_datetime, start_datetime, :minute)
    total_available = resource_count * minutes_in_range

    if total_available > 0 do
      Float.round(total_booked / total_available * 100, 2)
    else
      0.0
    end
  end

  @doc """
  Gets analytics summary for dashboard KPIs.
  """
  def get_dashboard_summary(start_date, end_date) do
    %{
      total_revenue: total_revenue(),
      active_contracts: active_contracts_count(),
      overall_utilization: overall_utilization(start_date, end_date),
      revenue_by_resource: revenue_by_resource(start_date, end_date) |> Enum.take(5),
      utilization_by_resource: all_resources_utilization(start_date, end_date) |> Enum.take(5)
    }
  end

  @doc """
  Formats cents to dollar string.
  """
  def format_currency(cents) when is_integer(cents) do
    dollars = cents / 100
    "$#{:erlang.float_to_binary(dollars, decimals: 2)}"
  end

  def format_currency(_), do: "$0.00"
end
