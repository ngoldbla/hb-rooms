defmodule OverbookedWeb.SpaceRowComponent do
  use OverbookedWeb, :live_component

  alias Overbooked.Contracts

  def render(assigns) do
    ~H"""
    <tr id={@id} class={@class} tabindex="0">
      <.modal
        id={"edit-space-modal-#{@space.id}"}
        on_confirm={hide_modal("edit-space-modal-#{@space.id}")}
        icon={nil}
      >
        <:title>Edit <%= @space.name %></:title>
        <.form
          :let={f}
          for={@changeset}
          phx-change="validate_update"
          phx-submit="update"
          id={"edit-space-form-#{@space.id}"}
          class="flex flex-col space-y-4"
        >
          <input class="hidden" type="hidden" value={@space.id} name="resource_id" />

          <div>
            <label for="name" class="block text-sm font-medium text-gray-700">
              Name
            </label>
            <div class="mt-1">
              <.text_input form={f} field={:name} phx_debounce="blur" required={true} />
              <.error form={f} field={:name} />
            </div>
          </div>

          <div>
            <label for="color" class="block text-sm font-medium text-gray-700">
              Color
            </label>
            <div class="mt-1">
              <.select
                form={f}
                field={:color}
                options={
                  Enum.map(
                    ~w(gray red yellow green blue indigo pink purple),
                    &{String.capitalize(&1), &1}
                  )
                }
              />
              <.error form={f} field={:color} />
            </div>
          </div>

          <div>
            <label class="flex items-center space-x-2">
              <input
                type="checkbox"
                name="resource[is_rentable]"
                value="true"
                checked={@space.is_rentable == true}
                class="h-4 w-4 rounded border-gray-300 text-primary-600 focus:ring-primary-500"
              />
              <span class="text-sm font-medium text-gray-700">Available for rent</span>
            </label>
          </div>

          <div>
            <label for="monthly_rate" class="block text-sm font-medium text-gray-700">
              Monthly Rate ($)
            </label>
            <div class="mt-1">
              <.number_input
                form={f}
                field={:monthly_rate_dollars}
                value={dollars_from_cents(@space.monthly_rate_cents)}
                min="0"
                step="0.01"
              />
              <.error form={f} field={:monthly_rate_cents} />
            </div>
          </div>

          <div>
            <label for="description" class="block text-sm font-medium text-gray-700">
              Description
            </label>
            <div class="mt-1">
              <textarea
                name="resource[description]"
                rows="3"
                class="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm"
              ><%= @space.description %></textarea>
              <.error form={f} field={:description} />
            </div>
          </div>

          <div class="flex flex-col space-y-4">
            <label for="amenities" class="block text-sm font-medium text-gray-700">
              Amenities
            </label>
            <.checkbox_group
              form={f}
              layout={:grid}
              field={:amenities}
              options={Enum.map(@amenities, &{&1.name, &1.id})}
            />
          </div>
        </.form>
        <:confirm
          type="submit"
          form={"edit-space-form-#{@space.id}"}
          phx-disable-with="Saving..."
          disabled={!@changeset.valid?}
          variant={:secondary}
        >
          Save
        </:confirm>

        <:cancel>Cancel</:cancel>
      </.modal>

      <.modal id={"space-amenities-modal-#{@space.id}"} icon={nil}>
        <:title>Amenities for <%= @space.name %></:title>
        <div class="flex flex-row gap-2 flex-wrap">
          <%= for amenity <- @space.amenities do %>
            <.badge color="gray"><%= amenity.name %></.badge>
          <% end %>
        </div>
        <:cancel>Close</:cancel>
      </.modal>

      <.modal
        id={"remove-space-modal-#{@space.id}"}
        on_confirm={
          JS.push("delete", value: %{id: @space.id})
          |> hide_modal("remove-space-modal-#{@space.id}")
          |> hide("#space-#{@space.id}")
        }
        icon={nil}
      >
        <:title>Remove space</:title>
        <span>
          Are you sure you want to remove <span class="font-bold"><%= @space.name %>?</span>
          <%= if @space.has_active_contract do %>
            <br /><br />
            <span class="text-red-600 font-medium">
              Warning: This space has an active contract!
            </span>
          <% end %>
        </span>
        <:confirm phx-disable-with="Removing..." variant={:danger}>
          Remove
        </:confirm>

        <:cancel>Cancel</:cancel>
      </.modal>

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

  defp dollars_from_cents(nil), do: ""

  defp dollars_from_cents(cents) when is_integer(cents) do
    :erlang.float_to_binary(cents / 100, decimals: 2)
  end

  def update(assigns, socket) do
    {:ok,
     assign(socket,
       id: assigns.id,
       space: assigns.row,
       col: assigns.col,
       class: assigns.class,
       index: assigns.index,
       amenities: assigns.amenities,
       resource_types: assigns.resource_types,
       changeset: assigns.changeset
     )}
  end
end
