defmodule OverbookedWeb.SpacesLive do
  @moduledoc """
  LiveView for browsing and renting office spaces.
  """
  use OverbookedWeb, :live_view

  alias Overbooked.Resources
  alias Overbooked.Contracts
  alias Overbooked.Stripe

  @impl true
  def mount(_params, _session, socket) do
    spaces = Resources.list_rentable_spaces()

    {:ok,
     socket
     |> assign(spaces: spaces)
     |> assign(selected_space: nil)
     |> assign(duration: 1)
     |> assign(checkout_loading: false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header label="Office Spaces"></.header>

    <.page>
      <div class="w-full space-y-8">
        <div class="text-gray-600">
          Browse available office spaces for long-term rental. Choose from 1-month or 3-month contracts.
        </div>

        <%= if Enum.empty?(@spaces) do %>
          <div class="text-center py-12 text-gray-500">
            <.icon name={:office_building} class="mx-auto h-12 w-12 text-gray-400" />
            <h3 class="mt-2 text-sm font-medium text-gray-900">No spaces available</h3>
            <p class="mt-1 text-sm text-gray-500">
              Check back later for available office spaces.
            </p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for space <- @spaces do %>
              <.space_card
                space={space}
                on_select={JS.push("select_space", value: %{id: space.id})}
              />
            <% end %>
          </div>
        <% end %>

        <%= if @selected_space do %>
          <.modal id="checkout-modal" show={true} on_cancel={JS.push("close_modal")}>
            <:title>Book <%= @selected_space.name %></:title>

            <div class="space-y-6">
              <%= if @selected_space.description do %>
                <p class="text-gray-600"><%= @selected_space.description %></p>
              <% end %>

              <div class="space-y-3">
                <label class="block text-sm font-medium text-gray-700">
                  Select Contract Duration
                </label>

                <div class="space-y-2">
                  <label class={"flex items-center p-4 border rounded-lg cursor-pointer #{if @duration == 1, do: "border-primary-500 bg-primary-50", else: "border-gray-200 hover:bg-gray-50"}"}>
                    <input
                      type="radio"
                      name="duration"
                      value="1"
                      checked={@duration == 1}
                      phx-click="set_duration"
                      phx-value-months="1"
                      class="h-4 w-4 text-primary-500 focus:ring-primary-500"
                    />
                    <div class="ml-3 flex-1">
                      <span class="block text-sm font-medium text-gray-900">1 Month</span>
                      <span class="block text-sm text-gray-500">
                        <%= Contracts.format_price(@selected_space.monthly_rate_cents) %>
                      </span>
                    </div>
                  </label>

                  <label class={"flex items-center p-4 border rounded-lg cursor-pointer #{if @duration == 3, do: "border-primary-500 bg-primary-50", else: "border-gray-200 hover:bg-gray-50"}"}>
                    <input
                      type="radio"
                      name="duration"
                      value="3"
                      checked={@duration == 3}
                      phx-click="set_duration"
                      phx-value-months="3"
                      class="h-4 w-4 text-primary-500 focus:ring-primary-500"
                    />
                    <div class="ml-3 flex-1">
                      <span class="block text-sm font-medium text-gray-900">3 Months</span>
                      <span class="block text-sm text-gray-500">
                        <%= Contracts.format_price(Contracts.calculate_total(@selected_space.monthly_rate_cents, 3)) %>
                        <span class="ml-2 text-green-600 text-xs font-medium">Save 10%</span>
                      </span>
                    </div>
                  </label>
                </div>
              </div>

              <div class="bg-gray-50 p-4 rounded-lg">
                <div class="flex justify-between text-sm">
                  <span class="text-gray-600">Contract Period</span>
                  <span class="font-medium">
                    <%= Date.utc_today() %> - <%= Date.add(Date.utc_today(), @duration * 30) %>
                  </span>
                </div>
                <div class="flex justify-between text-sm mt-2">
                  <span class="text-gray-600">Total</span>
                  <span class="font-bold text-lg">
                    <%= Contracts.format_price(Contracts.calculate_total(@selected_space.monthly_rate_cents, @duration)) %>
                  </span>
                </div>
              </div>

              <.button
                phx-click="checkout"
                class="w-full btn-primary"
                disabled={@checkout_loading}
              >
                <%= if @checkout_loading do %>
                  Processing...
                <% else %>
                  Proceed to Payment
                <% end %>
              </.button>
            </div>
          </.modal>
        <% end %>
      </div>
    </.page>
    """
  end

  @impl true
  def handle_event("select_space", %{"id" => id}, socket) do
    space = Resources.get_rentable_space(id)
    {:noreply, assign(socket, selected_space: space, duration: 1)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, selected_space: nil)}
  end

  @impl true
  def handle_event("set_duration", %{"months" => months}, socket) do
    {:noreply, assign(socket, duration: String.to_integer(months))}
  end

  @impl true
  def handle_event("checkout", _, socket) do
    space = socket.assigns.selected_space
    user = socket.assigns.current_user
    duration = socket.assigns.duration

    base_url = OverbookedWeb.Endpoint.url()
    success_url = base_url <> "/contracts/success?session_id={CHECKOUT_SESSION_ID}"
    cancel_url = base_url <> "/spaces"

    socket = assign(socket, checkout_loading: true)

    case Stripe.create_checkout_session(space, duration, user, success_url, cancel_url) do
      {:ok, session} ->
        {:noreply, redirect(socket, external: session.url)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(checkout_loading: false)
         |> put_flash(:error, "Could not start checkout. Please try again.")}
    end
  end

  # Space card component
  defp space_card(assigns) do
    ~H"""
    <div class="bg-white border border-gray-200 rounded-lg overflow-hidden shadow-sm hover:shadow-md transition-shadow">
      <div class="p-6">
        <div class="flex items-start justify-between">
          <div>
            <h3 class="text-lg font-semibold text-gray-900"><%= @space.name %></h3>
            <%= if @space.resource_type do %>
              <span class="text-sm text-gray-500 capitalize"><%= @space.resource_type.name %></span>
            <% end %>
          </div>
          <div class={"h-3 w-3 rounded-full bg-#{@space.color}-400"}></div>
        </div>

        <%= if @space.description do %>
          <p class="mt-3 text-sm text-gray-600 line-clamp-2"><%= @space.description %></p>
        <% end %>

        <%= if @space.amenities && Enum.any?(@space.amenities) do %>
          <div class="mt-3 flex flex-wrap gap-1">
            <%= for amenity <- Enum.take(@space.amenities, 3) do %>
              <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800">
                <%= amenity.name %>
              </span>
            <% end %>
            <%= if length(@space.amenities) > 3 do %>
              <span class="text-xs text-gray-500">+<%= length(@space.amenities) - 3 %> more</span>
            <% end %>
          </div>
        <% end %>

        <div class="mt-4 pt-4 border-t border-gray-100">
          <div class="flex items-center justify-between">
            <div>
              <span class="text-2xl font-bold text-gray-900">
                <%= Contracts.format_price(@space.monthly_rate_cents) %>
              </span>
              <span class="text-sm text-gray-500">/month</span>
            </div>
            <.button phx-click={@on_select} variant={:primary} size={:small}>
              Book Now
            </.button>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
