defmodule OverbookedWeb.ContractsLive do
  @moduledoc """
  LiveView for managing user contracts.
  """
  use OverbookedWeb, :live_view

  alias Overbooked.Contracts

  @impl true
  def mount(_params, _session, socket) do
    contracts = Contracts.list_user_contracts(socket.assigns.current_user)

    {:ok, assign(socket, contracts: contracts)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header label="My Contracts"></.header>

    <.page>
      <div class="w-full space-y-6">
        <div class="flex justify-between items-center">
          <p class="text-gray-600">
            View and manage your office space contracts.
          </p>
          <.link navigate={Routes.live_path(@socket, OverbookedWeb.SpacesLive)}>
            <.button variant={:primary}>
              Browse Spaces
            </.button>
          </.link>
        </div>

        <%= if Enum.empty?(@contracts) do %>
          <div class="text-center py-12 text-gray-500 bg-white rounded-lg border border-gray-200">
            <.icon name={:document_text} class="mx-auto h-12 w-12 text-gray-400" />
            <h3 class="mt-2 text-sm font-medium text-gray-900">No contracts yet</h3>
            <p class="mt-1 text-sm text-gray-500">
              Get started by browsing available office spaces.
            </p>
            <div class="mt-4">
              <.link navigate={Routes.live_path(@socket, OverbookedWeb.SpacesLive)}>
                <.button variant={:primary}>Browse Spaces</.button>
              </.link>
            </div>
          </div>
        <% else %>
          <div class="bg-white shadow-sm rounded-lg overflow-hidden">
            <.table id="contracts" rows={@contracts} row_id={fn contract -> "contract-#{contract.id}" end}>
              <:col :let={contract} label="Space" width="w-32">
                <div class="flex items-center space-x-2">
                  <div class={"h-2 w-2 rounded-full bg-#{contract.resource.color}-400"}></div>
                  <span class="font-medium"><%= contract.resource.name %></span>
                </div>
              </:col>

              <:col :let={contract} label="Duration" width="w-24">
                <%= contract.duration_months %> month<%= if contract.duration_months > 1, do: "s" %>
              </:col>

              <:col :let={contract} label="Period" width="w-48">
                <span class="text-sm">
                  <%= format_date(contract.start_date) %> - <%= format_date(contract.end_date) %>
                </span>
              </:col>

              <:col :let={contract} label="Status" width="w-24">
                <.status_badge status={contract.status} />
              </:col>

              <:col :let={contract} label="Total" width="w-24">
                <span class="font-medium">
                  <%= Contracts.format_price(contract.total_amount_cents) %>
                </span>
              </:col>

              <:col :let={contract} label="" width="w-24">
                <div class="flex justify-end space-x-2">
                  <%= if contract.status == :active do %>
                    <.button
                      variant={:danger}
                      size={:small}
                      phx-click={show_modal("cancel-contract-modal-#{contract.id}")}
                    >
                      Cancel
                    </.button>
                  <% end %>
                </div>
              </:col>
            </.table>
          </div>
        <% end %>

        <%= for contract <- @contracts, contract.status == :active do %>
          <.modal
            id={"cancel-contract-modal-#{contract.id}"}
            on_confirm={JS.push("cancel_contract", value: %{id: contract.id}) |> hide_modal("cancel-contract-modal-#{contract.id}")}
            icon={nil}
          >
            <:title>Cancel Contract</:title>
            <p class="text-gray-600">
              Are you sure you want to cancel your contract for
              <span class="font-bold"><%= contract.resource.name %></span>?
            </p>
            <p class="mt-2 text-sm text-gray-500">
              This action cannot be undone. Please contact support for refund inquiries.
            </p>
            <:confirm phx-disable-with="Cancelling..." variant={:danger}>
              Cancel Contract
            </:confirm>
            <:cancel>Keep Contract</:cancel>
          </.modal>
        <% end %>
      </div>
    </.page>
    """
  end

  @impl true
  def handle_event("cancel_contract", %{"id" => id}, socket) do
    contract = Contracts.get_contract!(id)

    case Contracts.cancel_contract(contract, socket.assigns.current_user) do
      {:ok, _contract} ->
        contracts = Contracts.list_user_contracts(socket.assigns.current_user)

        {:noreply,
         socket
         |> assign(contracts: contracts)
         |> put_flash(:info, "Contract cancelled successfully.")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You are not authorized to cancel this contract.")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not cancel contract. Please try again.")}
    end
  end

  defp status_badge(assigns) do
    {bg_color, text_color} =
      case assigns.status do
        :active -> {"bg-green-100", "text-green-800"}
        :pending -> {"bg-yellow-100", "text-yellow-800"}
        :cancelled -> {"bg-red-100", "text-red-800"}
        :expired -> {"bg-gray-100", "text-gray-800"}
        _ -> {"bg-gray-100", "text-gray-800"}
      end

    assigns = assign(assigns, bg_color: bg_color, text_color: text_color)

    ~H"""
    <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize #{@bg_color} #{@text_color}"}>
      <%= @status %>
    </span>
    """
  end

  defp format_date(%Date{} = date) do
    Calendar.strftime(date, "%b %d, %Y")
  end
end
