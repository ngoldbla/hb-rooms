defmodule OverbookedWeb.AdminSettingsLive do
  use OverbookedWeb, :live_view

  alias Overbooked.Settings
  alias Overbooked.Settings.MailSetting
  alias Overbooked.Settings.StripeSetting
  alias Overbooked.Settings.ContractTerm

  @impl true
  def mount(_params, _session, socket) do
    mail_setting = Settings.get_mail_setting_for_display()
    mail_changeset = Settings.change_mail_setting(mail_setting)

    stripe_setting = Settings.get_stripe_setting_for_display()
    stripe_changeset = Settings.change_stripe_setting(stripe_setting)

    contract_terms = Settings.get_current_terms()
    terms_changeset = Settings.change_contract_terms(contract_terms)

    webhook_url = OverbookedWeb.Endpoint.url() <> "/webhooks/stripe"

    {:ok,
     socket
     |> assign(mail_setting: mail_setting)
     |> assign(changeset: mail_changeset)
     |> assign(test_email_status: nil)
     |> assign(stripe_setting: stripe_setting)
     |> assign(stripe_changeset: stripe_changeset)
     |> assign(stripe_test_status: nil)
     |> assign(webhook_url: webhook_url)
     |> assign(contract_terms: contract_terms)
     |> assign(terms_changeset: terms_changeset)
     |> assign(terms_preview: false)}
  end

  @impl true
  def render(assigns) do
    # Section tabs for Settings group (Settings, Email Templates)
    assigns = assign(assigns, :settings_tabs, [
      %{id: :admin_settings, label: "Settings", path: Routes.admin_settings_path(assigns.socket, :index)},
      %{id: :admin_email_templates, label: "Email Templates", path: Routes.admin_email_templates_path(assigns.socket, :index)}
    ])

    ~H"""
    <.header label="Admin">
      <.admin_tabs active_tab={@active_tab} socket={@socket} />
    </.header>

    <.page>
      <.section_tabs active_tab={@active_tab} socket={@socket} tabs={@settings_tabs} />

      <div class="w-full space-y-8">
        <div class="bg-white shadow rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg font-medium leading-6 text-gray-900">
              Email Settings
            </h3>
            <p class="mt-1 text-sm text-gray-500">
              Configure Mailgun to send transactional emails (invitations, password resets, etc.)
            </p>

            <.form
              :let={f}
              for={@changeset}
              phx-change="validate"
              phx-submit="save"
              id="mail-settings-form"
              class="mt-6 space-y-6"
            >
              <div class="flex items-center">
                <.switch form={f} field={:enabled} />
                <label for="enabled" class="ml-3 text-sm font-medium text-gray-700">
                  Enable email sending
                </label>
              </div>

              <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
                <div>
                  <label for="mailgun_api_key" class="block text-sm font-medium text-gray-700">
                    Mailgun API Key
                  </label>
                  <div class="mt-1">
                    <.text_input
                      form={f}
                      field={:mailgun_api_key}
                      type="password"
                      placeholder="key-xxxxxxxxxxxxxxxxxxxxxxxx"
                      autocomplete="off"
                    />
                    <.error form={f} field={:mailgun_api_key} />
                  </div>
                  <p class="mt-1 text-xs text-gray-500">
                    Find this in your Mailgun dashboard under API Keys
                  </p>
                </div>

                <div>
                  <label for="mailgun_domain" class="block text-sm font-medium text-gray-700">
                    Mailgun Domain
                  </label>
                  <div class="mt-1">
                    <.text_input
                      form={f}
                      field={:mailgun_domain}
                      placeholder="mg.yourdomain.com"
                    />
                    <.error form={f} field={:mailgun_domain} />
                  </div>
                  <p class="mt-1 text-xs text-gray-500">
                    Your verified sending domain in Mailgun
                  </p>
                </div>

                <div>
                  <label for="from_name" class="block text-sm font-medium text-gray-700">
                    From Name
                  </label>
                  <div class="mt-1">
                    <.text_input
                      form={f}
                      field={:from_name}
                      placeholder="Hatchbridge Rooms"
                    />
                    <.error form={f} field={:from_name} />
                  </div>
                </div>

                <div>
                  <label for="from_email" class="block text-sm font-medium text-gray-700">
                    From Email
                  </label>
                  <div class="mt-1">
                    <.text_input
                      form={f}
                      field={:from_email}
                      type="email"
                      placeholder="noreply@yourdomain.com"
                    />
                    <.error form={f} field={:from_email} />
                  </div>
                  <p class="mt-1 text-xs text-gray-500">
                    Must be from your verified Mailgun domain
                  </p>
                </div>
              </div>

              <div class="flex items-center justify-between pt-4 border-t border-gray-200">
                <div class="flex items-center space-x-4">
                  <.button type="submit" variant={:secondary}>
                    Save Settings
                  </.button>

                  <%= if @mail_setting.enabled do %>
                    <.button type="button" phx-click="send_test_email">
                      Send Test Email
                    </.button>
                  <% end %>
                </div>

                <%= if @test_email_status do %>
                  <span class={"text-sm #{if @test_email_status == :success, do: "text-green-600", else: "text-red-600"}"}>
                    <%= if @test_email_status == :success do %>
                      ✓ Test email sent successfully!
                    <% else %>
                      ✗ Failed to send test email
                    <% end %>
                  </span>
                <% end %>
              </div>
            </.form>
          </div>
        </div>

        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <.icon name={:information_circle} class="h-5 w-5 text-blue-400" />
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-blue-800">
                Setting up Mailgun
              </h3>
              <div class="mt-2 text-sm text-blue-700">
                <ol class="list-decimal list-inside space-y-1">
                  <li>Create a Mailgun account at <a href="https://www.mailgun.com" target="_blank" class="underline">mailgun.com</a></li>
                  <li>Add and verify your sending domain</li>
                  <li>Copy your API key from Settings → API Keys</li>
                  <li>Enter your credentials above and enable email sending</li>
                </ol>
              </div>
            </div>
          </div>
        </div>

        <!-- Stripe Settings Section -->
        <div class="bg-white shadow rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg font-medium leading-6 text-gray-900">
              Stripe Settings
            </h3>
            <p class="mt-1 text-sm text-gray-500">
              Configure Stripe for accepting payments on office space contracts.
            </p>

            <.form
              :let={f}
              for={@stripe_changeset}
              phx-change="validate_stripe"
              phx-submit="save_stripe"
              id="stripe-settings-form"
              class="mt-6 space-y-6"
            >
              <div class="flex items-center">
                <.switch form={f} field={:enabled} />
                <label for="stripe_setting_enabled" class="ml-3 text-sm font-medium text-gray-700">
                  Enable Stripe payments
                </label>
              </div>

              <div>
                <label for="stripe_setting_environment" class="block text-sm font-medium text-gray-700">
                  Environment
                </label>
                <div class="mt-1">
                  <select
                    name="stripe_setting[environment]"
                    id="stripe_setting_environment"
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm"
                  >
                    <option value="test" selected={Phoenix.HTML.Form.input_value(f, :environment) == "test"}>Test Mode</option>
                    <option value="live" selected={Phoenix.HTML.Form.input_value(f, :environment) == "live"}>Live Mode</option>
                  </select>
                </div>
                <p class="mt-1 text-xs text-gray-500">
                  Use Test Mode during development, Live Mode for production
                </p>
              </div>

              <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
                <div>
                  <label for="stripe_setting_secret_key" class="block text-sm font-medium text-gray-700">
                    Secret Key
                  </label>
                  <div class="mt-1">
                    <.text_input
                      form={f}
                      field={:secret_key}
                      type="password"
                      placeholder="sk_test_..."
                      autocomplete="off"
                    />
                    <.error form={f} field={:secret_key} />
                  </div>
                  <p class="mt-1 text-xs text-gray-500">
                    Starts with sk_test_ or sk_live_
                  </p>
                </div>

                <div>
                  <label for="stripe_setting_publishable_key" class="block text-sm font-medium text-gray-700">
                    Publishable Key
                  </label>
                  <div class="mt-1">
                    <.text_input
                      form={f}
                      field={:publishable_key}
                      placeholder="pk_test_..."
                    />
                    <.error form={f} field={:publishable_key} />
                  </div>
                  <p class="mt-1 text-xs text-gray-500">
                    Starts with pk_test_ or pk_live_
                  </p>
                </div>

                <div class="sm:col-span-2">
                  <label for="stripe_setting_webhook_secret" class="block text-sm font-medium text-gray-700">
                    Webhook Secret
                  </label>
                  <div class="mt-1">
                    <.text_input
                      form={f}
                      field={:webhook_secret}
                      type="password"
                      placeholder="whsec_..."
                      autocomplete="off"
                    />
                    <.error form={f} field={:webhook_secret} />
                  </div>
                  <p class="mt-1 text-xs text-gray-500">
                    Found in Stripe Dashboard → Developers → Webhooks
                  </p>
                </div>
              </div>

              <div class="flex items-center justify-between pt-4 border-t border-gray-200">
                <div class="flex items-center space-x-4">
                  <.button type="submit" variant={:secondary}>
                    Save Settings
                  </.button>

                  <.button type="button" phx-click="test_stripe_connection">
                    Test Connection
                  </.button>
                </div>

                <%= if @stripe_test_status do %>
                  <span class={"text-sm #{if @stripe_test_status == :success, do: "text-green-600", else: "text-red-600"}"}>
                    <%= if @stripe_test_status == :success do %>
                      ✓ Connected successfully!
                    <% else %>
                      ✗ Connection failed
                    <% end %>
                  </span>
                <% end %>
              </div>
            </.form>

            <!-- Webhook URL Info -->
            <div class="mt-6 bg-gray-50 p-4 rounded-lg">
              <p class="text-sm font-medium text-gray-700">Webhook Endpoint URL</p>
              <div class="mt-1 flex items-center space-x-2">
                <code class="text-sm text-gray-600 break-all bg-white px-2 py-1 rounded border"><%= @webhook_url %></code>
              </div>
              <p class="mt-2 text-xs text-gray-500">
                Add this URL in Stripe Dashboard → Developers → Webhooks.<br/>
                Subscribe to events: <code class="bg-gray-100 px-1 rounded">checkout.session.completed</code>
              </p>
            </div>
          </div>
        </div>

        <div class="bg-purple-50 border border-purple-200 rounded-lg p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <.icon name={:information_circle} class="h-5 w-5 text-purple-400" />
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-purple-800">
                Setting up Stripe
              </h3>
              <div class="mt-2 text-sm text-purple-700">
                <ol class="list-decimal list-inside space-y-1">
                  <li>Create a Stripe account at <a href="https://stripe.com" target="_blank" class="underline">stripe.com</a></li>
                  <li>Go to Developers → API Keys to get your keys</li>
                  <li>Add your webhook endpoint in Developers → Webhooks</li>
                  <li>Enter your credentials above and enable Stripe payments</li>
                </ol>
              </div>
            </div>
          </div>
        </div>

        <!-- Contract Terms Section -->
        <div class="bg-white shadow rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="text-lg font-medium leading-6 text-gray-900">
                  Contract Terms
                </h3>
                <p class="mt-1 text-sm text-gray-500">
                  Customize the terms and conditions shown during checkout. Users must accept these before proceeding.
                </p>
              </div>
              <div class="flex items-center space-x-2">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                  Version <%= @contract_terms.version %>
                </span>
                <%= if @contract_terms.effective_date do %>
                  <span class="text-xs text-gray-500">
                    Effective: <%= @contract_terms.effective_date %>
                  </span>
                <% end %>
              </div>
            </div>

            <.form
              :let={f}
              for={@terms_changeset}
              phx-change="validate_terms"
              phx-submit="save_terms"
              id="contract-terms-form"
              class="mt-6 space-y-6"
            >
              <div>
                <label for="contract_term_content" class="block text-sm font-medium text-gray-700">
                  Terms Content (HTML)
                </label>
                <p class="mt-1 text-xs text-gray-500">
                  Use HTML formatting. Saving changes will create a new version.
                </p>
                <div class="mt-2">
                  <textarea
                    id="contract_term_content"
                    name="contract_term[content]"
                    rows="12"
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm font-mono"
                  ><%= Phoenix.HTML.Form.input_value(f, :content) %></textarea>
                  <.error form={f} field={:content} />
                </div>
              </div>

              <div class="flex items-center justify-between pt-4 border-t border-gray-200">
                <div class="flex items-center space-x-4">
                  <.button type="submit" variant={:secondary}>
                    Save Terms
                  </.button>
                  <.button type="button" phx-click="preview_terms" variant={:secondary}>
                    Preview
                  </.button>
                  <.button
                    type="button"
                    phx-click="reset_terms"
                    variant={:danger}
                    data-confirm="Are you sure you want to reset to default terms? This will create a new version."
                  >
                    Reset to Default
                  </.button>
                </div>
              </div>
            </.form>
          </div>
        </div>

        <!-- Terms Preview Modal -->
        <%= if @terms_preview do %>
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75 z-40" phx-click="close_terms_preview"></div>
          <div class="fixed inset-0 z-50 overflow-y-auto">
            <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
              <div class="relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-2xl">
                <div class="px-6 py-4 bg-gray-50 flex justify-between items-center">
                  <h3 class="text-lg font-medium text-gray-900">Contract Terms Preview</h3>
                  <button type="button" phx-click="close_terms_preview" class="text-gray-400 hover:text-gray-500">
                    <.icon name={:x} class="h-5 w-5" />
                  </button>
                </div>
                <div class="p-6 max-h-[70vh] overflow-y-auto">
                  <div class="prose prose-sm max-w-none">
                    <%= Phoenix.HTML.raw(@terms_preview_content) %>
                  </div>
                </div>
                <div class="px-6 py-4 bg-gray-50 flex justify-end">
                  <.button type="button" phx-click="close_terms_preview" variant={:secondary}>
                    Close
                  </.button>
                </div>
              </div>
            </div>
          </div>
        <% end %>

        <div class="bg-green-50 border border-green-200 rounded-lg p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <.icon name={:information_circle} class="h-5 w-5 text-green-400" />
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-green-800">
                Contract Terms Versioning
              </h3>
              <div class="mt-2 text-sm text-green-700">
                <ul class="list-disc list-inside space-y-1">
                  <li>Each content change automatically creates a new version</li>
                  <li>Users must accept terms during checkout</li>
                  <li>Contracts store the accepted terms version for compliance</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </.page>
    """
  end

  @impl true
  def handle_event("validate", %{"mail_setting" => params}, socket) do
    changeset =
      socket.assigns.mail_setting
      |> Settings.change_mail_setting(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"mail_setting" => params}, socket) do
    case Settings.update_mail_setting(params) do
      {:ok, mail_setting} ->
        {:noreply,
         socket
         |> put_flash(:info, "Email settings saved successfully.")
         |> assign(mail_setting: Settings.get_mail_setting_for_display())
         |> assign(changeset: Settings.change_mail_setting(mail_setting))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Please fix the errors below.")
         |> assign(changeset: changeset)}
    end
  end

  def handle_event("send_test_email", _params, socket) do
    current_user = socket.assigns.current_user

    case Settings.send_test_email(current_user.email) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(test_email_status: :success)
         |> put_flash(:info, "Test email sent to #{current_user.email}")}

      {:error, :mail_not_enabled} ->
        {:noreply,
         socket
         |> assign(test_email_status: :error)
         |> put_flash(:error, "Email sending is not enabled. Please enable it first.")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(test_email_status: :error)
         |> put_flash(:error, "Failed to send test email: #{inspect(reason)}")}
    end
  end

  # Stripe event handlers

  def handle_event("validate_stripe", %{"stripe_setting" => params}, socket) do
    changeset =
      socket.assigns.stripe_setting
      |> Settings.change_stripe_setting(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, stripe_changeset: changeset)}
  end

  def handle_event("save_stripe", %{"stripe_setting" => params}, socket) do
    case Settings.update_stripe_setting(params) do
      {:ok, stripe_setting} ->
        {:noreply,
         socket
         |> put_flash(:info, "Stripe settings saved successfully.")
         |> assign(stripe_setting: Settings.get_stripe_setting_for_display())
         |> assign(stripe_changeset: Settings.change_stripe_setting(stripe_setting))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Please fix the errors below.")
         |> assign(stripe_changeset: changeset)}
    end
  end

  def handle_event("test_stripe_connection", _params, socket) do
    case Settings.test_stripe_connection() do
      {:ok, :connected} ->
        {:noreply,
         socket
         |> assign(stripe_test_status: :success)
         |> put_flash(:info, "Successfully connected to Stripe!")}

      {:error, message} ->
        {:noreply,
         socket
         |> assign(stripe_test_status: :error)
         |> put_flash(:error, "Stripe connection failed: #{message}")}
    end
  end

  # Contract terms event handlers

  def handle_event("validate_terms", %{"contract_term" => params}, socket) do
    changeset =
      socket.assigns.contract_terms
      |> Settings.change_contract_terms(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, terms_changeset: changeset)}
  end

  def handle_event("save_terms", %{"contract_term" => params}, socket) do
    case Settings.update_terms(params) do
      {:ok, terms} ->
        {:noreply,
         socket
         |> put_flash(:info, "Contract terms saved. New version: #{terms.version}")
         |> assign(contract_terms: terms)
         |> assign(terms_changeset: Settings.change_contract_terms(terms))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Please fix the errors below.")
         |> assign(terms_changeset: changeset)}
    end
  end

  def handle_event("preview_terms", _params, socket) do
    changeset = socket.assigns.terms_changeset
    content = Ecto.Changeset.get_field(changeset, :content) || socket.assigns.contract_terms.content

    {:noreply,
     socket
     |> assign(terms_preview: true)
     |> assign(terms_preview_content: content)}
  end

  def handle_event("close_terms_preview", _params, socket) do
    {:noreply,
     socket
     |> assign(terms_preview: false)
     |> assign(terms_preview_content: nil)}
  end

  def handle_event("reset_terms", _params, socket) do
    case Settings.reset_terms_to_default() do
      {:ok, terms} ->
        {:noreply,
         socket
         |> put_flash(:info, "Contract terms reset to default. New version: #{terms.version}")
         |> assign(contract_terms: terms)
         |> assign(terms_changeset: Settings.change_contract_terms(terms))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reset terms.")}
    end
  end
end
