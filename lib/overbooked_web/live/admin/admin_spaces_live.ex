defmodule OverbookedWeb.AdminSpacesLive do
  use OverbookedWeb, :live_view

  alias Overbooked.Resources
  alias Overbooked.Resources.Resource
  alias Overbooked.Contracts

  @impl true
  def mount(_params, _session, socket) do
    changeset = Resources.change_resource(%Resource{})

    {:ok,
     socket
     |> assign_amenities()
     |> assign_resource_types()
     |> assign_spaces()
     |> assign(changeset: changeset)
     |> assign(edit_changeset: changeset)}
  end

  defp assign_amenities(socket) do
    amenities = Resources.list_amenities()
    assign(socket, amenities: amenities)
  end

  defp assign_resource_types(socket) do
    # Get available resource types for the dropdown
    resource_types = [
      {"Room", "room"},
      {"Desk", "desk"}
    ]

    assign(socket, resource_types: resource_types)
  end

  defp assign_spaces(socket) do
    # List all resources with their amenities and active contract status
    spaces = Resources.list_resources_with_status()
    assign(socket, spaces: spaces)
  end

  @impl true
  def render(assigns) do
    # Section tabs for Rentals group (Spaces, Contracts)
    assigns = assign(assigns, :rentals_tabs, [
      %{id: :admin_spaces, label: "Spaces", path: Routes.admin_spaces_path(assigns.socket, :index)},
      %{id: :admin_contracts, label: "Contracts", path: Routes.admin_contracts_path(assigns.socket, :index)}
    ])

    ~H"""
    <.header label="Admin">
      <.admin_tabs active_tab={@active_tab} socket={@socket} />
    </.header>

    <.modal id="add-space-modal" on_confirm={hide_modal("add-space-modal")} icon={nil}>
      <:title>Add a new space</:title>
      <.form
        :let={f}
        for={@changeset}
        phx-submit="create"
        phx-change="validate"
        id="add-space-form"
        class="flex flex-col space-y-4"
      >
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
          <label for="resource_type_name" class="block text-sm font-medium text-gray-700">
            Resource Type
          </label>
          <div class="mt-1">
            <.select form={f} field={:resource_type_name} options={@resource_types} />
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
              checked={Phoenix.HTML.Form.input_value(f, :is_rentable) == true}
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
            <.number_input form={f} field={:monthly_rate_dollars} min="0" step="0.01" />
            <.error form={f} field={:monthly_rate_cents} />
          </div>
          <p class="mt-1 text-xs text-gray-500">Leave empty if not rentable</p>
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
            ><%= Phoenix.HTML.Form.input_value(f, :description) %></textarea>
            <.error form={f} field={:description} />
          </div>
        </div>

        <div class="flex flex-col space-y-4">
          <label for="amenities" class="block text-sm font-medium text-gray-700">
            Amenities
          </label>
          <.checkbox_group
            layout={:grid}
            form={f}
            field={:amenities}
            options={Enum.map(@amenities, &{&1.name, &1.id})}
          />
        </div>
      </.form>
      <:confirm
        type="submit"
        form="add-space-form"
        phx-disable-with="Saving..."
        disabled={!@changeset.valid?}
        variant={:secondary}
      >
        Save
      </:confirm>

      <:cancel>Cancel</:cancel>
    </.modal>

    <.page>
      <.section_tabs active_tab={@active_tab} socket={@socket} tabs={@rentals_tabs} />

      <div class="w-full space-y-12">
        <div class="w-full">
          <div class="w-full flex flex-row justify-between">
            <h3>Rentable Spaces</h3>
            <.button type="button" phx-click={show_modal("add-space-modal")}>
              New space
            </.button>
          </div>
          <.live_table
            module={OverbookedWeb.SpaceRowComponent}
            id="spaces"
            changeset={@edit_changeset}
            amenities={@amenities}
            resource_types={@resource_types}
            rows={@spaces}
            row_id={fn space -> "space-#{space.id}" end}
          >
            <:col :let={%{space: space}} label="Name" width="w-32"><%= space.name %></:col>
            <:col :let={%{space: space}} label="Type" width="w-20">
              <%= if space.resource_type, do: space.resource_type.name, else: "-" %>
            </:col>
            <:col :let={%{space: space}} label="Rentable" width="w-20">
              <%= if space.is_rentable do %>
                <.badge color="green">Yes</.badge>
              <% else %>
                <.badge color="gray">No</.badge>
              <% end %>
            </:col>
            <:col :let={%{space: space}} label="Monthly Rate" width="w-24">
              <%= if space.monthly_rate_cents do %>
                <%= format_price(space.monthly_rate_cents) %>
              <% else %>
                -
              <% end %>
            </:col>
            <:col :let={%{space: space}} label="Status" width="w-24">
              <%= if space.has_active_contract do %>
                <.badge color="yellow">Occupied</.badge>
              <% else %>
                <.badge color="green">Available</.badge>
              <% end %>
            </:col>
            <:col :let={%{space: space}} label="">
              <div class="w-full flex flex-row-reverse space-x-2 space-x-reverse">
                <.button
                  phx-click={show_modal("remove-space-modal-#{space.id}")}
                  variant={:danger}
                  size={:small}
                >
                  Remove
                </.button>
                <.button
                  phx-click={
                    JS.push("edit", value: %{id: space.id})
                    |> show_modal("edit-space-modal-#{space.id}")
                  }
                  size={:small}
                >
                  Edit
                </.button>
              </div>
            </:col>
          </.live_table>
        </div>
      </div>
    </.page>
    """
  end

  defp format_price(cents) when is_integer(cents) do
    Contracts.format_price(cents)
  end

  defp format_price(_), do: "-"

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    resource = Resources.get_resource!(id)

    edit_changeset =
      resource
      |> Resources.change_resource(%{})

    {:noreply, assign(socket, edit_changeset: edit_changeset)}
  end

  @impl true
  def handle_event("validate_update", %{"resource" => resource_params}, socket) do
    resource_params = convert_rate_to_cents(resource_params)

    changeset =
      %Resource{}
      |> Resources.change_resource(resource_params)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, edit_changeset: changeset)}
  end

  @impl true
  def handle_event("update", params, socket) do
    %{"resource" => resource_params, "resource_id" => id} = params
    resource_params = convert_rate_to_cents(resource_params)
    resource_params = handle_checkbox(resource_params, "is_rentable")

    resource = Resources.get_resource!(id)

    case Resources.update_resource(resource, resource_params) do
      {:ok, _resource} ->
        {:noreply,
         socket
         |> put_flash(:info, "Space updated successfully.")
         |> assign_spaces()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, edit_changeset: changeset)}
    end
  end

  @impl true
  def handle_event("validate", %{"resource" => resource_params}, socket) do
    resource_params = convert_rate_to_cents(resource_params)

    changeset =
      %Resource{}
      |> Resources.change_resource(resource_params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("create", %{"resource" => resource_params}, socket) do
    resource_type_name = Map.get(resource_params, "resource_type_name", "room")
    resource_params = convert_rate_to_cents(resource_params)
    resource_params = handle_checkbox(resource_params, "is_rentable")

    create_fn =
      case resource_type_name do
        "desk" -> &Resources.create_desk/1
        _ -> &Resources.create_room/1
      end

    case create_fn.(resource_params) do
      {:ok, _resource} ->
        {:noreply,
         socket
         |> put_flash(:info, "Space created successfully.")
         |> assign_spaces()
         |> assign(changeset: Resources.change_resource(%Resource{}))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _} =
      id
      |> Resources.get_resource!()
      |> Resources.delete_resource()

    {:noreply, assign_spaces(socket)}
  end

  # Convert dollar amount to cents for storage
  defp convert_rate_to_cents(params) do
    case Map.get(params, "monthly_rate_dollars") do
      nil ->
        params

      "" ->
        params

      dollars_str ->
        case Float.parse(dollars_str) do
          {dollars, _} ->
            cents = trunc(dollars * 100)
            Map.put(params, "monthly_rate_cents", cents)

          :error ->
            params
        end
    end
  end

  # Handle checkbox boolean conversion
  defp handle_checkbox(params, field) do
    case Map.get(params, field) do
      "true" -> Map.put(params, field, true)
      nil -> Map.put(params, field, false)
      _ -> params
    end
  end
end
