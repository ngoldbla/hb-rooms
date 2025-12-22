defmodule Overbooked.Resources.AvailabilitySearch do
  @moduledoc """
  Search module for finding available resources.
  
  Provides functions to search for resources that are available
  during a specified time range, with optional filters for
  resource type, capacity, and amenities.
  """

  import Ecto.Query, warn: false
  alias Overbooked.Repo
  alias Overbooked.Resources.{Resource, ResourceType}
  alias Overbooked.Schedule.Booking

  @doc """
  Searches for available resources based on the given criteria.
  
  ## Options
  
    * `:start_at` - (required) UTC datetime for start of availability window
    * `:end_at` - (required) UTC datetime for end of availability window
    * `:resource_type` - (optional) filter by type ("room" or "desk")
    * `:min_capacity` - (optional) minimum capacity required
    * `:amenity_ids` - (optional) list of required amenity IDs
    * `:limit` - (optional) max results, default 100
    
  ## Returns
  
  List of `%Resource{}` structs that are available during the specified window.
  
  ## Examples
  
      search(%{
        start_at: ~U[2024-01-15 09:00:00Z],
        end_at: ~U[2024-01-15 10:00:00Z],
        resource_type: "room",
        min_capacity: 4
      })
  """
  def search(opts) when is_map(opts) do
    start_at = Map.fetch!(opts, :start_at)
    end_at = Map.fetch!(opts, :end_at)
    
    base_query()
    |> filter_available(start_at, end_at)
    |> filter_by_type(Map.get(opts, :resource_type))
    |> filter_by_capacity(Map.get(opts, :min_capacity))
    |> filter_by_amenities(Map.get(opts, :amenity_ids))
    |> limit_results(Map.get(opts, :limit, 100))
    |> Repo.all()
  end

  @doc """
  Returns resources that have any availability during a date range.
  
  Unlike `search/1`, this returns resources even if they have some
  bookings during the range, as long as there's at least some
  availability.
  """
  def search_with_availability(opts) when is_map(opts) do
    start_at = Map.fetch!(opts, :start_at)
    end_at = Map.fetch!(opts, :end_at)
    
    # Get all resources matching filters
    resources =
      base_query()
      |> filter_by_type(Map.get(opts, :resource_type))
      |> filter_by_capacity(Map.get(opts, :min_capacity))
      |> filter_by_amenities(Map.get(opts, :amenity_ids))
      |> limit_results(Map.get(opts, :limit, 100))
      |> Repo.all()
    
    # For each resource, calculate available windows
    Enum.map(resources, fn resource ->
      windows = calculate_availability_windows(resource, start_at, end_at)
      Map.put(resource, :availability_windows, windows)
    end)
    |> Enum.filter(fn r -> length(r.availability_windows) > 0 end)
  end

  # ============================================================================
  # Private Functions
  # ============================================================================

  defp base_query do
    from(r in Resource,
      preload: [:amenities, :resource_type],
      order_by: [asc: r.name]
    )
  end

  # Filter to resources with no overlapping bookings
  defp filter_available(query, start_at, end_at) do
    conflicting_bookings =
      from(b in Booking,
        where: b.resource_id == parent_as(:resource).id,
        where: b.start_at < ^end_at and b.end_at > ^start_at
      )

    from(r in query,
      as: :resource,
      where: not exists(conflicting_bookings)
    )
  end

  defp filter_by_type(query, nil), do: query
  defp filter_by_type(query, type) when type in ["room", "desk"] do
    from(r in query,
      join: rt in ResourceType,
      on: rt.id == r.resource_type_id,
      where: rt.name == ^type
    )
  end
  defp filter_by_type(query, _), do: query

  defp filter_by_capacity(query, nil), do: query
  defp filter_by_capacity(query, min_capacity) when is_integer(min_capacity) and min_capacity > 0 do
    from(r in query, where: r.capacity >= ^min_capacity)
  end
  defp filter_by_capacity(query, _), do: query

  defp filter_by_amenities(query, nil), do: query
  defp filter_by_amenities(query, []), do: query
  defp filter_by_amenities(query, amenity_ids) when is_list(amenity_ids) do
    # Resources must have ALL specified amenities
    amenity_count = length(amenity_ids)
    
    from(r in query,
      join: ra in "resource_amenities",
      on: ra.resource_id == r.id,
      where: ra.amenity_id in ^amenity_ids,
      group_by: r.id,
      having: count(ra.amenity_id) >= ^amenity_count
    )
  end

  defp limit_results(query, limit) when is_integer(limit) and limit > 0 do
    from(q in query, limit: ^limit)
  end
  defp limit_results(query, _), do: from(q in query, limit: 100)

  @doc """
  Calculates available time windows for a resource during a date range.
  
  Returns a list of `{start_at, end_at}` tuples representing available windows.
  """
  def calculate_availability_windows(resource, range_start, range_end) do
    # Get all bookings for this resource in the range
    bookings =
      from(b in Booking,
        where: b.resource_id == ^resource.id,
        where: b.start_at < ^range_end and b.end_at > ^range_start,
        order_by: b.start_at
      )
      |> Repo.all()

    # Find gaps between bookings
    find_gaps(range_start, range_end, bookings)
  end

  defp find_gaps(range_start, range_end, []) do
    # No bookings = entire range is available
    [{range_start, range_end}]
  end

  defp find_gaps(range_start, range_end, bookings) do
    # Start with potential gap at beginning
    initial_gaps = 
      case hd(bookings) do
        %{start_at: first_start} when first_start > range_start ->
          [{range_start, first_start}]
        _ ->
          []
      end

    # Find gaps between consecutive bookings
    middle_gaps =
      bookings
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.flat_map(fn [b1, b2] ->
        if DateTime.compare(b1.end_at, b2.start_at) == :lt do
          [{b1.end_at, b2.start_at}]
        else
          []
        end
      end)

    # Check for gap at end
    end_gaps =
      case List.last(bookings) do
        %{end_at: last_end} when last_end < range_end ->
          [{last_end, range_end}]
        _ ->
          []
      end

    initial_gaps ++ middle_gaps ++ end_gaps
  end
end
