defmodule OverbookedWeb.AdminSettingsLive do
  use OverbookedWeb, :live_view

  alias Overbooked.Settings
  alias Overbooked.Settings.MailSetting

  @impl true
  def mount(_params, _session, socket) do
    mail_setting = Settings.get_mail_setting_for_display()
    changeset = Settings.change_mail_setting(mail_setting)

    {:ok,
     socket
     |> assign(mail_setting: mail_setting)
     |> assign(changeset: changeset)
     |> assign(test_email_status: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header label="Admin">
      <.admin_tabs active_tab={@active_tab} socket={@socket} />
    </.header>

    <.page>
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
end
