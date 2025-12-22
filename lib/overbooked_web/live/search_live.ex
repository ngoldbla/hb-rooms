defmodule OverbookedWeb.SearchLive do
  @moduledoc """
  LiveView for searching available resources.
  
  Provides filtering by date/time range, resource type, capacity, and amenities
  with real-time search results.
  """
  use OverbookedWeb, :live_view

  alias Overbooked.Resources
  alias Overbooked.Resources.AvailabilitySearch

  @impl true
  def mount(_params, _session, socket) do
    # Default to tomorrow's date range
    today = Timex.today()
    tomorrow = Timex.shift(today, days: 1)
    
    default_start_time = ~T[09:00:00]
    default_end_time = ~T[17:00:00]
    
    amenities = Resources.list_amenities()
    
    {:ok,
     socket
     |> assign(:date, tomorrow)
     |> assign(:start_time, default_start_time)
     |> assign(:end_time, default_end_time)
     |> assign(:resource_type, "all")
     |> assign(:min_capacity, 1)
     |> assign(:amenity_ids, [])
     |> assign(:amenities, amenities)
     |> assign(:results, [])
     |> assign(:searched, false)
     |> run_search()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> maybe_apply_param(params, "date", :date, &parse_date/1)
      |> maybe_apply_param(params, "start_time", :start_time, &parse_time/1)
      |> maybe_apply_param(params, "end_time", :end_time, &parse_time/1)
      |> maybe_apply_param(params, "type", :resource_type, & &1)
      |> maybe_apply_param(params, "capacity", :min_capacity, &parse_int/1)
    
    {:noreply, socket |> run_search()}
  end

  defp maybe_apply_param(socket, params, key, assign_key, parser) do
    case Map.get(params, key) do
      nil -> socket
      val ->
        case parser.(val) do
          {:ok, parsed} -> assign(socket, assign_key, parsed)
          _ -> socket
        end
    end
  end

  defp parse_date(str) do
    case Date.from_iso8601(str) do
      {:ok, date} -> {:ok, date}
      _ -> :error
    end
  end

  defp parse_time(str) do
    case Time.from_iso8601(str <> ":00") do
      {:ok, time} -> {:ok, time}
      _ -> 
        case Time.from_iso8601(str) do
          {:ok, time} -> {:ok, time}
          _ -> :error
        end
    end
  end

  defp parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, ""} when n > 0 -> {:ok, n}
      _ -> :error
    end
  end

  @impl true
  def handle_event("search", %{"search" => params}, socket) do
    date = parse_date_fallback(params["date"], socket.assigns.date)
    start_time = parse_time_fallback(params["start_time"], socket.assigns.start_time)
    end_time = parse_time_fallback(params["end_time"], socket.assigns.end_time)
    resource_type = params["resource_type"] || "all"
    min_capacity = parse_int_fallback(params["min_capacity"], 1)
    
    amenity_ids = 
      (params["amenity_ids"] || [])
      |> List.wrap()
      |> Enum.map(&parse_int_fallback(&1, nil))
      |> Enum.reject(&is_nil/1)

    socket =
      socket
      |> assign(:date, date)
      |> assign(:start_time, start_time)
      |> assign(:end_time, end_time)
      |> assign(:resource_type, resource_type)
      |> assign(:min_capacity, min_capacity)
      |> assign(:amenity_ids, amenity_ids)
      |> assign(:searched, true)
      |> run_search()

    {:noreply, socket}
  end

  defp parse_date_fallback(str, default) do
    case parse_date(str) do
      {:ok, date} -> date
      _ -> default
    end
  end

  defp parse_time_fallback(str, default) do
    case parse_time(str) do
      {:ok, time} -> time
      _ -> default
    end
  end

  defp parse_int_fallback(str, default) when is_binary(str) do
    case Integer.parse(str) do
      {n, ""} when n > 0 -> n
      _ -> default
    end
  end
  defp parse_int_fallback(_, default), do: default

  defp run_search(socket) do
    %{
      date: date,
      start_time: start_time,
      end_time: end_time,
      resource_type: resource_type,
      min_capacity: min_capacity,
      amenity_ids: amenity_ids
    } = socket.assigns

    start_at = to_utc_datetime(date, start_time)
    end_at = to_utc_datetime(date, end_time)

    opts = %{
      start_at: start_at,
      end_at: end_at
    }

    opts = if resource_type != "all", do: Map.put(opts, :resource_type, resource_type), else: opts
    opts = if min_capacity > 1, do: Map.put(opts, :min_capacity, min_capacity), else: opts
    opts = if amenity_ids != [], do: Map.put(opts, :amenity_ids, amenity_ids), else: opts

    results = AvailabilitySearch.search(opts)
    assign(socket, :results, results)
  end

  defp to_utc_datetime(date, time) do
    {:ok, naive} = NaiveDateTime.new(date, time)
    DateTime.from_naive!(naive, "Etc/UTC")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header label="Find Available Spaces"></.header>

    <.page>
      <div class="w-full grid grid-cols-1 lg:grid-cols-4 gap-8">
        <!-- Filters Sidebar -->
        <div class="lg:col-span-1">
          <div class="bg-white rounded-lg shadow p-6 sticky top-4">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Filters</h2>
            
            <.form for={%{}} phx-submit="search" phx-change="search" id="search-form">
              <div class="space-y-6">
                <!-- Date -->
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Date</label>
                  <input
                    type="date"
                    name="search[date]"
                    value={Date.to_iso8601(@date)}
                    class="w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                  />
                </div>

                <!-- Time Range -->
                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Start Time</label>
                    <input
                      type="time"
                      name="search[start_time]"
                      value={Time.to_string(@start_time) |> String.slice(0, 5)}
                      class="w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">End Time</label>
                    <input
                      type="time"
                      name="search[end_time]"
                      value={Time.to_string(@end_time) |> String.slice(0, 5)}
                      class="w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                    />
                  </div>
                </div>

                <!-- Resource Type -->
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Space Type</label>
                  <select
                    name="search[resource_type]"
                    class="w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                  >
                    <option value="all" selected={@resource_type == "all"}>All</option>
                    <option value="room" selected={@resource_type == "room"}>Rooms</option>
                    <option value="desk" selected={@resource_type == "desk"}>Desks</option>
                  </select>
                </div>

                <!-- Capacity -->
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Minimum Capacity</label>
                  <input
                    type="number"
                    name="search[min_capacity]"
                    value={@min_capacity}
                    min="1"
                    class="w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
                  />
                </div>

                <!-- Amenities -->
                <%= if length(@amenities) > 0 do %>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Amenities</label>
                    <div class="space-y-2 max-h-48 overflow-y-auto">
                      <%= for amenity <- @amenities do %>
                        <label class="flex items-center">
                          <input
                            type="checkbox"
                            name="search[amenity_ids][]"
                            value={amenity.id}
                            checked={amenity.id in @amenity_ids}
                            class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                          />
                          <span class="ml-2 text-sm text-gray-600"><%= amenity.name %></span>
                        </label>
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <button
                  type="submit"
                  class="w-full bg-primary-600 text-white rounded-md py-2 px-4 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 transition"
                >
                  Search
                </button>
              </div>
            </.form>
          </div>
        </div>

        <!-- Results -->
        <div class="lg:col-span-3">
          <%= if length(@results) == 0 do %>
            <div class="bg-white rounded-lg shadow p-8 text-center">
              <.icon name={:magnifying_glass} class="mx-auto h-12 w-12 text-gray-400" />
              <h3 class="mt-2 text-sm font-semibold text-gray-900">No results</h3>
              <p class="mt-1 text-sm text-gray-500">
                No spaces are available for the selected time. Try adjusting your filters.
              </p>
            </div>
          <% else %>
            <div class="space-y-4">
              <p class="text-sm text-gray-600">
                <span class="font-medium"><%= length(@results) %></span> space(s) available
              </p>
              
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <%= for resource <- @results do %>
                  <.result_card resource={resource} date={@date} start_time={@start_time} end_time={@end_time} />
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </.page>
    """
  end

  defp result_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow hover:shadow-md transition p-6">
      <div class="flex items-start justify-between">
        <div>
          <div class="flex items-center gap-2">
            <div class={"w-3 h-3 rounded-full bg-#{@resource.color}-400"}></div>
            <h3 class="text-lg font-semibold text-gray-900"><%= @resource.name %></h3>
          </div>
          
          <%= if @resource.resource_type do %>
            <p class="text-sm text-gray-500 mt-1 capitalize"><%= @resource.resource_type.name %></p>
          <% end %>
        </div>
        
        <div class="text-right">
          <%= if @resource.capacity do %>
            <div class="flex items-center gap-1 text-sm text-gray-600">
              <.icon name={:user_group} class="h-4 w-4" />
              <span><%= @resource.capacity %></span>
            </div>
          <% end %>
        </div>
      </div>

      <%= if length(@resource.amenities) > 0 do %>
        <div class="mt-3 flex flex-wrap gap-1">
          <%= for amenity <- @resource.amenities do %>
            <span class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-800">
              <%= amenity.name %>
            </span>
          <% end %>
        </div>
      <% end %>

      <div class="mt-4 pt-4 border-t border-gray-100">
        <.link
          navigate={"/schedule/weekly?date=#{Date.to_iso8601(@date)}"}
          class="inline-flex items-center gap-1 text-sm font-medium text-primary-600 hover:text-primary-700"
        >
          View Calendar
          <.icon name={:arrow_right} class="h-4 w-4" />
        </.link>
      </div>
    </div>
    """
  end
end
