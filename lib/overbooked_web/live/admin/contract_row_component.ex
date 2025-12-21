defmodule OverbookedWeb.ContractRowComponent do
  use OverbookedWeb, :live_component

  alias Overbooked.Contracts

  def render(assigns) do
    ~H"""
    <tr id={@id} class={@class} tabindex="0">
      <.modal id={"contract-details-modal-#{@contract.id}"} icon={nil}>
        <:title>Contract Details</:title>
        <div class="space-y-4">
          <div class="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span class="text-gray-500">User:</span>
              <p class="font-medium"><%= @contract.user.name %></p>
              <p class="text-xs text-gray-500"><%= @contract.user.email %></p>
            </div>
            <div>
              <span class="text-gray-500">Space:</span>
              <p class="font-medium">
                <%= if @contract.resource, do: @contract.resource.name, else: "Deleted" %>
              </p>
            </div>
            <div>
              <span class="text-gray-500">Duration:</span>
              <p class="font-medium"><%= @contract.duration_months %> month(s)</p>
            </div>
            <div>
              <span class="text-gray-500">Status:</span>
              <p class="font-medium"><%= @contract.status %></p>
            </div>
            <div>
              <span class="text-gray-500">Start Date:</span>
              <p class="font-medium"><%= format_date(@contract.start_date) %></p>
            </div>
            <div>
              <span class="text-gray-500">End Date:</span>
              <p class="font-medium"><%= format_date(@contract.end_date) %></p>
            </div>
            <div>
              <span class="text-gray-500">Monthly Rate:</span>
              <p class="font-medium"><%= Contracts.format_price(@contract.monthly_rate_cents) %></p>
            </div>
            <div>
              <span class="text-gray-500">Total Amount:</span>
              <p class="font-medium"><%= Contracts.format_price(@contract.total_amount_cents) %></p>
            </div>
          </div>

          <%= if @contract.stripe_checkout_session_id || @contract.stripe_payment_intent_id || @contract.stripe_customer_id do %>
            <div class="border-t pt-4 mt-4">
              <h4 class="text-sm font-medium text-gray-700 mb-2">Stripe Details</h4>
              <div class="space-y-2 text-xs">
                <%= if @contract.stripe_checkout_session_id do %>
                  <div>
                    <span class="text-gray-500">Checkout Session:</span>
                    <code class="ml-2 bg-gray-100 px-1 py-0.5 rounded text-xs break-all">
                      <%= @contract.stripe_checkout_session_id %>
                    </code>
                  </div>
                <% end %>
                <%= if @contract.stripe_payment_intent_id do %>
                  <div>
                    <span class="text-gray-500">Payment Intent:</span>
                    <code class="ml-2 bg-gray-100 px-1 py-0.5 rounded text-xs break-all">
                      <%= @contract.stripe_payment_intent_id %>
                    </code>
                  </div>
                <% end %>
                <%= if @contract.stripe_customer_id do %>
                  <div>
                    <span class="text-gray-500">Customer ID:</span>
                    <code class="ml-2 bg-gray-100 px-1 py-0.5 rounded text-xs break-all">
                      <%= @contract.stripe_customer_id %>
                    </code>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <%= if @contract.refund_id do %>
            <div class="border-t pt-4 mt-4">
              <h4 class="text-sm font-medium text-orange-700 mb-2">Refund Information</h4>
              <div class="space-y-2 text-xs bg-orange-50 p-3 rounded">
                <div>
                  <span class="text-gray-500">Refund ID:</span>
                  <code class="ml-2 bg-orange-100 px-1 py-0.5 rounded text-xs break-all">
                    <%= @contract.refund_id %>
                  </code>
                </div>
                <div>
                  <span class="text-gray-500">Amount Refunded:</span>
                  <span class="ml-2 font-medium text-orange-700">
                    <%= Contracts.format_price(@contract.refund_amount_cents) %>
                  </span>
                </div>
                <div>
                  <span class="text-gray-500">Refunded At:</span>
                  <span class="ml-2"><%= format_datetime(@contract.refunded_at) %></span>
                </div>
              </div>
            </div>
          <% end %>

          <div class="border-t pt-4 mt-4 text-xs text-gray-500">
            <p>Created: <%= format_datetime(@contract.inserted_at) %></p>
            <p>Updated: <%= format_datetime(@contract.updated_at) %></p>
          </div>
        </div>
        <:cancel>Close</:cancel>
      </.modal>

      <.modal
        id={"cancel-contract-modal-#{@contract.id}"}
        on_confirm={
          JS.push("cancel_contract", value: %{id: @contract.id})
          |> hide_modal("cancel-contract-modal-#{@contract.id}")
        }
        icon={nil}
      >
        <:title>Cancel Contract</:title>
        <span>
          Are you sure you want to cancel this contract?
          <br /><br />
          <strong>User:</strong> <%= @contract.user.name %><br />
          <strong>Space:</strong> <%= if @contract.resource, do: @contract.resource.name, else: "N/A" %><br />
          <strong>Amount:</strong> <%= Contracts.format_price(@contract.total_amount_cents) %>
          <br /><br />
          <span class="text-red-600 text-sm">
            Note: This will cancel the contract but will not automatically process a refund.
            You may need to handle the refund separately in Stripe.
          </span>
        </span>
        <:confirm phx-disable-with="Cancelling..." variant={:danger}>
          Cancel Contract
        </:confirm>

        <:cancel>Keep Contract</:cancel>
      </.modal>

      <%= if @contract.stripe_payment_intent_id and is_nil(@contract.refund_id) do %>
        <.modal
          id={"refund-contract-modal-#{@contract.id}"}
          on_confirm={
            JS.push("refund_contract", value: %{id: @contract.id})
            |> hide_modal("refund-contract-modal-#{@contract.id}")
          }
          icon={nil}
        >
          <:title>Refund Contract</:title>
          <span>
            Are you sure you want to issue a full refund for this contract?
            <br /><br />
            <strong>User:</strong> <%= @contract.user.name %><br />
            <strong>Space:</strong> <%= if @contract.resource, do: @contract.resource.name, else: "N/A" %><br />
            <strong>Amount to Refund:</strong> <%= Contracts.format_price(@contract.total_amount_cents) %>
            <br /><br />
            <span class="text-orange-600 text-sm">
              This will initiate a refund through Stripe. The funds will be returned to the customer's
              original payment method within 5-10 business days.
            </span>
          </span>
          <:confirm phx-disable-with="Processing Refund..." variant={:warning}>
            Issue Refund
          </:confirm>

          <:cancel>Cancel</:cancel>
        </.modal>
      <% end %>

      <%= for {col, _i} <- Enum.with_index(@col) do %>
        <td class={"px-6 py-3 text-sm font-medium text-gray-900 #{col[:class]}"}>
          <div class="flex items-center space-x-3 lg:pl-2">
            <%= render_slot(col, assigns) %>
          </div>
        </td>
      <% end %>
    </tr>
    """
  end

  defp format_date(date) do
    Calendar.strftime(date, "%b %d, %Y")
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y at %H:%M")
  end

  def update(assigns, socket) do
    {:ok,
     assign(socket,
       id: assigns.id,
       contract: assigns.row,
       col: assigns.col,
       class: assigns.class,
       index: assigns.index
     )}
  end
end
