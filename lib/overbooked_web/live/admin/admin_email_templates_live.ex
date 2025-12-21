defmodule OverbookedWeb.AdminEmailTemplatesLive do
  use OverbookedWeb, :live_view

  alias Overbooked.Settings
  alias Overbooked.Settings.EmailTemplate
  alias Overbooked.EmailRenderer

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(templates: Settings.list_email_templates())
     |> assign(selected_template: nil)
     |> assign(changeset: nil)
     |> assign(preview_html: nil)
     |> assign(show_preview: false)
     |> assign(show_modal: false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header label="Admin">
      <.admin_tabs active_tab={@active_tab} socket={@socket} />
    </.header>

    <.page>
      <div class="w-full">
        <div class="sm:flex sm:items-center mb-6">
          <div class="sm:flex-auto">
            <h1 class="text-xl font-semibold text-gray-900">Email Templates</h1>
            <p class="mt-2 text-sm text-gray-700">
              Customize email templates sent to users. Use variables like <code class="bg-gray-100 px-1 rounded">{{user.name}}</code> to personalize content.
            </p>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          <%= for template <- @templates do %>
            <div class="bg-white shadow rounded-lg p-6">
              <div class="flex items-start justify-between">
                <h3 class="text-lg font-medium text-gray-900">
                  <%= EmailTemplate.humanize_type(template.template_type) %>
                </h3>
                <%= if template.is_custom do %>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                    Customized
                  </span>
                <% end %>
              </div>

              <p class="mt-2 text-sm text-gray-500">
                <%= EmailTemplate.description(template.template_type) %>
              </p>

              <p class="mt-3 text-sm text-gray-700">
                <span class="font-medium">Subject:</span> <%= template.subject %>
              </p>

              <div class="mt-4 flex flex-wrap gap-2">
                <.button phx-click="edit_template" phx-value-type={template.template_type} size={:small}>
                  Edit
                </.button>
                <.button phx-click="preview_template" phx-value-type={template.template_type} size={:small} variant={:secondary}>
                  Preview
                </.button>
                <%= if template.is_custom do %>
                  <.button
                    phx-click="reset_template"
                    phx-value-type={template.template_type}
                    size={:small}
                    variant={:danger}
                    data-confirm="Are you sure you want to reset this template to the default? Your customizations will be lost."
                  >
                    Reset
                  </.button>
                <% end %>
              </div>

              <div class="mt-4 pt-4 border-t border-gray-200">
                <p class="text-xs font-medium text-gray-700 mb-2">Available Variables:</p>
                <div class="flex flex-wrap gap-1">
                  <%= for var <- template.variables do %>
                    <code class="text-xs bg-gray-100 px-1.5 py-0.5 rounded">{{<%= var %>}}</code>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <!-- Edit Modal -->
        <%= if @show_modal and @selected_template do %>
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75 z-40" phx-click="close_modal"></div>
          <div class="fixed inset-0 z-50 overflow-y-auto">
            <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
              <div class="relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-4xl">
                <.form
                  :let={f}
                  for={@changeset}
                  phx-change="validate_template"
                  phx-submit="save_template"
                  class="divide-y divide-gray-200"
                >
                  <div class="px-6 py-4 bg-gray-50">
                    <h3 class="text-lg font-medium text-gray-900">
                      Edit <%= EmailTemplate.humanize_type(@selected_template.template_type) %>
                    </h3>
                  </div>

                  <div class="px-6 py-4 space-y-4 max-h-[60vh] overflow-y-auto">
                    <div>
                      <label for="subject" class="block text-sm font-medium text-gray-700">
                        Subject Line
                      </label>
                      <div class="mt-1">
                        <.text_input form={f} field={:subject} />
                        <.error form={f} field={:subject} />
                      </div>
                    </div>

                    <div>
                      <label for="html_body" class="block text-sm font-medium text-gray-700">
                        Email Content (HTML)
                      </label>
                      <p class="mt-1 text-xs text-gray-500">
                        Use <code class="bg-gray-100 px-1 rounded">{{variable}}</code> syntax for dynamic content.
                        Available: <%= Enum.map_join(@selected_template.variables, ", ", &("{{#{&1}}}")) %>
                      </p>
                      <div class="mt-2">
                        <textarea
                          id="email_template_html_body"
                          name="email_template[html_body]"
                          rows="15"
                          class="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm font-mono"
                        ><%= Phoenix.HTML.Form.input_value(f, :html_body) %></textarea>
                        <.error form={f} field={:html_body} />
                      </div>
                    </div>

                    <div>
                      <label for="text_body" class="block text-sm font-medium text-gray-700">
                        Plain Text Version
                      </label>
                      <div class="mt-1">
                        <textarea
                          id="email_template_text_body"
                          name="email_template[text_body]"
                          rows="8"
                          class="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm font-mono"
                        ><%= Phoenix.HTML.Form.input_value(f, :text_body) %></textarea>
                        <.error form={f} field={:text_body} />
                      </div>
                    </div>
                  </div>

                  <div class="px-6 py-4 bg-gray-50 flex justify-between items-center">
                    <.button type="button" phx-click="preview_current" variant={:secondary}>
                      Preview
                    </.button>
                    <div class="flex space-x-3">
                      <.button type="button" phx-click="close_modal" variant={:secondary}>
                        Cancel
                      </.button>
                      <.button type="submit" variant={:primary}>
                        Save Template
                      </.button>
                    </div>
                  </div>
                </.form>
              </div>
            </div>
          </div>
        <% end %>

        <!-- Preview Modal -->
        <%= if @show_preview and @preview_html do %>
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75 z-40" phx-click="close_preview"></div>
          <div class="fixed inset-0 z-50 overflow-y-auto">
            <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
              <div class="relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-3xl">
                <div class="px-6 py-4 bg-gray-50 flex justify-between items-center">
                  <h3 class="text-lg font-medium text-gray-900">Email Preview</h3>
                  <button type="button" phx-click="close_preview" class="text-gray-400 hover:text-gray-500">
                    <.icon name={:x} class="h-5 w-5" />
                  </button>
                </div>
                <div class="p-6 max-h-[70vh] overflow-y-auto">
                  <div class="bg-gray-100 p-4 rounded-lg">
                    <p class="text-sm text-gray-600 mb-2"><strong>Subject:</strong> <%= @preview_subject %></p>
                  </div>
                  <div class="mt-4 border border-gray-200 rounded-lg overflow-hidden">
                    <iframe
                      id="preview-frame"
                      srcdoc={@preview_html}
                      class="w-full"
                      style="min-height: 500px; border: none;"
                    ></iframe>
                  </div>
                  <p class="mt-3 text-xs text-gray-500 text-center">
                    Preview uses sample data for variables
                  </p>
                </div>
                <div class="px-6 py-4 bg-gray-50 flex justify-end">
                  <.button type="button" phx-click="close_preview" variant={:secondary}>
                    Close
                  </.button>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </.page>
    """
  end

  @impl true
  def handle_event("edit_template", %{"type" => type}, socket) do
    template = Settings.get_email_template(type)
    changeset = Settings.change_email_template(template)

    {:noreply,
     socket
     |> assign(selected_template: template)
     |> assign(changeset: changeset)
     |> assign(show_modal: true)}
  end

  def handle_event("validate_template", %{"email_template" => params}, socket) do
    changeset =
      socket.assigns.selected_template
      |> Settings.change_email_template(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save_template", %{"email_template" => params}, socket) do
    template = socket.assigns.selected_template

    case Settings.update_email_template(template.template_type, params) do
      {:ok, _template} ->
        {:noreply,
         socket
         |> put_flash(:info, "Template saved successfully.")
         |> assign(templates: Settings.list_email_templates())
         |> assign(show_modal: false)
         |> assign(selected_template: nil)
         |> assign(changeset: nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Please fix the errors below.")
         |> assign(changeset: changeset)}
    end
  end

  def handle_event("close_modal", _, socket) do
    {:noreply,
     socket
     |> assign(show_modal: false)
     |> assign(selected_template: nil)
     |> assign(changeset: nil)}
  end

  def handle_event("preview_template", %{"type" => type}, socket) do
    template = Settings.get_email_template(type)
    sample_data = EmailRenderer.sample_assigns(type)

    preview_subject = EmailRenderer.render(template.subject, sample_data)
    preview_html = render_full_email(template.html_body, sample_data)

    {:noreply,
     socket
     |> assign(show_preview: true)
     |> assign(preview_subject: preview_subject)
     |> assign(preview_html: preview_html)}
  end

  def handle_event("preview_current", _, socket) do
    template = socket.assigns.selected_template
    changeset = socket.assigns.changeset
    sample_data = EmailRenderer.sample_assigns(template.template_type)

    # Get the current form values from the changeset
    subject = Ecto.Changeset.get_field(changeset, :subject) || template.subject
    html_body = Ecto.Changeset.get_field(changeset, :html_body) || template.html_body

    preview_subject = EmailRenderer.render(subject, sample_data)
    preview_html = render_full_email(html_body, sample_data)

    {:noreply,
     socket
     |> assign(show_preview: true)
     |> assign(preview_subject: preview_subject)
     |> assign(preview_html: preview_html)}
  end

  def handle_event("close_preview", _, socket) do
    {:noreply,
     socket
     |> assign(show_preview: false)
     |> assign(preview_html: nil)}
  end

  def handle_event("reset_template", %{"type" => type}, socket) do
    case Settings.reset_email_template(type) do
      {:ok, _template} ->
        {:noreply,
         socket
         |> put_flash(:info, "Template reset to default.")
         |> assign(templates: Settings.list_email_templates())}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to reset template.")}
    end
  end

  # Renders the email content wrapped in the email layout
  defp render_full_email(content, assigns) do
    rendered_content = EmailRenderer.render(content, assigns)

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        body { font-family: 'Nunito Sans', Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f5; }
        .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; }
        a { color: #2153FF; }
      </style>
    </head>
    <body style="margin: 0; padding: 0; background-color: #f4f4f5;">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f5;">
        <tr>
          <td align="center" style="padding: 40px 20px;">
            <table role="presentation" width="600" cellpadding="0" cellspacing="0">
              <tr>
                <td align="center" style="padding-bottom: 32px;">
                  <img src="#{OverbookedWeb.Endpoint.url()}/images/hatchbridge-logo.svg" alt="Hatchbridge Rooms" width="180" style="height: auto;">
                </td>
              </tr>
              <tr>
                <td style="background-color: #ffffff; border-radius: 12px; padding: 40px;">
                  #{rendered_content}
                </td>
              </tr>
              <tr>
                <td align="center" style="padding-top: 32px;">
                  <p style="margin: 0; color: #6b7280; font-size: 12px;">
                    Hatchbridge Rooms<br>
                    <a href="#{OverbookedWeb.Endpoint.url()}" style="color: #6b7280;">Visit Dashboard</a>
                  </p>
                  <p style="margin: 16px 0 0; color: #9ca3af; font-size: 11px;">
                    &copy; #{Date.utc_today().year} Hatchbridge. All rights reserved.
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    """
  end
end
