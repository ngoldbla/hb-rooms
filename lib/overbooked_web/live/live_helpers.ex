defmodule OverbookedWeb.LiveHelpers do
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias OverbookedWeb.Router.Helpers, as: Routes

  ## String formatters

  def relative_time(nil), do: ""

  def relative_time(datetime) do
    {:ok, str} = Timex.format(datetime, "{relative}", :relative)
    str
  end

  def from_to_datetime(from_date, to_date) do
    same_year = Timex.compare(from_date, to_date, :year) == 0
    same_month = Timex.compare(from_date, to_date, :month) == 0
    same_day = Timex.compare(from_date, to_date, :day) == 0

    {:ok, from_date_str} =
      Timex.format(from_date, "#{if !same_year, do: "{YYYY}"} {Mshort} {D} {h24}:{m}")

    {:ok, to_date_str} =
      Timex.format(
        to_date,
        "#{if !same_year, do: "{YYYY}"} #{if !same_month, do: "{Mshort}"} #{if same_day, do: "{h24}:{m}", else: "{D} {h24}:{m}"}"
      )

    "#{from_date_str} - #{to_date_str}"
  end

  def from_to_datetime(from_date, to_date, :hours) do
    {:ok, from_date_str} = Timex.format(from_date, "{h24}:{m}")
    {:ok, to_date_str} = Timex.format(to_date, "{h24}:{m}")

    "#{from_date_str} - #{to_date_str}"
  end

  attr :flash, :map
  attr :kind, :atom

  def flash(%{kind: :error} = assigns) do
    ~H"""
    <%= if live_flash(@flash, @kind) do %>
      <div
        id="flash"
        class="rounded-md bg-red-50 p-4 fixed top-1 right-1 w-96 fade-in-scale z-50"
        phx-click={
          JS.push("lv:clear-flash")
          |> JS.remove_class("fade-in-scale", to: "#flash")
          |> hide("#flash")
        }
        phx-hook="Flash"
      >
        <div class="flex justify-between items-center space-x-3 text-red-700">
          <.icon name={:exclamation_circle} class="w-5 w-5" />
          <p class="flex-1 text-sm font-medium" role="alert">
            <%= live_flash(@flash, @kind) %>
          </p>
          <button
            type="button"
            class="inline-flex bg-red-50 rounded-md p-1.5 text-red-500 hover:bg-red-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-red-50 focus:ring-red-600"
          >
            <.icon name={:x} class="w-4 h-4" />
          </button>
        </div>
      </div>
    <% end %>
    """
  end

  def flash(%{kind: :info} = assigns) do
    ~H"""
    <%= if live_flash(@flash, @kind) do %>
      <div
        id="flash"
        class="rounded-md bg-green-50 p-4 fixed top-1 right-1 w-96 fade-in-scale z-50"
        phx-click={JS.push("lv:clear-flash") |> JS.remove_class("fade-in-scale") |> hide("#flash")}
        phx-value-key="info"
        phx-hook="Flash"
      >
        <div class="flex justify-between items-center space-x-3 text-green-700">
          <.icon name={:check_circle} class="w-5 h-5" />
          <p class="flex-1 text-sm font-medium" role="alert">
            <%= live_flash(@flash, @kind) %>
          </p>
          <button
            type="button"
            class="inline-flex bg-green-50 rounded-md p-1.5 text-green-500 hover:bg-green-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-green-50 focus:ring-green-600"
          >
            <.icon name={:x} class="w-4 h-4" />
          </button>
        </div>
      </div>
    <% end %>
    """
  end

  def admin_tabs(assigns) do
    ~H"""
    <!-- Mobile: Dropdown -->
    <div class="block md:hidden w-full">
      <.admin_nav_mobile active_tab={@active_tab} socket={@socket} />
    </div>

    <!-- Tablet: Vertical Sidebar -->
    <div class="hidden md:block lg:hidden w-full">
      <.admin_nav_tablet active_tab={@active_tab} socket={@socket} />
    </div>

    <!-- Desktop: Horizontal Tabs with Grouping -->
    <div class="hidden lg:block w-full">
      <.admin_nav_desktop active_tab={@active_tab} socket={@socket} />
    </div>
    """
  end

  # Mobile navigation using horizontal scrollable chips
  # Avoids iOS Safari dropdown issues by using simple inline chips
  # Consolidated: Users, Resources (Rooms+Desks+Amenities), Rentals (Spaces+Contracts), Analytics, Settings
  defp admin_nav_mobile(assigns) do
    ~H"""
    <div class="w-full overflow-x-auto pb-2 -mx-1">
      <div class="flex flex-row gap-2 px-1 min-w-max">
        <.nav_chip
          path={Routes.admin_users_path(@socket, :index)}
          active={@active_tab == :admin_users}
          label="Users"
          icon={:users}
        />
        <.nav_chip
          path={Routes.admin_rooms_path(@socket, :index)}
          active={@active_tab in [:admin_rooms, :admin_desks, :admin_amenities]}
          label="Resources"
          icon={:cube}
        />
        <.nav_chip
          path={Routes.admin_spaces_path(@socket, :index)}
          active={@active_tab in [:admin_spaces, :admin_contracts]}
          label="Rentals"
          icon={:office_building}
        />
        <.nav_chip
          path={Routes.admin_analytics_path(@socket, :index)}
          active={@active_tab == :admin_analytics}
          label="Analytics"
          icon={:chart_bar}
        />
        <.nav_chip
          path={Routes.admin_settings_path(@socket, :index)}
          active={@active_tab in [:admin_settings, :admin_email_templates]}
          label="Settings"
          icon={:cog}
        />
      </div>
    </div>
    """
  end

  # Horizontal scrollable chip for navigation
  attr :path, :string, required: true
  attr :active, :boolean, required: true
  attr :label, :string, required: true
  attr :icon, :atom, required: true

  defp nav_chip(assigns) do
    ~H"""
    <.link
      navigate={@path}
      class={"inline-flex items-center px-4 py-2.5 rounded-full text-sm font-medium transition-all min-h-[44px] whitespace-nowrap touch-manipulation #{if @active, do: "bg-primary-600 text-white shadow-md", else: "bg-gray-100 text-gray-700 hover:bg-gray-200 active:bg-gray-300"}"}
    >
      <.icon name={@icon} class="w-4 h-4 mr-2" />
      <%= @label %>
    </.link>
    """
  end

  @doc """
  Section tabs for navigating within a consolidated admin panel.
  Used to switch between related items (e.g., Rooms/Desks/Amenities within Resources).
  """
  attr :active_tab, :atom, required: true
  attr :socket, :any, required: true
  attr :tabs, :list, required: true

  def section_tabs(assigns) do
    ~H"""
    <div class="flex flex-row gap-1 bg-gray-100 rounded-lg p-1 mb-4">
      <%= for tab <- @tabs do %>
        <.link
          navigate={tab.path}
          class={"flex-1 text-center px-3 py-2 text-sm font-medium rounded-md transition-all min-h-[40px] #{if @active_tab == tab.id, do: "bg-white text-gray-900 shadow-sm", else: "text-gray-600 hover:text-gray-900 hover:bg-gray-50"}"}
        >
          <%= tab.label %>
        </.link>
      <% end %>
    </div>
    """
  end

  # Get the consolidated group for an admin tab
  def get_admin_group(tab) do
    case tab do
      :admin_users -> :users
      :admin_rooms -> :resources
      :admin_desks -> :resources
      :admin_amenities -> :resources
      :admin_spaces -> :rentals
      :admin_contracts -> :rentals
      :admin_analytics -> :analytics
      :admin_settings -> :settings
      :admin_email_templates -> :settings
      _ -> :unknown
    end
  end

  # Tablet vertical sidebar navigation - consolidated to match mobile chips
  defp admin_nav_tablet(assigns) do
    ~H"""
    <nav class="space-y-1 py-2">
      <.nav_link active={@active_tab == :admin_users} path={Routes.admin_users_path(@socket, :index)}>
        <.icon name={:users} class="w-4 h-4 mr-2" /> Users
      </.nav_link>
      <.nav_link
        active={@active_tab in [:admin_rooms, :admin_desks, :admin_amenities]}
        path={Routes.admin_rooms_path(@socket, :index)}
      >
        <.icon name={:cube} class="w-4 h-4 mr-2" /> Resources
      </.nav_link>
      <.nav_link
        active={@active_tab in [:admin_spaces, :admin_contracts]}
        path={Routes.admin_spaces_path(@socket, :index)}
      >
        <.icon name={:office_building} class="w-4 h-4 mr-2" /> Rentals
      </.nav_link>
      <.nav_link active={@active_tab == :admin_analytics} path={Routes.admin_analytics_path(@socket, :index)}>
        <.icon name={:chart_bar} class="w-4 h-4 mr-2" /> Analytics
      </.nav_link>
      <.nav_link
        active={@active_tab in [:admin_settings, :admin_email_templates]}
        path={Routes.admin_settings_path(@socket, :index)}
      >
        <.icon name={:cog} class="w-4 h-4 mr-2" /> Settings
      </.nav_link>
    </nav>
    """
  end

  # Desktop horizontal tabs - consolidated to match mobile chips
  defp admin_nav_desktop(assigns) do
    ~H"""
    <div class="flex flex-row gap-3">
      <.desktop_tab active={@active_tab == :admin_users} path={Routes.admin_users_path(@socket, :index)}>
        <.icon name={:users} class="w-4 h-4 mr-1.5" /> Users
      </.desktop_tab>
      <.desktop_tab
        active={@active_tab in [:admin_rooms, :admin_desks, :admin_amenities]}
        path={Routes.admin_rooms_path(@socket, :index)}
      >
        <.icon name={:cube} class="w-4 h-4 mr-1.5" /> Resources
      </.desktop_tab>
      <.desktop_tab
        active={@active_tab in [:admin_spaces, :admin_contracts]}
        path={Routes.admin_spaces_path(@socket, :index)}
      >
        <.icon name={:office_building} class="w-4 h-4 mr-1.5" /> Rentals
      </.desktop_tab>
      <.desktop_tab active={@active_tab == :admin_analytics} path={Routes.admin_analytics_path(@socket, :index)}>
        <.icon name={:chart_bar} class="w-4 h-4 mr-1.5" /> Analytics
      </.desktop_tab>
      <.desktop_tab
        active={@active_tab in [:admin_settings, :admin_email_templates]}
        path={Routes.admin_settings_path(@socket, :index)}
      >
        <.icon name={:cog} class="w-4 h-4 mr-1.5" /> Settings
      </.desktop_tab>
    </div>
    """
  end

  # Helper component for sidebar navigation links
  attr :active, :boolean, default: false
  attr :path, :string, required: true
  slot :inner_block, required: true

  defp nav_link(assigns) do
    ~H"""
    <.link
      navigate={@path}
      class={"group flex items-center px-3 py-2.5 text-sm font-medium rounded-md transition-colors #{if @active, do: "bg-primary-100 text-primary-700", else: "text-gray-700 hover:bg-gray-100"}"}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  # Helper component for desktop tabs
  attr :active, :boolean, default: false
  attr :path, :string, required: true
  slot :inner_block, required: true

  defp desktop_tab(assigns) do
    ~H"""
    <.link
      navigate={@path}
      class={"px-3 py-1.5 text-sm font-medium rounded transition-colors #{if @active, do: "bg-gray-200 text-gray-700", else: "text-gray-500 hover:text-gray-700 hover:bg-gray-50"}"}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  def spinner(assigns) do
    ~H"""
    <svg
      class="inline-block animate-spin h-2.5 w-2.5 text-gray-400"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
      </circle>
      <path
        class="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      >
      </path>
    </svg>
    """
  end

  attr :name, :atom, required: true
  attr :outlined, :boolean, default: false
  attr :rest, :global, default: %{class: "w-4 h-4 inline-block"}

  def icon(assigns) do
    assigns = assign_new(assigns, :"aria-hidden", fn -> !Map.has_key?(assigns, :"aria-label") end)

    ~H"""
    <%= if @outlined do %>
      <%= apply(Heroicons, @name, [[outline: true] ++ Map.to_list(@rest)]) %>
    <% else %>
      <%= apply(Heroicons, @name, [[solid: true] ++ Map.to_list(@rest)]) %>
    <% end %>
    """
  end

  @doc """
  Returns a button triggered dropdown with aria keyboard and focus supporrt.
  Accepts the follow slots:
    * `:id` - The id to uniquely identify this dropdown
    * `:img` - The optional img to show beside the button title
    * `:title` - The button title
    * `:subtitle` - The button subtitle
  ## Examples
      <.dropdown id={@id}>
        <:img src={@current_user.avatar_url}/>
        <:title><%= @current_user.name %></:title>
        <:subtitle>@<%= @current_user.username %></:subtitle>
        <:link navigate={profile_path(@current_user)}>View Profile</:link>
        <:link navigate={Routes.settings_path(OverbookedWeb.Endpoint, :edit)}Settings</:link>
      </.dropdown>
  """
  attr :id, :string, required: true
  attr :ok, :string, required: true
  attr :img, :list, default: []
  attr :title, :list, default: []
  attr :subtitle, :list, default: []
  attr :link, :list, default: []

  def dropdown(assigns) do
    ~H"""
    <div class="px-3 relative inline-block text-left">
      <div>
        <button
          id={@id}
          type="button"
          class="border rounded-md border-2 group w-full bg-gray-100 rounded-md px-3.5 py-2 text-sm text-left font-medium text-gray-700 hover:bg-gray-200 focus:outline-none focus:ring-1 focus:ring-primary-500 focus:border-primary-500"
          phx-click={show_dropdown("##{@id}-dropdown")}
          data-active-class="bg-gray-100"
          aria-haspopup="true"
        >
          <span class="flex w-full justify-between items-center">
            <span class="flex min-w-0 items-center justify-between space-x-3">
              <%= for img <- @img do %>
                <img
                  class="w-10 h-10 bg-gray-300 rounded-full flex-shrink-0"
                  alt=""
                  {Phoenix.Component.assigns_to_attributes(img)}
                />
              <% end %>
              <span class="flex-1 flex flex-col min-w-0">
                <span class="text-gray-900 text-sm font-medium truncate">
                  <%= render_slot(@title) %>
                </span>
                <span class="text-gray-500 text-sm truncate"><%= render_slot(@subtitle) %></span>
              </span>
            </span>
            <svg
              class="flex-shrink-0 h-5 w-5 text-gray-400 group-hover:text-gray-500"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M10 3a1 1 0 01.707.293l3 3a1 1 0 01-1.414 1.414L10 5.414 7.707 7.707a1 1 0 01-1.414-1.414l3-3A1 1 0 0110 3zm-3.707 9.293a1 1 0 011.414 0L10 14.586l2.293-2.293a1 1 0 011.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z"
                clip-rule="evenodd"
              >
              </path>
            </svg>
          </span>
        </button>
      </div>
      <div
        id={"#{@id}-dropdown"}
        phx-click-away={hide_dropdown("##{@id}-dropdown")}
        class="hidden z-10 mx-3 origin-top absolute right-0 left-0 mt-1 min-w-max rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 divide-y divide-gray-200"
        role="menu"
        aria-labelledby={@id}
      >
        <div class="py-1" role="none">
          <%= for link <- @link do %>
            <.link
              tabindex="-1"
              role="menuitem"
              class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 focus:outline-none focus:ring-1 focus:ring-primary-500 focus:border-primary-500"
              {link}
            >
              <%= render_slot(link) %>
            </.link>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      display: "inline-block",
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 300,
      transition:
        {"transition ease-in duration-300", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  def show_dropdown(to) do
    JS.show(
      to: to,
      transition:
        {"transition ease-out duration-120", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"}
    )
    |> JS.set_attribute({"aria-expanded", "true"}, to: to)
  end

  def hide_dropdown(to) do
    JS.hide(
      to: to,
      transition:
        {"transition ease-in duration-120", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
    |> JS.remove_attribute("aria-expanded", to: to)
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(
      to: "##{id}",
      display: "inline-block",
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      display: "inline-block",
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> js_exec("##{id}-confirm", "focus", [])
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.remove_class("fade-in", to: "##{id}")
    |> JS.hide(
      to: "##{id}",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      transition:
        {"ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.dispatch("click", to: "##{id} [data-modal-return]")
  end

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :icon, :atom, default: :information_circle
  attr :patch, :string, default: nil
  attr :navigate, :string, default: nil
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}
  attr :rest, :global
  # slots
  slot(:title)

  slot :confirm do
    attr :patch, :string
    attr :size, :atom
    attr :form, :any
    attr :type, :string
    attr :variant, :atom
    attr :disabled, :boolean
  end

  slot :cancel do
    attr :patch, :string
    attr :size, :atom
    attr :type, :string
    attr :variant, :atom
    attr :disabled, :boolean
  end

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      class={"fixed z-20 inset-0 overflow-y-auto #{if @show, do: "fade-in", else: "hidden"}"}
      {@rest}
    >
      <.focus_wrap id={"#{@id}-focus-wrap"}>
        <div
          class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
          aria-labelledby={"#{@id}-title"}
          aria-describedby={"#{@id}-description"}
          role="dialog"
          aria-modal="true"
          tabindex="0"
        >
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true">
          </div>
          <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">
            &#8203;
          </span>
          <div
            id={"#{@id}-container"}
            class={
              "#{if @show, do: "fade-in-scale", else: "hidden"} sticky inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform sm:my-8 sm:align-middle sm:max-w-xl sm:w-full sm:p-6 max-h-screen lg:max-h-auto overflow-y-auto"
            }
            phx-key="escape"
          >
            <%= if @patch do %>
              <.link patch={@patch} data-modal-return class="hidden"></.link>
            <% end %>
            <%= if @navigate do %>
              <.link navigate={@navigate} data-modal-return class="hidden"></.link>
            <% end %>
            <div class="sm:flex sm:items-start">
              <%= if @icon do %>
                <div class="mx-auto flex-shrink-0 flex items-center justify-center h-8 w-8 rounded-full bg-purple-100 sm:mx-0">
                  <!-- Heroicon name: outline/plus -->
                  <.icon name={@icon || :information_circle} outlined class="h-6 w-6 text-purple-600" />
                </div>
              <% end %>

              <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full mr-4">
                <h3 class="text-lg leading-6 font-medium text-gray-900" id={"#{@id}-title"}>
                  <%= render_slot(@title) %>
                </h3>
                <div class="mt-6">
                  <div id={"#{@id}-content"} class="text-sm text-gray-500">
                    <%= render_slot(@inner_block) %>
                  </div>
                </div>
              </div>
            </div>
            <div class="sm:ml-4 mr-4 mt-8 flex flex-col sm:flex-row sm:flex-row-reverse space-y-2 sm:space-y-0 sm:space-x-2 sm:space-x-reverse">
              <%= for confirm <- @confirm do %>
                <.button
                  id={"#{@id}-confirm"}
                  phx-click={@on_confirm}
                  phx-disable-with
                  class="w-full sm:w-auto justify-center min-h-[44px]"
                  {Phoenix.Component.assigns_to_attributes(confirm)}
                >
                  <%= render_slot(confirm) %>
                </.button>
              <% end %>
              <%= for cancel <- @cancel do %>
                <.button
                  phx-click={hide_modal(@on_cancel, @id)}
                  class="w-full sm:w-auto justify-center min-h-[44px]"
                  {Phoenix.Component.assigns_to_attributes(cancel)}
                >
                  <%= render_slot(cancel) %>
                </.button>
              <% end %>
            </div>
          </div>
        </div>
      </.focus_wrap>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :min, :integer, default: 0
  attr :max, :integer, default: 100
  attr :value, :integer

  def progress_bar(assigns) do
    assigns = assign_new(assigns, :value, fn -> assigns[:min] || 0 end)

    ~H"""
    <div
      id={"#{@id}-container"}
      class="bg-gray-200 flex-auto dark:bg-black rounded-full overflow-hidden"
      phx-update="ignore"
    >
      <div
        id={@id}
        class="bg-lime-500 dark:bg-lime-400 h-1.5 w-0"
        data-min={@min}
        data-max={@max}
        data-val={@value}
      >
      </div>
    </div>
    """
  end

  attr :actions, :list, default: []

  def title_bar(assigns) do
    ~H"""
    <!-- Page title & actions -->
    <div class="border-b border-gray-200 px-4 py-4 sm:flex sm:items-center sm:justify-between sm:px-6 lg:px-8 sm:h-16">
      <div class="flex-1 min-w-0">
        <h1 class="text-lg font-medium leading-6 text-gray-900 sm:truncate focus:outline-none">
          <%= render_slot(@inner_block) %>
        </h1>
      </div>
      <%= if Enum.count(@actions) > 0 do %>
        <div class="mt-4 flex sm:mt-0 sm:ml-4 space-x-4">
          <%= render_slot(@actions) %>
        </div>
      <% end %>
    </div>
    """
  end

  def badge(assigns) do
    ~H"""
    <span class={"inline-flex items-center bg-#{@color}-100 text-#{@color}-800 text-xs font-semibold px-2.5 py-0.5 rounded dark:bg-#{@color}-200 dark:text-#{@color}-800"}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  attr :patch, :string
  attr :size, :atom, default: :base
  attr :type, :string, default: "button"
  attr :variant, :atom, default: nil
  attr :disabled, :boolean, default: false
  attr :rest, :global, include: ~w(form)
  slot(:inner_block, required: true)

  def button(%{patch: _} = assigns) do
    ~H"""
    <%= if @primary do %>
      <.link
        patch={@patch}
        class="order-0 inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 sm:order-1"
        {@rest}
      >
        <%= render_slot(@inner_block) %>
      </.link>
    <% else %>
      <.link
        patch={@patch}
        class="order-1 inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 sm:order-0"
        {Phoenix.Component.assigns_to_attributes(assigns, [:primary, :patch])}
      >
        <%= render_slot(@inner_block) %>
      </.link>
    <% end %>
    """
  end

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={"#{button_classes_base()} #{button_classes_color(@variant)} #{button_classes_size(@size)} #{if @disabled, do: "opacity-50 cursor-default hover:bg-inherit"}"}
      disabled={@disabled}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp button_classes_size(size) do
    case size do
      :base -> "text-sm px-4 py-1.5"
      :small -> "text-xs px-2 py-1"
      :narrow -> "text-sm px-1 py-1"
      _ -> "text-sm px-4 py-1.5"
    end
  end

  defp button_classes_color(variant) do
    case variant do
      :primary -> "border-primary-300 text-primary-700 bg-white hover:bg-primary-50"
      :secondary -> "bg-secondary-500 text-white hover:bg-secondary-600"
      :danger -> "border-primary-300 text-danger-600 bg-white hover:bg-primary-50"
      _ -> "border-primary-300 text-primary-700 bg-white hover:bg-primary-50"
    end
  end

  defp button_classes_base() do
    "font-medium inline-flex items-center border shadow-sm rounded-md focus:outline-none focus:ring-1 focus:ring-primary-500 focus:border-primary-500"
  end

  @doc """
  Mobile-friendly responsive list/table component.

  Renders as cards on mobile and table on desktop.

  ## Example

      <.card_list items={@bookings}>
        <:card :let={booking}>
          <div class="flex justify-between items-start">
            <div>
              <p class="font-medium text-gray-900"><%= booking.resource.name %></p>
              <p class="text-sm text-gray-500"><%= format_date(booking.start_at) %></p>
            </div>
            <.badge color="green">Active</.badge>
          </div>
        </:card>
        <:col :let={booking} label="Resource">
          <%= booking.resource.name %>
        </:col>
        <:col :let={booking} label="Date">
          <%= format_date(booking.start_at) %>
        </:col>
        <:col :let={booking} label="Status">
          <.badge color="green">Active</.badge>
        </:col>
      </.card_list>
  """
  attr :items, :list, required: true
  slot :card, required: true
  slot :col, required: true do
    attr :label, :string
  end

  def card_list(assigns) do
    ~H"""
    <!-- Mobile: Card view -->
    <div class="space-y-4 sm:hidden mt-4">
      <%= for item <- @items do %>
        <div class="bg-white rounded-lg shadow border border-gray-200 p-4 min-h-[44px]">
          <%= render_slot(@card, item) %>
        </div>
      <% end %>
    </div>

    <!-- Desktop: Table view -->
    <div class="hidden sm:block mt-8">
      <div class="align-middle inline-block min-w-full border-b border-gray-200">
        <table class="min-w-full divide-y divide-gray-200 border-t border-r border-l">
          <thead>
            <tr class="border-t border-gray-200">
              <%= for col <- @col do %>
                <th class="px-6 py-3 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  <%= col[:label] %>
                </th>
              <% end %>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-100">
            <%= for item <- @items do %>
              <tr class="hover:bg-gray-50">
                <%= for col <- @col do %>
                  <td class="px-6 py-3 text-sm text-gray-900">
                    <%= render_slot(col, item) %>
                  </td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  attr :id, :any
  attr :row_id, :any, default: false
  attr :rows, :list, required: true
  # slots
  slot(:inner_block, required: true)

  slot :col, required: true do
    attr :label, :string
    attr :width, :string
  end

  def table(assigns) do
    assigns =
      assigns
      |> assign_new(:row_id, fn -> false end)
      |> assign(:col, for(col <- assigns.col, col[:if] != false, do: col))

    ~H"""
    <div class="hidden mt-8 sm:block">
      <div class="align-middle inline-block min-w-full border-b border-gray-200">
        <table class="w-full table-fixed border-t border-r border-l">
          <thead>
            <tr class="border-t border-gray-200">
              <%= for col <- @col do %>
                <th class={"#{if Map.has_key?(col, :width), do: col.width} px-6 py-3 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"}>
                  <span class="lg:pl-2"><%= col.label %></span>
                </th>
              <% end %>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-100">
            <%= for {row, _i} <- Enum.with_index(@rows) do %>
              <tr id={@row_id && @row_id.(row)} class="hover:bg-gray-50">
                <%= for col <- @col do %>
                  <td class={
                    "px-6 py-3 text-sm font-medium text-gray-900 #{col[:class]}"
                  }>
                    <div class="flex items-center space-x-3 lg:pl-2">
                      <%= render_slot(col, row) %>
                    </div>
                  </td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  attr :id, :any, required: true
  attr :module, :atom, required: true
  attr :row_id, :any, default: false
  attr :rows, :list, required: true
  attr :rest, :global
  # slots
  slot(:inner_block, required: true)

  slot :col, required: true do
    attr :label, :string
    attr :width, :string
  end

  def live_table(assigns) do
    assigns = assign(assigns, :col, for(col <- assigns.col, col[:if] != false, do: col))

    ~H"""
    <div class="hidden mt-8 sm:block">
      <div class="align-middle inline-block min-w-full border-b border-gray-200">
        <table class="min-w-full border-t border-r border-l">
          <thead>
            <tr class="border-t border-gray-200">
              <%= for col <- @col do %>
                <th class="px-6 py-3 border-b border-gray-200 bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  <span class="lg:pl-2"><%= col.label %></span>
                </th>
              <% end %>
            </tr>
          </thead>
          <tbody id={@id} class="bg-white divide-y divide-gray-100">
            <%= for {row, i} <- Enum.with_index(@rows) do %>
              <.live_component
                module={@module}
                id={@row_id.(row)}
                row={row}
                col={@col}
                index={i}
                class="hover:bg-gray-50"
                {@rest}
              />
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  slot :link, required: true do
    attr :navigate, :string, required: true
    attr :active, :boolean, required: true
  end

  slot(:inner_block, required: true)

  def tabs(assigns) do
    ~H"""
    <div class="flex flex-row space-x-2">
      <%= for link <- @link do %>
        <.link
          tabindex="0"
          class={"#{if link[:active], do: "bg-gray-200 text-gray-700", else: "focus:outline-none focus:ring-1 focus:ring-primary-500 focus:border-primary-500 text-gray-500 hover:text-gray-700"} p-1 transition-colors block rounded text-sm font-medium focus:outline-none focus:ring-0 focus:ring-offset-0 focus:ring-offset-gray-100 focus:ring-purple-500"}
          {link}
        >
          &nbsp; <%= render_slot(link) %> &nbsp;
        </.link>
      <% end %>
    </div>
    """
  end

  attr :label, :string
  slot(:inner_block, required: true)

  def header(assigns) do
    ~H"""
    <div class="border-b bg-white sticky top-0 border-gray-200 px-4 pt-4 pb-1 sm:flex sm:items-center sm:justify-between sm:px-6 lg:px-8 mx-auto">
      <div class="min-w-0 sm:mr-6">
        <h1 tabindex="-1" class="text-3xl">
          <%= @label %>
        </h1>
      </div>
      <div class="w-full sm:flex-1 mt-2 sm:mt-0" style="display: block; width: 100%;">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr :full, :boolean, default: false
  slot(:inner_block, required: true)

  def page(assigns) do
    ~H"""
    <div class={"px-4 py-4 sm:px-6 lg:px-8 w-full #{if !@full, do: "mx-auto max-w-4xl"}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Calls a wired up event listener to call a function with arguments.
      window.addEventListener("js:exec", e => e.target[e.detail.call](...e.detail.args))
  """
  def js_exec(js \\ %JS{}, to, call, args) do
    JS.dispatch(js, "js:exec", to: to, detail: %{call: call, args: args})
  end

  def focus(js \\ %JS{}, parent, to) do
    JS.dispatch(js, "js:focus", to: to, detail: %{parent: parent})
  end

  def focus_closest(js \\ %JS{}, to) do
    js
    |> JS.dispatch("js:focus-closest", to: to)
    |> hide(to)
  end
end
