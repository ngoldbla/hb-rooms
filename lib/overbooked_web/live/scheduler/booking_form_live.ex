defmodule OverbookedWeb.ScheduleLive.BookingForm do
  use OverbookedWeb, :live_component

  alias Overbooked.Resources
  alias Overbooked.Schedule
  alias Overbooked.Schedule.{Booking, RecurringRule}

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.modal id={"#{@id}-modal"} on_confirm={hide_modal("#{@id}-modal")} icon={nil}>
        <:title>Book a resource</:title>
        <.form
          :let={f}
          for={@changeset}
          phx-submit={:add_booking}
          phx-change={:validate_form}
          phx-target={@myself}
          id={"#{@id}-form"}
          class="flex flex-col space-y-4"
        >
          <div class="">
            <label for="start_at" class="block text-sm font-medium text-gray-700">
              Resource
            </label>
            <div class="mt-1">
              <.select
                form={f}
                field={:resource_id}
                value={@default_resource}
                name="resource_id"
                phx_debounce="blur"
                options={Enum.map(@resources, &{&1.name, &1.id})}
                required={true}
              />
            </div>
          </div>
          <div class="flex flex-row space-x-4">
            <div class="">
              <label for="start_at" class="block text-sm font-medium text-gray-700">
                Day
              </label>
              <div class="mt-1">
                <.date_input
                  form={f}
                  field={:date}
                  phx_debounce="blur"
                  value={@default_day}
                  required={true}
                />
                <.error form={f} field={:date} />
              </div>
            </div>
            <div class="">
              <label for="end_at" class="block text-sm font-medium text-gray-700">
                Hours
              </label>
              <div class="flex flex-row space-x-2">
                <div class="mt-1">
                  <.select
                    options={time_options()}
                    value={@default_start_at}
                    form={f}
                    field={:start_at}
                    phx_debounce="blur"
                    required={true}
                  />
                  <.error form={f} field={:start_at} />
                </div>
                <div class="mt-1">
                  <.select
                    options={time_options()}
                    value={@default_end_at}
                    form={f}
                    field={:end_at}
                    phx_debounce="blur"
                    required={true}
                  />
                  <.error form={f} field={:end_at} />
                </div>
              </div>
            </div>
          </div>

          <!-- Recurring Options Toggle -->
          <div class="border-t border-gray-200 pt-4">
            <label class="flex items-center cursor-pointer">
              <input
                type="checkbox"
                name="recurring_enabled"
                checked={@recurring_enabled}
                class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
              />
              <span class="ml-2 text-sm font-medium text-gray-700">Repeat this booking</span>
            </label>
          </div>

          <!-- Recurring Options (shown when enabled) -->
          <%= if @recurring_enabled do %>
            <div class="bg-gray-50 rounded-lg p-4 space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Pattern</label>
                <.select
                  form={f}
                  field={:pattern}
                  name="recurring[pattern]"
                  options={[
                    {"Daily", "daily"},
                    {"Weekly", "weekly"},
                    {"Every 2 weeks", "biweekly"},
                    {"Monthly", "monthly"}
                  ]}
                  value={@recurring_pattern}
                />
              </div>

              <%= if @recurring_pattern in ["weekly", "biweekly"] do %>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">Days of week</label>
                  <div class="flex flex-wrap gap-2">
                    <%= for {day, num} <- [{"Mon", 1}, {"Tue", 2}, {"Wed", 3}, {"Thu", 4}, {"Fri", 5}, {"Sat", 6}, {"Sun", 7}] do %>
                      <label class={"flex items-center justify-center w-10 h-10 rounded-full cursor-pointer border-2 transition #{if num in @recurring_days, do: "bg-primary-600 text-white border-primary-600", else: "bg-white text-gray-700 border-gray-300 hover:border-primary-400"}"}>
                        <input
                          type="checkbox"
                          name="recurring[days_of_week][]"
                          value={num}
                          checked={num in @recurring_days}
                          class="sr-only"
                        />
                        <span class="text-xs font-medium"><%= day %></span>
                      </label>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">End date</label>
                  <input
                    type="date"
                    name="recurring[end_date]"
                    value={@recurring_end_date}
                    class="w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 text-sm"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Or occurrences</label>
                  <input
                    type="number"
                    name="recurring[max_occurrences]"
                    value={@recurring_max_occurrences}
                    min="1"
                    max="52"
                    placeholder="e.g., 10"
                    class="w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 text-sm"
                  />
                </div>
              </div>

              <%= if length(@preview_dates) > 0 do %>
                <div class="mt-2">
                  <p class="text-sm text-gray-600 mb-2">
                    <span class="font-medium"><%= length(@preview_dates) %></span> bookings will be created:
                  </p>
                  <div class="max-h-32 overflow-y-auto bg-white rounded border p-2">
                    <ul class="text-xs text-gray-600 space-y-1">
                      <%= for date <- Enum.take(@preview_dates, 10) do %>
                        <li><%= Calendar.strftime(date, "%a, %b %d, %Y") %></li>
                      <% end %>
                      <%= if length(@preview_dates) > 10 do %>
                        <li class="text-gray-400">... and <%= length(@preview_dates) - 10 %> more</li>
                      <% end %>
                    </ul>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </.form>
        <:confirm type="submit" form={"#{@id}-form"} phx-disable-with="Saving..." variant={:secondary}>
          <%= if @recurring_enabled, do: "Save Series", else: "Save" %>
        </:confirm>

        <:cancel>Cancel</:cancel>
      </.modal>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       default_start_at: "09:00",
       default_end_at: "10:00",
       default_resource: 1,
       recurring_enabled: false,
       recurring_pattern: "weekly",
       recurring_days: [],
       recurring_end_date: nil,
       recurring_max_occurrences: nil,
       preview_dates: []
     )}
  end

  @impl true
  def handle_event("validate_form", params, socket) do
    recurring_enabled = Map.get(params, "recurring_enabled") in ["true", "on", "1"]
    recurring = Map.get(params, "recurring", %{})
    
    pattern = Map.get(recurring, "pattern", "weekly")
    days = parse_days_of_week(Map.get(recurring, "days_of_week", []))
    end_date = Map.get(recurring, "end_date")
    max_occurrences = parse_int(Map.get(recurring, "max_occurrences"))

    preview_dates = 
      if recurring_enabled do
        calculate_preview(pattern, days, socket.assigns.default_day, end_date, max_occurrences)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:recurring_enabled, recurring_enabled)
     |> assign(:recurring_pattern, pattern)
     |> assign(:recurring_days, days)
     |> assign(:recurring_end_date, end_date)
     |> assign(:recurring_max_occurrences, max_occurrences)
     |> assign(:preview_dates, preview_dates)}
  end

  @impl true
  def handle_event("validate", %{"booking" => booking_params}, socket) do
    changeset =
      %Booking{}
      |> Schedule.change_booking(booking_params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event(
        "add_booking",
        %{"booking" => booking_params, "resource_id" => resource_id} = params,
        socket
      ) do
    resource = Resources.get_resource!(resource_id)
    %{"date" => date, "end_at" => end_at, "start_at" => start_at} = booking_params
    recurring_enabled = Map.get(params, "recurring_enabled") in ["true", "on", "1"]

    start_at_dt = Timex.parse!("#{date} #{start_at}", "{YYYY}-{0M}-{D} {h24}:{m}")
    end_at_dt = Timex.parse!("#{date} #{end_at}", "{YYYY}-{0M}-{D} {h24}:{m}")

    if recurring_enabled do
      # Create recurring booking
      recurring = Map.get(params, "recurring", %{})

      pattern = Map.get(recurring, "pattern", "weekly")
      start_date = Date.from_iso8601!(date)
      days = parse_days_of_week(Map.get(recurring, "days_of_week", []))

      days =
        if pattern in ["weekly", "biweekly"] and Enum.empty?(days) do
          [Timex.weekday(start_date, :monday)]
        else
          days
        end
      
      recurring_attrs = %{
        pattern: pattern,
        interval: 1,
        days_of_week: days,
        start_date: start_date,
        end_date: parse_date(Map.get(recurring, "end_date")),
        max_occurrences: parse_int(Map.get(recurring, "max_occurrences")),
        start_time: Time.from_iso8601!("#{start_at}:00"),
        end_time: Time.from_iso8601!("#{end_at}:00")
      }

      case Schedule.create_recurring_booking(resource, socket.assigns.current_user, recurring_attrs) do
        {:ok, %{rule: rule}} ->
          booking_count = length(Schedule.RecurringExpander.generate_occurrences(rule))
          send(self(), {:created_recurring_booking, rule, booking_count})
          {:noreply, socket |> reset_recurring_state()}

        {:error, :conflict, conflicting} ->
          send(self(), {:recurring_conflict, conflicting})
          {:noreply, socket}

        {:error, :rule, changeset, _} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    else
      # Create single booking (existing logic)
      booking_params = %{start_at: start_at_dt, end_at: end_at_dt}

      case Schedule.book_resource(resource, socket.assigns.current_user, booking_params) do
        {:ok, booking} ->
          send(self(), {:created_booking, booking})
          {:noreply, socket}

        {:error, :resource_busy} ->
          send(self(), {:resource_busy, resource})
          {:noreply, socket}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    end
  end

  defp reset_recurring_state(socket) do
    socket
    |> assign(:recurring_enabled, false)
    |> assign(:recurring_pattern, "weekly")
    |> assign(:recurring_days, [])
    |> assign(:recurring_end_date, nil)
    |> assign(:recurring_max_occurrences, nil)
    |> assign(:preview_dates, [])
  end

  defp parse_days_of_week(days) when is_list(days) do
    days
    |> Enum.map(&parse_int/1)
    |> Enum.reject(&is_nil/1)
  end
  defp parse_days_of_week(_), do: []

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil
  defp parse_int(val) when is_integer(val), do: val
  defp parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {n, ""} -> n
      _ -> nil
    end
  end

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil
  defp parse_date(str) do
    case Date.from_iso8601(str) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp calculate_preview(pattern, days, start_date_str, end_date_str, max_occurrences) do
    with {:ok, start_date} <- Date.from_iso8601(start_date_str),
         end_date <- parse_date(end_date_str),
         true <- end_date != nil or max_occurrences != nil do
      
      # Ensure days is not empty for weekly patterns
      days = if pattern in ["weekly", "biweekly"] and Enum.empty?(days) do
        [Timex.weekday(start_date, :monday)]
      else
        days
      end

      attrs = %{
        pattern: pattern,
        interval: 1,
        days_of_week: days,
        start_date: start_date,
        end_date: end_date,
        max_occurrences: max_occurrences,
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00]
      }

      case Schedule.preview_recurring_dates(attrs) do
        {:ok, dates} -> dates
        _ -> []
      end
    else
      _ -> []
    end
  end

  defp time_options() do
    res =
      for h <- [
            "00",
            "01",
            "02",
            "03",
            "04",
            "05",
            "06",
            "07",
            "08",
            "09",
            "10",
            "11",
            "12",
            "13",
            "14",
            "15",
            "16",
            "17",
            "18",
            "19",
            "20",
            "21",
            "22",
            "23"
          ] do
        for m <- ["00", "15", "30", "45"] do
          {"#{h}:#{m}", "#{h}:#{m}"}
        end
      end

    List.flatten(res)
  end
end
