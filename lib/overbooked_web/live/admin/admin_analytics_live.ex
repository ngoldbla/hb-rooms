defmodule OverbookedWeb.AdminAnalyticsLive do
  use OverbookedWeb, :live_view

  alias Overbooked.Analytics

  @impl true
  def mount(_params, _session, socket) do
    # Default to last 30 days
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -30)

    socket =
      socket
      |> assign(date_range: "30_days")
      |> assign(start_date: start_date)
      |> assign(end_date: end_date)
      |> assign(custom_start: Date.to_string(start_date))
      |> assign(custom_end: Date.to_string(end_date))
      |> load_analytics_data()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      case params do
        %{"range" => range, "start" => start_str, "end" => end_str} ->
          with {:ok, start_date} <- Date.from_iso8601(start_str),
               {:ok, end_date} <- Date.from_iso8601(end_str) do
            socket
            |> assign(date_range: range)
            |> assign(start_date: start_date)
            |> assign(end_date: end_date)
            |> assign(custom_start: start_str)
            |> assign(custom_end: end_str)
            |> load_analytics_data()
          else
            _ -> socket
          end

        _ ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header label="Admin">
      <.admin_tabs active_tab={@active_tab} socket={@socket} />
    </.header>

    <.page>
      <div class="w-full space-y-6">
        <!-- Date Range Filter -->
        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-medium leading-6 text-gray-900 mb-4">
            Date Range
          </h3>

          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
            <button
              type="button"
              phx-click="set_range"
              phx-value-range="today"
              class={"px-4 py-2 rounded-md text-sm font-medium transition-colors #{if @date_range == "today", do: "bg-primary-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200"}"}
            >
              Today
            </button>

            <button
              type="button"
              phx-click="set_range"
              phx-value-range="7_days"
              class={"px-4 py-2 rounded-md text-sm font-medium transition-colors #{if @date_range == "7_days", do: "bg-primary-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200"}"}
            >
              Last 7 Days
            </button>

            <button
              type="button"
              phx-click="set_range"
              phx-value-range="30_days"
              class={"px-4 py-2 rounded-md text-sm font-medium transition-colors #{if @date_range == "30_days", do: "bg-primary-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200"}"}
            >
              Last 30 Days
            </button>

            <button
              type="button"
              phx-click="set_range"
              phx-value-range="90_days"
              class={"px-4 py-2 rounded-md text-sm font-medium transition-colors #{if @date_range == "90_days", do: "bg-primary-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200"}"}
            >
              Last 90 Days
            </button>

            <button
              type="button"
              phx-click="toggle_custom"
              class={"px-4 py-2 rounded-md text-sm font-medium transition-colors #{if @date_range == "custom", do: "bg-primary-600 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200"}"}
            >
              Custom
            </button>
          </div>

          <%= if @date_range == "custom" do %>
            <form phx-submit="apply_custom_range" class="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label for="custom_start" class="block text-sm font-medium text-gray-700">
                  Start Date
                </label>
                <input
                  type="date"
                  id="custom_start"
                  name="start_date"
                  value={@custom_start}
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm"
                />
              </div>

              <div>
                <label for="custom_end" class="block text-sm font-medium text-gray-700">
                  End Date
                </label>
                <input
                  type="date"
                  id="custom_end"
                  name="end_date"
                  value={@custom_end}
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm"
                />
              </div>

              <div class="sm:col-span-2">
                <.button type="submit" variant={:secondary}>
                  Apply Custom Range
                </.button>
              </div>
            </form>
          <% end %>

          <p class="mt-4 text-sm text-gray-500">
            Showing data from <%= Calendar.strftime(@start_date, "%B %d, %Y") %> to <%= Calendar.strftime(
              @end_date,
              "%B %d, %Y"
            ) %>
          </p>
        </div>

        <!-- KPI Cards -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <.kpi_card
            title="Total Revenue"
            value={Analytics.format_currency(@summary.total_revenue)}
            icon={:currency_dollar}
            color="green"
          />

          <.kpi_card
            title="Active Contracts"
            value={@summary.active_contracts}
            icon={:document_text}
            color="blue"
          />

          <.kpi_card
            title="Overall Utilization"
            value={"#{@summary.overall_utilization}%"}
            icon={:chart_bar}
            color="purple"
          />
        </div>

        <!-- Revenue by Resource -->
        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-medium leading-6 text-gray-900 mb-4">
            Revenue by Resource
          </h3>

          <%= if Enum.empty?(@summary.revenue_by_resource) do %>
            <p class="text-sm text-gray-500">No revenue data available for this period.</p>
          <% else %>
            <div class="space-y-3">
              <%= for item <- @summary.revenue_by_resource do %>
                <div class="flex items-center justify-between">
                  <span class="text-sm font-medium text-gray-900"><%= item.resource_name %></span>
                  <span class="text-sm text-gray-600"><%= Analytics.format_currency(
                      item.revenue_cents
                    ) %></span>
                </div>
              <% end %>
            </div>

            <!-- Revenue Chart -->
            <div class="mt-6">
              <canvas
                id="revenue-chart"
                phx-hook="RevenueChart"
                data-chart-data={Jason.encode!(@chart_data.revenue)}
              >
              </canvas>
            </div>
          <% end %>
        </div>

        <!-- Utilization by Resource -->
        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-medium leading-6 text-gray-900 mb-4">
            Space Utilization
          </h3>

          <%= if Enum.empty?(@summary.utilization_by_resource) do %>
            <p class="text-sm text-gray-500">No utilization data available for this period.</p>
          <% else %>
            <div class="space-y-3">
              <%= for item <- @summary.utilization_by_resource do %>
                <div>
                  <div class="flex items-center justify-between mb-1">
                    <span class="text-sm font-medium text-gray-900"><%= item.resource_name %></span>
                    <span class="text-sm text-gray-600"><%= item.utilization_percentage %>%</span>
                  </div>
                  <div class="w-full bg-gray-200 rounded-full h-2">
                    <div
                      class="bg-primary-600 h-2 rounded-full"
                      style={"width: #{min(item.utilization_percentage, 100)}%"}
                    >
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Utilization Chart -->
            <div class="mt-6">
              <canvas
                id="utilization-chart"
                phx-hook="UtilizationChart"
                data-chart-data={Jason.encode!(@chart_data.utilization)}
              >
              </canvas>
            </div>
          <% end %>
        </div>

        <!-- Revenue Trend -->
        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-medium leading-6 text-gray-900 mb-4">
            Revenue Trend (Last 12 Months)
          </h3>

          <%= if Enum.empty?(@revenue_trend) do %>
            <p class="text-sm text-gray-500">No revenue trend data available.</p>
          <% else %>
            <div>
              <canvas
                id="trend-chart"
                phx-hook="TrendChart"
                data-chart-data={Jason.encode!(@chart_data.trend)}
              >
              </canvas>
            </div>
          <% end %>
        </div>
      </div>
    </.page>
    """
  end

  # KPI Card Component
  attr :title, :string, required: true
  attr :value, :any, required: true
  attr :icon, :atom, required: true
  attr :color, :string, default: "gray"

  defp kpi_card(assigns) do
    color_classes = %{
      "green" => "bg-green-100 text-green-600",
      "blue" => "bg-blue-100 text-blue-600",
      "purple" => "bg-purple-100 text-purple-600",
      "gray" => "bg-gray-100 text-gray-600"
    }

    assigns = assign(assigns, :color_class, Map.get(color_classes, assigns.color, color_classes["gray"]))

    ~H"""
    <div class="bg-white shadow rounded-lg p-6">
      <div class="flex items-center">
        <div class={"flex-shrink-0 rounded-md p-3 #{@color_class}"}>
          <.icon name={@icon} class="h-6 w-6" />
        </div>
        <div class="ml-5 w-0 flex-1">
          <dl>
            <dt class="text-sm font-medium text-gray-500 truncate">
              <%= @title %>
            </dt>
            <dd class="text-2xl font-semibold text-gray-900">
              <%= @value %>
            </dd>
          </dl>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("set_range", %{"range" => range}, socket) do
    {start_date, end_date} = calculate_date_range(range)

    socket =
      socket
      |> assign(date_range: range)
      |> assign(start_date: start_date)
      |> assign(end_date: end_date)
      |> assign(custom_start: Date.to_string(start_date))
      |> assign(custom_end: Date.to_string(end_date))
      |> load_analytics_data()
      |> push_patch(
        to:
          Routes.admin_analytics_path(socket, :index,
            range: range,
            start: Date.to_string(start_date),
            end: Date.to_string(end_date)
          )
      )

    {:noreply, socket}
  end

  def handle_event("toggle_custom", _params, socket) do
    socket =
      socket
      |> assign(date_range: "custom")

    {:noreply, socket}
  end

  def handle_event("apply_custom_range", %{"start_date" => start_str, "end_date" => end_str}, socket) do
    with {:ok, start_date} <- Date.from_iso8601(start_str),
         {:ok, end_date} <- Date.from_iso8601(end_str),
         :gt <- Date.compare(end_date, start_date) do
      socket =
        socket
        |> assign(start_date: start_date)
        |> assign(end_date: end_date)
        |> assign(custom_start: start_str)
        |> assign(custom_end: end_str)
        |> load_analytics_data()
        |> push_patch(
          to:
            Routes.admin_analytics_path(socket, :index,
              range: "custom",
              start: start_str,
              end: end_str
            )
        )

      {:noreply, socket}
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Invalid date range. End date must be after start date.")}
    end
  end

  # Private functions

  defp calculate_date_range("today") do
    today = Date.utc_today()
    {today, today}
  end

  defp calculate_date_range("7_days") do
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -7)
    {start_date, end_date}
  end

  defp calculate_date_range("30_days") do
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -30)
    {start_date, end_date}
  end

  defp calculate_date_range("90_days") do
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -90)
    {start_date, end_date}
  end

  defp calculate_date_range(_), do: calculate_date_range("30_days")

  defp load_analytics_data(socket) do
    start_date = socket.assigns.start_date
    end_date = socket.assigns.end_date

    summary = Analytics.get_dashboard_summary(start_date, end_date)
    revenue_trend = Analytics.revenue_trend(12)

    # Prepare chart data
    chart_data = %{
      revenue: %{
        labels: Enum.map(summary.revenue_by_resource, &(&1.resource_name)),
        data: Enum.map(summary.revenue_by_resource, &(&1.revenue_cents / 100))
      },
      utilization: %{
        labels: Enum.map(summary.utilization_by_resource, &(&1.resource_name)),
        data: Enum.map(summary.utilization_by_resource, &(&1.utilization_percentage))
      },
      trend: %{
        labels: Enum.map(revenue_trend, &format_month/1),
        data: Enum.map(revenue_trend, &(&1.revenue_cents / 100))
      }
    }

    socket
    |> assign(summary: summary)
    |> assign(revenue_trend: revenue_trend)
    |> assign(chart_data: chart_data)
  end

  defp format_month(%{month: month, year: year}) do
    month_name =
      case trunc(month) do
        1 -> "Jan"
        2 -> "Feb"
        3 -> "Mar"
        4 -> "Apr"
        5 -> "May"
        6 -> "Jun"
        7 -> "Jul"
        8 -> "Aug"
        9 -> "Sep"
        10 -> "Oct"
        11 -> "Nov"
        12 -> "Dec"
        _ -> ""
      end

    "#{month_name} #{trunc(year)}"
  end
end
