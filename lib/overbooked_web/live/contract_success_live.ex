defmodule OverbookedWeb.ContractSuccessLive do
  @moduledoc """
  LiveView for displaying successful contract payment confirmation.
  """
  use OverbookedWeb, :live_view

  alias Overbooked.Contracts

  @impl true
  def mount(%{"session_id" => session_id}, _session, socket) do
    # In production, verify the session with Stripe
    # For now, we just display a success message

    {:ok,
     socket
     |> assign(session_id: session_id)
     |> assign(loading: true)
     |> assign(contract: nil)}
  end

  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: ~p"/contracts")}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    # Check if contract exists for this session
    case Contracts.get_contract_by_session_id(socket.assigns.session_id) do
      nil ->
        # Contract might still be processing via webhook
        {:noreply, assign(socket, loading: false, contract: nil)}

      contract ->
        contract = Contracts.get_contract!(contract.id)
        {:noreply, assign(socket, loading: false, contract: contract)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page>
      <div class="max-w-lg mx-auto text-center py-12">
        <%= if @loading do %>
          <div class="animate-pulse">
            <div class="h-16 w-16 bg-gray-200 rounded-full mx-auto"></div>
            <div class="mt-4 h-6 bg-gray-200 rounded w-48 mx-auto"></div>
          </div>
        <% else %>
          <div class="bg-green-100 rounded-full h-16 w-16 flex items-center justify-center mx-auto">
            <.icon name={:check} class="h-8 w-8 text-green-600" />
          </div>

          <h1 class="mt-6 text-2xl font-bold text-gray-900">Payment Successful!</h1>

          <%= if @contract do %>
            <p class="mt-2 text-gray-600">
              Your contract for <strong><%= @contract.resource.name %></strong> has been confirmed.
            </p>

            <div class="mt-6 bg-gray-50 rounded-lg p-6 text-left">
              <h3 class="font-medium text-gray-900">Contract Details</h3>
              <dl class="mt-4 space-y-2 text-sm">
                <div class="flex justify-between">
                  <dt class="text-gray-500">Space</dt>
                  <dd class="font-medium"><%= @contract.resource.name %></dd>
                </div>
                <div class="flex justify-between">
                  <dt class="text-gray-500">Duration</dt>
                  <dd class="font-medium"><%= @contract.duration_months %> month(s)</dd>
                </div>
                <div class="flex justify-between">
                  <dt class="text-gray-500">Start Date</dt>
                  <dd class="font-medium"><%= format_date(@contract.start_date) %></dd>
                </div>
                <div class="flex justify-between">
                  <dt class="text-gray-500">End Date</dt>
                  <dd class="font-medium"><%= format_date(@contract.end_date) %></dd>
                </div>
                <div class="flex justify-between pt-2 border-t">
                  <dt class="text-gray-700 font-medium">Total Paid</dt>
                  <dd class="font-bold text-lg"><%= Contracts.format_price(@contract.total_amount_cents) %></dd>
                </div>
              </dl>
            </div>
          <% else %>
            <p class="mt-2 text-gray-600">
              Your payment is being processed. You will receive a confirmation email shortly.
            </p>
          <% end %>

          <div class="mt-8 space-x-4">
            <.link navigate={~p"/contracts"}>
              <.button variant={:primary}>View My Contracts</.button>
            </.link>
            <.link navigate={~p"/"}>
              <.button variant={:secondary}>Go to Home</.button>
            </.link>
          </div>
        <% end %>
      </div>
    </.page>
    """
  end

  defp format_date(%Date{} = date) do
    Calendar.strftime(date, "%B %d, %Y")
  end
end
