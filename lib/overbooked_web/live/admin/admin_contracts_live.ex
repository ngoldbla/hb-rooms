defmodule OverbookedWeb.AdminContractsLive do
  use OverbookedWeb, :live_view

  alias Overbooked.Contracts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(status_filter: "all")
     |> assign_contracts()}
  end

  defp assign_contracts(socket) do
    status_filter = socket.assigns[:status_filter] || "all"
    contracts = Contracts.list_all_contracts(status: status_filter)
    assign(socket, contracts: contracts)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header label="Admin">
      <.admin_tabs active_tab={@active_tab} socket={@socket} />
    </.header>

    <.page>
      <div class="w-full space-y-6">
        <div class="w-full flex flex-row justify-between items-center">
          <h3>Contracts</h3>
          <div class="flex items-center space-x-2">
            <label class="text-sm text-gray-600">Filter:</label>
            <select
              name="status_filter"
              phx-change="filter"
              class="rounded-md border-gray-300 text-sm focus:border-primary-500 focus:ring-primary-500"
            >
              <option value="all" selected={@status_filter == "all"}>All</option>
              <option value="active" selected={@status_filter == "active"}>Active</option>
              <option value="pending" selected={@status_filter == "pending"}>Pending</option>
              <option value="cancelled" selected={@status_filter == "cancelled"}>Cancelled</option>
              <option value="expired" selected={@status_filter == "expired"}>Expired</option>
            </select>
          </div>
        </div>

        <%= if Enum.empty?(@contracts) do %>
          <div class="text-center py-12 text-gray-500">
            No contracts found.
          </div>
        <% else %>
          <.live_table
            module={OverbookedWeb.ContractRowComponent}
            id="contracts"
            rows={@contracts}
            row_id={fn contract -> "contract-#{contract.id}" end}
          >
            <:col :let={%{contract: contract}} label="User" width="w-32">
              <div class="flex flex-col">
                <span class="font-medium"><%= contract.user.name %></span>
                <span class="text-xs text-gray-500"><%= contract.user.email %></span>
              </div>
            </:col>
            <:col :let={%{contract: contract}} label="Space" width="w-24">
              <%= if contract.resource, do: contract.resource.name, else: "-" %>
            </:col>
            <:col :let={%{contract: contract}} label="Duration" width="w-20">
              <%= contract.duration_months %> mo
            </:col>
            <:col :let={%{contract: contract}} label="Period" width="w-32">
              <div class="flex flex-col text-xs">
                <span><%= format_date(contract.start_date) %></span>
                <span class="text-gray-500">to <%= format_date(contract.end_date) %></span>
              </div>
            </:col>
            <:col :let={%{contract: contract}} label="Amount" width="w-20">
              <%= Contracts.format_price(contract.total_amount_cents) %>
            </:col>
            <:col :let={%{contract: contract}} label="Status" width="w-20">
              <.status_badge status={contract.status} />
            </:col>
            <:col :let={%{contract: contract}} label="">
              <div class="w-full flex flex-row-reverse space-x-2 space-x-reverse">
                <.button
                  phx-click={show_modal("contract-details-modal-#{contract.id}")}
                  size={:small}
                >
                  Details
                </.button>
                <%= if contract.status == :active do %>
                  <.button
                    phx-click={show_modal("cancel-contract-modal-#{contract.id}")}
                    variant={:danger}
                    size={:small}
                  >
                    Cancel
                  </.button>
                <% end %>
              </div>
            </:col>
          </.live_table>
        <% end %>
      </div>
    </.page>
    """
  end

  defp format_date(date) do
    Calendar.strftime(date, "%b %d, %Y")
  end

  defp status_badge(%{status: :active} = assigns) do
    ~H"""
    <.badge color="green">Active</.badge>
    """
  end

  defp status_badge(%{status: :pending} = assigns) do
    ~H"""
    <.badge color="yellow">Pending</.badge>
    """
  end

  defp status_badge(%{status: :cancelled} = assigns) do
    ~H"""
    <.badge color="red">Cancelled</.badge>
    """
  end

  defp status_badge(%{status: :expired} = assigns) do
    ~H"""
    <.badge color="gray">Expired</.badge>
    """
  end

  @impl true
  def handle_event("filter", %{"status_filter" => status}, socket) do
    {:noreply,
     socket
     |> assign(status_filter: status)
     |> assign_contracts()}
  end

  @impl true
  def handle_event("cancel_contract", %{"id" => id}, socket) do
    contract = Contracts.get_contract!(id)

    case Contracts.admin_cancel_contract(contract) do
      {:ok, _contract} ->
        {:noreply,
         socket
         |> put_flash(:info, "Contract cancelled successfully.")
         |> assign_contracts()}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to cancel contract.")}
    end
  end
end
