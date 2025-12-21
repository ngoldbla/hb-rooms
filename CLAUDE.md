# Hatchbridge Rooms - Agent Implementation Guide

## Project Overview

**Stack:** Phoenix 1.7 + LiveView + Tailwind CSS + PostgreSQL + Swoosh (Mailgun) + Stripe
**Purpose:** Self-hosted coworking space management platform
**Goal:** Transform into world-class visitor management system (Envoy-like experience)

## Current State Summary

| Area | Status | Key Files |
|------|--------|-----------|
| Mobile Layout | ✅ Complete | `lib/overbooked_web/templates/layout/live.html.heex` |
| Email System | ✅ Complete | `lib/overbooked/accounts/user_notifier.ex`, `templates/email/` |
| Mailgun Admin | ✅ Complete | `lib/overbooked_web/live/admin/admin_settings_live.ex` |
| Spaces Browsing | ✅ Complete | `lib/overbooked_web/live/spaces_live.ex` |
| Stripe Checkout | ✅ Complete | `lib/overbooked/stripe.ex`, `stripe_webhook_controller.ex` |
| Contracts (User) | ✅ Complete | `lib/overbooked_web/live/contracts_live.ex`, `contracts.ex` |
| Stripe Admin Settings | ✅ Complete | `lib/overbooked/settings/stripe_setting.ex`, `admin_settings_live.ex` |
| Admin Spaces | ✅ Fixed | `lib/overbooked_web/live/admin/admin_spaces_live.ex`, `resources.ex` |
| Admin Contracts | ✅ Complete | `lib/overbooked_web/live/admin/admin_contracts_live.ex` |
| Nav Integration | ✅ Fixed | `lib/overbooked_web/live/nav.ex`, `templates/layout/live.html.heex` |
| Contract Emails | ✅ Complete | `templates/email/contract_confirmation.html.heex`, `contract_cancelled.html.heex` |
| Stripe Customer Portal | ✅ Complete | `lib/overbooked/stripe.ex`, `billing_controller.ex`, `contracts_live.ex` |
| Refund Handling | ✅ Complete | `stripe.ex`, `contracts.ex`, `stripe_webhook_controller.ex`, `admin_contracts_live.ex` |
| Email Template Editor | 📋 Planned | `lib/overbooked/settings/email_template.ex`, `admin_email_templates_live.ex` |
| Contract Terms Editor | 📋 Planned | `lib/overbooked/settings/contract_term.ex`, `admin_settings_live.ex` |

## Brand Assets

- **Logo SVG:** `priv/static/images/hatchbridge-logo.svg`
- **Logo PNG:** `priv/static/images/logo.png`
- **Primary Yellow:** `#FFC421`
- **Secondary Blue:** `#2153FF`
- **Dark Blue:** `#000824`
- **Font:** Nunito Sans

---

# Phase 1: Mobile Layout + Email Foundation ✅ COMPLETED

All Phase 1 tasks have been implemented and merged:
- ✅ 1.1 Mobile Sidebar (Hamburger Menu)
- ✅ 1.2 Mobile-Friendly Components
- ✅ 1.3 HTML Email Templates

---

# Phase 2: Spaces + Stripe Integration

## Current Implementation Status

### What's Already Working
- **Spaces Browsing** (`/spaces`): Grid of rentable spaces with pricing, amenities, descriptions
- **Checkout Modal**: Duration selection (1 or 3 months), 10% discount for 3-month contracts
- **Stripe Checkout**: Redirects to Stripe hosted checkout page
- **Webhook Processing**: `checkout.session.completed` activates contract + blocks calendar
- **Contracts View** (`/contracts`): Users can view and cancel their contracts
- **Success Page** (`/contracts/success`): Post-payment confirmation

### Key Files Reference
```
lib/overbooked/
├── stripe.ex                    # Stripe checkout session creation
├── contracts.ex                 # Contract business logic
├── contracts/contract.ex        # Contract schema (Stripe fields)
├── settings.ex                  # Settings context (Mailgun pattern)
├── settings/mail_setting.ex     # Mailgun config schema
lib/overbooked_web/
├── live/
│   ├── spaces_live.ex           # Browse & book spaces
│   ├── contracts_live.ex        # View user contracts
│   ├── contract_success_live.ex # Success page
│   └── admin/
│       └── admin_settings_live.ex  # Mailgun settings UI
├── controllers/
│   └── stripe_webhook_controller.ex
config/
├── runtime.exs                  # STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET env vars
```

---

## 2.1 Stripe Admin Settings ✅ COMPLETED

DB-backed Stripe configuration matching the Mailgun pattern.

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 2.1.1 | Create `stripe_settings` migration | `priv/repo/migrations/` | Table with singleton index |
| 2.1.2 | Create `StripeSetting` schema | `lib/overbooked/settings/stripe_setting.ex` | Fields: secret_key, webhook_secret, enabled |
| 2.1.3 | Add Stripe functions to Settings context | `lib/overbooked/settings.ex` | get_stripe_setting, update_stripe_setting |
| 2.1.4 | Update AdminSettingsLive with Stripe section | `admin_settings_live.ex` | Stripe config form below Mailgun |
| 2.1.5 | Update Stripe module to use DB config | `lib/overbooked/stripe.ex` | Reads from Settings, falls back to env |
| 2.1.6 | Update webhook controller for DB secret | `stripe_webhook_controller.ex` | Uses Settings.get_stripe_config() |
| 2.1.7 | Add Stripe connection test button | `admin_settings_live.ex` | Tests API key validity |

### Schema Pattern

```elixir
# lib/overbooked/settings/stripe_setting.ex
defmodule Overbooked.Settings.StripeSetting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stripe_settings" do
    field :enabled, :boolean, default: false
    field :secret_key, :string           # Base64 encoded for storage
    field :publishable_key, :string      # Public key (no encoding needed)
    field :webhook_secret, :string       # Base64 encoded
    field :environment, :string, default: "test"  # "test" or "live"

    timestamps()
  end

  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:enabled, :secret_key, :publishable_key, :webhook_secret, :environment])
    |> validate_required_when_enabled()
    |> encode_secrets()
  end

  defp validate_required_when_enabled(changeset) do
    if get_field(changeset, :enabled) do
      changeset
      |> validate_required([:secret_key, :webhook_secret])
      |> validate_format(:secret_key, ~r/^sk_(test|live)_/, message: "must be a valid Stripe secret key")
    else
      changeset
    end
  end

  defp encode_secrets(changeset) do
    changeset
    |> maybe_encode_field(:secret_key)
    |> maybe_encode_field(:webhook_secret)
  end
end
```

### Settings Context Functions

```elixir
# Add to lib/overbooked/settings.ex

def get_stripe_setting do
  case Repo.one(from s in StripeSetting, limit: 1) do
    nil -> %StripeSetting{}
    setting -> setting
  end
end

def get_stripe_setting_for_display do
  setting = get_stripe_setting()
  %{setting |
    secret_key: mask_key(setting.secret_key),
    webhook_secret: mask_key(setting.webhook_secret)
  }
end

def update_stripe_setting(attrs) do
  get_stripe_setting()
  |> StripeSetting.changeset(filter_masked_keys(attrs))
  |> Repo.insert_or_update()
end

def get_stripe_config do
  setting = get_stripe_setting()

  if setting.enabled and setting.secret_key do
    %{
      secret_key: decode_key(setting.secret_key),
      webhook_secret: decode_key(setting.webhook_secret),
      environment: setting.environment
    }
  else
    # Fallback to environment variables
    %{
      secret_key: Application.get_env(:stripity_stripe, :api_key),
      webhook_secret: Application.get_env(:overbooked, :stripe_webhook_secret),
      environment: "env"
    }
  end
end

def test_stripe_connection do
  config = get_stripe_config()

  case Stripe.Balance.retrieve(api_key: config.secret_key) do
    {:ok, _balance} -> {:ok, :connected}
    {:error, %Stripe.Error{message: msg}} -> {:error, msg}
  end
end
```

### Admin UI Addition

```html
<!-- Add to admin_settings_live.ex after Mailgun section -->
<div class="bg-white shadow rounded-lg mt-8">
  <div class="px-4 py-5 sm:p-6">
    <h3 class="text-lg font-medium leading-6 text-gray-900">
      Stripe Settings
    </h3>
    <p class="mt-1 text-sm text-gray-500">
      Configure Stripe for accepting payments on office space contracts.
    </p>

    <.form for={@stripe_changeset} phx-change="validate_stripe" phx-submit="save_stripe">
      <!-- Enable toggle -->
      <div class="flex items-center mt-6">
        <.switch form={f} field={:enabled} />
        <label class="ml-3 text-sm font-medium text-gray-700">
          Enable Stripe payments
        </label>
      </div>

      <!-- Environment selector -->
      <div class="mt-4">
        <label class="block text-sm font-medium text-gray-700">Environment</label>
        <select name="stripe_setting[environment]" class="mt-1 block w-full rounded-md border-gray-300">
          <option value="test">Test Mode</option>
          <option value="live">Live Mode</option>
        </select>
      </div>

      <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 mt-6">
        <!-- Secret Key -->
        <div>
          <label class="block text-sm font-medium text-gray-700">Secret Key</label>
          <.text_input form={f} field={:secret_key} type="password"
            placeholder="sk_test_..." autocomplete="off" />
          <p class="mt-1 text-xs text-gray-500">Starts with sk_test_ or sk_live_</p>
        </div>

        <!-- Publishable Key -->
        <div>
          <label class="block text-sm font-medium text-gray-700">Publishable Key</label>
          <.text_input form={f} field={:publishable_key}
            placeholder="pk_test_..." />
          <p class="mt-1 text-xs text-gray-500">Starts with pk_test_ or pk_live_</p>
        </div>

        <!-- Webhook Secret -->
        <div class="sm:col-span-2">
          <label class="block text-sm font-medium text-gray-700">Webhook Secret</label>
          <.text_input form={f} field={:webhook_secret} type="password"
            placeholder="whsec_..." autocomplete="off" />
        </div>
      </div>

      <div class="flex items-center justify-between pt-4 mt-4 border-t">
        <div class="flex items-center space-x-4">
          <.button type="submit" variant={:secondary}>Save Settings</.button>
          <%= if @stripe_setting.enabled do %>
            <.button type="button" phx-click="test_stripe_connection">
              Test Connection
            </.button>
          <% end %>
        </div>
      </div>
    </.form>

    <!-- Webhook URL Info -->
    <div class="mt-6 bg-gray-50 p-4 rounded-lg">
      <p class="text-sm font-medium text-gray-700">Webhook Endpoint URL</p>
      <code class="text-sm text-gray-600 break-all"><%= @webhook_url %></code>
      <p class="mt-2 text-xs text-gray-500">
        Add this URL in Stripe Dashboard → Developers → Webhooks.<br/>
        Subscribe to: <code>checkout.session.completed</code>, <code>payment_intent.succeeded</code>, <code>charge.refunded</code>
      </p>
    </div>
  </div>
</div>
```

---

## 2.2 Admin Spaces Management ✅ COMPLETED

Admins can create/edit/delete rentable spaces with pricing.

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 2.2.1 | Create AdminSpacesLive | `lib/overbooked_web/live/admin/admin_spaces_live.ex` | Lists all spaces |
| 2.2.2 | Add space CRUD to Resources context | `lib/overbooked/resources.ex` | create_space, update_space |
| 2.2.3 | Add space form modal | `admin_spaces_live.ex` | Create/edit with pricing |
| 2.2.4 | Add admin route | `router.ex` | `/admin/spaces` |
| 2.2.5 | Add Spaces tab to admin nav | `live_helpers.ex` | Tab in admin_tabs |
| 2.2.6 | Show availability status | `admin_spaces_live.ex` | Indicate if has active contract |

### Space Form Fields
- Name (text, required)
- Resource Type (select from existing types)
- Color (color picker)
- Monthly Rate (currency input → stored as cents)
- Description (textarea)
- Amenities (multi-select from existing amenities)
- Is Rentable (toggle)

---

## 2.3 Admin Contracts Management ✅ COMPLETED

View and manage all contracts across all users.

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 2.3.1 | Create AdminContractsLive | `admin/admin_contracts_live.ex` | Lists all contracts |
| 2.3.2 | Add admin contract functions | `contracts.ex` | list_all_contracts |
| 2.3.3 | Add status filtering | `admin_contracts_live.ex` | Filter by active/cancelled/expired |
| 2.3.4 | Add contract detail modal | `admin_contracts_live.ex` | View details + Stripe links |
| 2.3.5 | Add route | `router.ex` | `/admin/contracts` |
| 2.3.6 | Add to admin nav | `live_helpers.ex` | Contracts tab |

### Admin Contract Features
- View all contracts with user info
- Filter by status (active, pending, cancelled, expired)
- Filter by date range
- Link to Stripe dashboard for payment details
- Admin cancel option

---

## 2.4 Contract Email Templates ✅ COMPLETED

Transactional emails for contract lifecycle events.

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 2.4.1 | Create contract_confirmation.html.heex | `templates/email/` | Branded confirmation |
| 2.4.2 | Create contract_confirmation.text.heex | `templates/email/` | Plain text version |
| 2.4.3 | Add deliver_contract_confirmation | `user_notifier.ex` | Sends after activation |
| 2.4.4 | Call notifier from webhook | `stripe_webhook_controller.ex` | Send on checkout complete |
| 2.4.5 | Create contract_cancelled.html.heex | `templates/email/` | Cancellation email |

### Email Content - Contract Confirmation
- Space name and description
- Contract dates (start - end)
- Duration and total paid
- Receipt link (Stripe hosted)
- Support contact info

---

## 2.5 Stripe Customer Portal ✅ COMPLETED

Allow users to manage billing through Stripe.

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 2.5.1 | Add create_portal_session | `stripe.ex` | Creates portal session |
| 2.5.2 | Add billing route | `router.ex` | `/billing` redirects to Stripe |
| 2.5.3 | Add portal link to contracts page | `contracts_live.ex` | "Manage Billing" button |

### Implementation Details
- `create_portal_session/2` in `lib/overbooked/stripe.ex` creates Stripe Billing Portal sessions
- `BillingController` in `lib/overbooked_web/controllers/billing_controller.ex` handles the redirect
- Route added at `GET /billing` requiring authentication
- "Manage Billing" button shown on `/contracts` page when user has stripe_customer_id

---

## 2.6 Refund Handling ✅ COMPLETED

Handle refunds for cancelled contracts.

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 2.6.1 | Add create_refund function | `stripe.ex` | Initiates Stripe refund |
| 2.6.2 | Add refund fields to contract | Migration + schema | refund_amount_cents, refund_id, refunded_at |
| 2.6.3 | Handle charge.refunded webhook | `stripe_webhook_controller.ex` | Update contract |
| 2.6.4 | Add refund button for admin | `admin_contracts_live.ex` | Admin initiates refund |
| 2.6.5 | Create refund email templates | `templates/email/` | Refund notification emails |

### Implementation Details
- Migration `20251221100000_add_refund_fields_to_contracts.exs` adds refund fields
- `Contract` schema updated with `refund_amount_cents`, `refund_id`, `refunded_at` fields
- `create_refund/3` and `get_payment_intent/1` added to `stripe.ex`
- `initiate_refund/2`, `record_refund/2`, `record_refund_by_payment_intent/2` added to `contracts.ex`
- `charge.refunded` webhook handler records refunds from Stripe
- Automatic refund initiated when `resource_busy` on checkout completion
- "Refund" button in admin contracts page with confirmation modal
- Contract details modal shows refund information
- Email templates: `refund_notification.html.heex`, `refund_notification.text.heex`
- `deliver_refund_notification/2` in `user_notifier.ex`

---

# Phase 3: Email Templates + Contract Terms

## Overview

**Goal:** Enable admin customization of email content and contract terms without code changes.

**Key Features:**
- Rich text editor for email template customization
- Variable substitution system (@user.name, @contract.resource.name, etc.)
- Preview pane with sample data
- Reset to default functionality
- Contract terms acceptance flow with DB-backed terms storage

---

## 3.1 Email Template Editor

Admin UI to customize all 6 email types with rich text editing, variable preview, and reset to default.

### Current Email Types
1. **Welcome Email** - `templates/email/welcome.html.heex`
2. **Password Reset** - `templates/email/reset_password.html.heex`
3. **Update Email** - `templates/email/update_email.html.heex`
4. **Contract Confirmation** - `templates/email/contract_confirmation.html.heex`
5. **Contract Cancelled** - `templates/email/contract_cancelled.html.heex`
6. **Refund Notification** - `templates/email/refund_notification.html.heex`

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 3.1.1 | Create `email_templates` migration | `priv/repo/migrations/` | Table with template_type unique index |
| 3.1.2 | Create `EmailTemplate` schema | `lib/overbooked/settings/email_template.ex` | Fields: template_type, subject, html_body, text_body, variables |
| 3.1.3 | Add email template functions to Settings context | `lib/overbooked/settings.ex` | get_template, update_template, reset_to_default |
| 3.1.4 | Create seed data for default templates | `priv/repo/seeds.exs` | Populate with current template content |
| 3.1.5 | Create AdminEmailTemplatesLive | `lib/overbooked_web/live/admin/admin_email_templates_live.ex` | List view with edit buttons |
| 3.1.6 | Add rich text editor component | `lib/overbooked_web/components/rich_text_editor.ex` | Trix or Quill.js integration |
| 3.1.7 | Create template edit modal | `admin_email_templates_live.ex` | Edit subject + HTML body |
| 3.1.8 | Implement variable substitution engine | `lib/overbooked/email_renderer.ex` | Replace @user.name, @contract.*, etc. |
| 3.1.9 | Add preview pane with sample data | `admin_email_templates_live.ex` | Live preview with variables replaced |
| 3.1.10 | Add reset to default button | `admin_email_templates_live.ex` | Restore original template content |
| 3.1.11 | Update UserNotifier to use DB templates | `lib/overbooked/accounts/user_notifier.ex` | Load from Settings.get_template |
| 3.1.12 | Add route and navigation | `router.ex`, `live_helpers.ex` | `/admin/email-templates` |

### Schema Pattern

```elixir
# lib/overbooked/settings/email_template.ex
defmodule Overbooked.Settings.EmailTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  @template_types ~w(welcome password_reset update_email contract_confirmation contract_cancelled refund_notification)

  schema "email_templates" do
    field :template_type, :string
    field :subject, :string
    field :html_body, :string
    field :text_body, :string
    field :variables, {:array, :string}, default: []
    field :is_custom, :boolean, default: false

    timestamps()
  end

  def changeset(template, attrs) do
    template
    |> cast(attrs, [:template_type, :subject, :html_body, :text_body, :variables, :is_custom])
    |> validate_required([:template_type, :subject, :html_body])
    |> validate_inclusion(:template_type, @template_types)
    |> unique_constraint(:template_type)
  end

  def template_types, do: @template_types

  # Returns list of available variables for each template type
  def available_variables(:welcome), do: ["@user.name", "@user.email"]
  def available_variables(:password_reset), do: ["@user.name", "@reset_url", "@expires_in"]
  def available_variables(:update_email), do: ["@user.name", "@new_email", "@confirm_url"]
  def available_variables(:contract_confirmation) do
    ["@user.name", "@contract.resource.name", "@contract.start_date",
     "@contract.end_date", "@contract.duration_months", "@contract.total_amount",
     "@receipt_url"]
  end
  def available_variables(:contract_cancelled) do
    ["@user.name", "@contract.resource.name", "@contract.end_date", "@refund_info"]
  end
  def available_variables(:refund_notification) do
    ["@user.name", "@contract.resource.name", "@refund_amount", "@refund_date"]
  end
end
```

### Settings Context Functions

```elixir
# Add to lib/overbooked/settings.ex

alias Overbooked.Settings.EmailTemplate

def get_email_template(template_type) do
  case Repo.get_by(EmailTemplate, template_type: to_string(template_type)) do
    nil -> get_default_template(template_type)
    template -> template
  end
end

def list_email_templates do
  Repo.all(from t in EmailTemplate, order_by: t.template_type)
end

def update_email_template(template_type, attrs) do
  case Repo.get_by(EmailTemplate, template_type: to_string(template_type)) do
    nil ->
      %EmailTemplate{template_type: to_string(template_type)}
      |> EmailTemplate.changeset(Map.put(attrs, :is_custom, true))
      |> Repo.insert()
    template ->
      template
      |> EmailTemplate.changeset(Map.put(attrs, :is_custom, true))
      |> Repo.update()
  end
end

def reset_email_template(template_type) do
  default = get_default_template(template_type)

  case Repo.get_by(EmailTemplate, template_type: to_string(template_type)) do
    nil -> {:ok, default}
    template ->
      template
      |> EmailTemplate.changeset(%{
        subject: default.subject,
        html_body: default.html_body,
        text_body: default.text_body,
        is_custom: false
      })
      |> Repo.update()
  end
end

defp get_default_template(template_type) do
  # Load from embedded default templates
  # These are the current .heex files converted to strings
  %EmailTemplate{
    template_type: to_string(template_type),
    subject: default_subject(template_type),
    html_body: default_html_body(template_type),
    text_body: default_text_body(template_type),
    variables: EmailTemplate.available_variables(template_type),
    is_custom: false
  }
end
```

### Email Renderer Module

```elixir
# lib/overbooked/email_renderer.ex
defmodule Overbooked.EmailRenderer do
  @moduledoc """
  Renders email templates with variable substitution.
  Supports @user.name, @contract.resource.name, etc.
  """

  def render(template, assigns) do
    template
    |> replace_variables(assigns)
    |> Phoenix.HTML.raw()
  end

  defp replace_variables(content, assigns) do
    Regex.replace(~r/@(\w+(?:\.\w+)*)/, content, fn _, path ->
      get_nested_value(assigns, String.split(path, "."))
    end)
  end

  defp get_nested_value(map, [key]) when is_map(map) do
    Map.get(map, String.to_atom(key)) |> to_string()
  end

  defp get_nested_value(map, [key | rest]) when is_map(map) do
    case Map.get(map, String.to_atom(key)) do
      nil -> ""
      value -> get_nested_value(value, rest)
    end
  end

  defp get_nested_value(_, _), do: ""
end
```

### Admin UI - Template List

```elixir
# lib/overbooked_web/live/admin/admin_email_templates_live.ex
defmodule OverbookedWeb.Admin.AdminEmailTemplatesLive do
  use OverbookedWeb, :live_view

  alias Overbooked.Settings
  alias Overbooked.Settings.EmailTemplate

  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      templates: Settings.list_email_templates(),
      selected_template: nil,
      preview_data: nil
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-2xl font-semibold text-gray-900">Email Templates</h1>
          <p class="mt-2 text-sm text-gray-700">
            Customize email templates sent to users. Use variables like @user.name to personalize content.
          </p>
        </div>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <%= for template <- @templates do %>
          <div class="bg-white shadow rounded-lg p-6">
            <h3 class="text-lg font-medium text-gray-900">
              <%= humanize_template_type(template.template_type) %>
            </h3>
            <%= if template.is_custom do %>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 mt-2">
                Customized
              </span>
            <% end %>
            <p class="mt-2 text-sm text-gray-500">
              <strong>Subject:</strong> <%= template.subject %>
            </p>
            <div class="mt-4 flex space-x-2">
              <.button phx-click="edit_template" phx-value-type={template.template_type} size={:sm}>
                Edit
              </.button>
              <%= if template.is_custom do %>
                <.button phx-click="reset_template" phx-value-type={template.template_type}
                         variant={:secondary} size={:sm}>
                  Reset to Default
                </.button>
              <% end %>
            </div>

            <!-- Available Variables -->
            <div class="mt-4 pt-4 border-t border-gray-200">
              <p class="text-xs font-medium text-gray-700">Available Variables:</p>
              <div class="mt-1 flex flex-wrap gap-1">
                <%= for var <- template.variables do %>
                  <code class="text-xs bg-gray-100 px-1.5 py-0.5 rounded"><%= var %></code>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @selected_template do %>
        <.live_component
          module={OverbookedWeb.Admin.EmailTemplateEditorComponent}
          id="template-editor"
          template={@selected_template}
          on_close={JS.push("close_editor")}
        />
      <% end %>
    </div>
    """
  end

  def handle_event("edit_template", %{"type" => type}, socket) do
    template = Settings.get_email_template(type)
    {:noreply, assign(socket, selected_template: template)}
  end

  def handle_event("reset_template", %{"type" => type}, socket) do
    case Settings.reset_email_template(type) do
      {:ok, _} ->
        {:noreply, socket
          |> put_flash(:info, "Template reset to default")
          |> assign(templates: Settings.list_email_templates())}
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reset template")}
    end
  end
end
```

### Rich Text Editor Component

```elixir
# lib/overbooked_web/components/rich_text_editor.ex
defmodule OverbookedWeb.Components.RichTextEditor do
  use Phoenix.Component

  attr :id, :string, required: true
  attr :value, :string, default: ""
  attr :on_change, :any, required: true

  def rich_text_editor(assigns) do
    ~H"""
    <div class="rich-text-editor">
      <!-- Use Trix editor (included via CDN or npm) -->
      <input type="hidden" id={@id <> "-input"} value={@value} />
      <trix-editor
        input={@id <> "-input"}
        phx-update="ignore"
        phx-hook="RichTextEditor"
        data-change-event={@on_change}
      ></trix-editor>
    </div>
    """
  end
end
```

### JavaScript Hook for Rich Text Editor

```javascript
// assets/js/app.js - Add this hook
Hooks.RichTextEditor = {
  mounted() {
    this.editor = this.el;
    this.editor.addEventListener("trix-change", (e) => {
      const content = e.target.value;
      this.pushEvent(this.el.dataset.changeEvent, { content });
    });
  }
}
```

---

## 3.2 Contract Terms Editor

DB-backed contract terms shown before checkout with required acceptance checkbox.

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 3.2.1 | Create `contract_terms` migration | `priv/repo/migrations/` | Singleton table with version tracking |
| 3.2.2 | Create `ContractTerm` schema | `lib/overbooked/settings/contract_term.ex` | Fields: content, version, effective_date |
| 3.2.3 | Add contract terms functions to Settings | `lib/overbooked/settings.ex` | get_current_terms, update_terms |
| 3.2.4 | Add terms UI to AdminSettingsLive | `admin_settings_live.ex` | Rich text editor section |
| 3.2.5 | Add accepted_terms_version to contracts | Migration + schema | Track which version user accepted |
| 3.2.6 | Update checkout modal with terms display | `spaces_live.ex` | Show terms + acceptance checkbox |
| 3.2.7 | Add terms acceptance validation | `lib/overbooked/contracts.ex` | Require acceptance before creating contract |
| 3.2.8 | Add terms preview modal | `spaces_live.ex` | Expandable terms view |

### Schema Pattern

```elixir
# lib/overbooked/settings/contract_term.ex
defmodule Overbooked.Settings.ContractTerm do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contract_terms" do
    field :content, :string
    field :version, :integer, default: 1
    field :effective_date, :date
    field :is_active, :boolean, default: true

    timestamps()
  end

  def changeset(term, attrs) do
    term
    |> cast(attrs, [:content, :version, :effective_date, :is_active])
    |> validate_required([:content, :version])
    |> increment_version_if_changed()
  end

  defp increment_version_if_changed(changeset) do
    if changed?(changeset, :content) do
      put_change(changeset, :version, (get_field(changeset, :version) || 0) + 1)
      |> put_change(:effective_date, Date.utc_today())
    else
      changeset
    end
  end
end
```

### Migration - Add Terms Acceptance to Contracts

```elixir
# priv/repo/migrations/YYYYMMDDHHMMSS_add_terms_acceptance_to_contracts.exs
defmodule Overbooked.Repo.Migrations.AddTermsAcceptanceToContracts do
  use Ecto.Migration

  def change do
    alter table(:contracts) do
      add :accepted_terms_version, :integer
      add :terms_accepted_at, :utc_datetime
    end
  end
end
```

### Settings Context Functions

```elixir
# Add to lib/overbooked/settings.ex

alias Overbooked.Settings.ContractTerm

def get_current_contract_terms do
  Repo.one(from t in ContractTerm, where: t.is_active == true, order_by: [desc: t.version], limit: 1)
  || get_default_contract_terms()
end

def get_contract_terms_version(version) do
  Repo.get_by(ContractTerm, version: version)
end

def update_contract_terms(attrs) do
  case get_current_contract_terms() do
    %{id: nil} = default ->
      %ContractTerm{}
      |> ContractTerm.changeset(Map.put(attrs, :is_active, true))
      |> Repo.insert()
    current ->
      # Create new version
      %ContractTerm{}
      |> ContractTerm.changeset(Map.merge(attrs, %{
        version: current.version + 1,
        is_active: true
      }))
      |> Repo.insert()
      |> case do
        {:ok, new_term} ->
          # Deactivate old version
          current
          |> ContractTerm.changeset(%{is_active: false})
          |> Repo.update()
          {:ok, new_term}
        error -> error
      end
  end
end

defp get_default_contract_terms do
  %ContractTerm{
    content: default_contract_terms_content(),
    version: 0,
    effective_date: Date.utc_today(),
    is_active: true
  }
end

defp default_contract_terms_content do
  """
  <h2>Office Space Rental Agreement</h2>

  <p>By proceeding with this reservation, you agree to the following terms:</p>

  <ol>
    <li><strong>Payment:</strong> Payment is due in full at the time of booking.</li>
    <li><strong>Cancellation:</strong> Cancellations made within 48 hours of the start date are non-refundable.</li>
    <li><strong>Use:</strong> The space must be used in accordance with building rules and regulations.</li>
    <li><strong>Liability:</strong> You are responsible for any damage to the space during your rental period.</li>
  </ol>

  <p>For full terms and conditions, please contact our support team.</p>
  """
end
```

### Admin UI - Contract Terms Section

```html
<!-- Add to admin_settings_live.ex -->
<div class="bg-white shadow rounded-lg mt-8">
  <div class="px-4 py-5 sm:p-6">
    <h3 class="text-lg font-medium leading-6 text-gray-900">
      Contract Terms & Conditions
    </h3>
    <p class="mt-1 text-sm text-gray-500">
      Customize the terms shown to users before they complete a space rental.
      Changing terms creates a new version automatically.
    </p>

    <%= if @current_terms do %>
      <div class="mt-4 bg-gray-50 p-3 rounded">
        <p class="text-sm text-gray-700">
          <strong>Current Version:</strong> <%= @current_terms.version %>
          <span class="ml-4"><strong>Effective Date:</strong> <%= @current_terms.effective_date %></span>
        </p>
      </div>
    <% end %>

    <.form for={@terms_changeset} phx-submit="save_contract_terms" class="mt-6">
      <div>
        <label class="block text-sm font-medium text-gray-700">Terms Content</label>
        <.rich_text_editor
          id="contract-terms-editor"
          value={@terms_changeset.data.content}
          on_change="update_terms_content"
        />
        <p class="mt-2 text-xs text-gray-500">
          Use HTML formatting. Users will see this before checkout and must accept to proceed.
        </p>
      </div>

      <div class="flex items-center justify-between pt-4 mt-4 border-t">
        <div class="flex items-center space-x-4">
          <.button type="submit">Save Terms</.button>
          <.button type="button" phx-click="preview_terms" variant={:secondary}>
            Preview
          </.button>
        </div>
        <p class="text-xs text-gray-500">
          Saving will create version <%= (@current_terms.version || 0) + 1 %>
        </p>
      </div>
    </.form>
  </div>
</div>
```

### Updated Checkout Modal with Terms

```elixir
# Update in spaces_live.ex - checkout modal
def render_checkout_modal(assigns) do
  ~H"""
  <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
    <div class="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
      <div class="p-6">
        <h3 class="text-lg font-medium">Reserve <%= @selected_space.name %></h3>

        <!-- Duration selection -->
        <div class="mt-4">
          <!-- existing duration selection code -->
        </div>

        <!-- Contract Terms -->
        <div class="mt-6 border-t pt-6">
          <h4 class="text-sm font-medium text-gray-900">Terms & Conditions</h4>

          <div class="mt-3 bg-gray-50 rounded-lg p-4 max-h-60 overflow-y-auto">
            <%= Phoenix.HTML.raw(@contract_terms.content) %>
          </div>

          <div class="mt-4 flex items-start">
            <input
              type="checkbox"
              id="accept-terms"
              phx-click="toggle_terms_acceptance"
              checked={@terms_accepted}
              class="h-4 w-4 text-blue-600 border-gray-300 rounded"
            />
            <label for="accept-terms" class="ml-2 text-sm text-gray-700">
              I have read and agree to the terms and conditions (Version <%= @contract_terms.version %>)
            </label>
          </div>
        </div>

        <!-- Action buttons -->
        <div class="mt-6 flex justify-end space-x-3">
          <.button phx-click="close_checkout" variant={:secondary}>Cancel</.button>
          <.button
            phx-click="proceed_to_payment"
            disabled={!@terms_accepted}
          >
            Proceed to Payment
          </.button>
        </div>
      </div>
    </div>
  </div>
  """
end
```

### Updated Contract Schema

```elixir
# Update lib/overbooked/contracts/contract.ex
schema "contracts" do
  # ... existing fields ...
  field :accepted_terms_version, :integer
  field :terms_accepted_at, :utc_datetime

  # ... existing associations ...
end

def changeset(contract, attrs) do
  contract
  |> cast(attrs, [..., :accepted_terms_version, :terms_accepted_at])
  |> validate_required([..., :accepted_terms_version])
  # ... existing validations ...
end
```

---

## Phase 3 Implementation Order

1. **3.1 Email Template Editor** - Foundation for customizable emails
   - Start with database schema and Settings context functions
   - Build admin UI with rich text editor integration
   - Implement variable substitution engine
   - Update UserNotifier to use DB templates
   - Add preview functionality

2. **3.2 Contract Terms Editor** - Legal compliance and customization
   - Create contract terms schema with versioning
   - Add admin UI for editing terms
   - Update checkout flow to display and require acceptance
   - Track accepted version in contracts table

---

## Database Schema Additions

### email_templates
```sql
CREATE TABLE email_templates (
  id BIGSERIAL PRIMARY KEY,
  template_type VARCHAR NOT NULL,
  subject VARCHAR NOT NULL,
  html_body TEXT NOT NULL,
  text_body TEXT,
  variables VARCHAR[] DEFAULT '{}',
  is_custom BOOLEAN DEFAULT false,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);
CREATE UNIQUE INDEX email_templates_type_idx ON email_templates (template_type);
```

### contract_terms
```sql
CREATE TABLE contract_terms (
  id BIGSERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  version INTEGER NOT NULL DEFAULT 1,
  effective_date DATE,
  is_active BOOLEAN DEFAULT true,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);
CREATE INDEX contract_terms_version_idx ON contract_terms (version);
CREATE INDEX contract_terms_active_idx ON contract_terms (is_active);
```

### contracts (additions)
```sql
ALTER TABLE contracts ADD COLUMN accepted_terms_version INTEGER;
ALTER TABLE contracts ADD COLUMN terms_accepted_at TIMESTAMP;
```

---

## Testing Checklist - Phase 3

### Email Template Editor
- [ ] Can view all 6 email templates
- [ ] Can edit template subject and HTML body
- [ ] Rich text editor saves formatting correctly
- [ ] Variable substitution works (@user.name, @contract.*, etc.)
- [ ] Preview pane shows correctly with sample data
- [ ] Reset to default restores original template
- [ ] Custom templates show "Customized" badge
- [ ] Emails sent use DB templates when available
- [ ] Falls back to file templates if DB template missing

### Contract Terms
- [ ] Can edit contract terms in admin settings
- [ ] Rich text formatting persists
- [ ] Version increments automatically when content changes
- [ ] Checkout modal displays current terms
- [ ] Acceptance checkbox required to proceed
- [ ] Cannot submit payment without accepting terms
- [ ] Contract records accepted version number
- [ ] Historical terms versions are preserved
- [ ] Can preview terms before saving

---

## Dependencies

### NPM Packages (for Rich Text Editor)
```json
{
  "dependencies": {
    "trix": "^2.0.0"
  }
}
```

Or use CDN:
```html
<!-- In root.html.heex -->
<link rel="stylesheet" href="https://unpkg.com/trix@2.0.0/dist/trix.css">
<script src="https://unpkg.com/trix@2.0.0/dist/trix.umd.min.js"></script>
```

---

# Implementation Order

## Phase 2A: Admin Foundation ✅ COMPLETED
1. ✅ **2.1 Stripe Admin Settings** - DB-backed config with Stripe section in admin settings
2. ✅ **2.2 Admin Spaces Management** - Full CRUD at `/admin/spaces`
3. ✅ **2.3 Admin Contracts Management** - View/filter/cancel at `/admin/contracts`

## Phase 2B: User Experience ✅ COMPLETED
4. ✅ **2.4 Contract Email Templates** - Confirmation + cancellation emails

## Phase 2C: Operations ✅ COMPLETED
5. ✅ **2.5 Stripe Customer Portal** - Self-service billing via `/billing`
6. ✅ **2.6 Refund Handling** - Full refund workflow with admin UI and email notifications

---

# Environment Variables

## Current Production Config
```bash
# Stripe (currently required as env vars)
STRIPE_SECRET_KEY=sk_live_...       # or sk_test_... for testing
STRIPE_WEBHOOK_SECRET=whsec_...     # From Stripe webhook settings

# Mailgun (existing, also DB-configurable)
MAILGUN_API_KEY=key-...
MAILGUN_DOMAIN=mg.yourdomain.com

# Application
SECRET_KEY_BASE=...
DATABASE_URL=...
PHX_HOST=...
```

## After Phase 2.1 (DB-backed)
Stripe keys will be configurable via Admin → Settings, with env vars as fallback.

---

# Database Schema Reference

## Existing Tables (Phase 1-2 Current)

### contracts
```sql
CREATE TABLE contracts (
  id BIGSERIAL PRIMARY KEY,
  status VARCHAR DEFAULT 'pending',        -- pending, active, cancelled, expired
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  duration_months INTEGER NOT NULL,        -- 1 or 3
  monthly_rate_cents INTEGER NOT NULL,
  total_amount_cents INTEGER NOT NULL,
  stripe_checkout_session_id VARCHAR,
  stripe_payment_intent_id VARCHAR,
  stripe_customer_id VARCHAR,
  resource_id BIGINT REFERENCES resources(id),
  user_id BIGINT REFERENCES users(id),
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### resources (with rentable fields)
```sql
-- Added columns for rentable spaces
ALTER TABLE resources ADD COLUMN is_rentable BOOLEAN DEFAULT false;
ALTER TABLE resources ADD COLUMN monthly_rate_cents INTEGER;
ALTER TABLE resources ADD COLUMN description TEXT;
```

### mail_settings (singleton pattern)
```sql
CREATE TABLE mail_settings (
  id BIGSERIAL PRIMARY KEY,
  adapter VARCHAR DEFAULT 'mailgun',
  mailgun_api_key VARCHAR,
  mailgun_domain VARCHAR,
  from_email VARCHAR,
  from_name VARCHAR DEFAULT 'Hatchbridge Rooms',
  enabled BOOLEAN DEFAULT false
);
CREATE UNIQUE INDEX mail_settings_singleton ON mail_settings (id) WHERE id IS NOT NULL;
```

---

# Testing Checklist

## Stripe Integration
- [ ] Checkout session creates successfully
- [ ] Webhook receives and validates events
- [ ] Contract activates on successful payment
- [ ] Calendar booking blocks resource for contract period
- [ ] 10% discount applies to 3-month contracts
- [ ] User can view their contracts
- [ ] User can cancel active contract

## Admin Settings
- [ ] Stripe keys save to database (encoded)
- [ ] Keys are masked in UI display
- [ ] Test connection validates API key
- [ ] Webhook URL displays correctly
- [ ] Enable/disable toggle works
- [ ] Falls back to env vars when DB config disabled

## Admin Spaces
- [x] Navigation works (nav.ex + layout.heex fixed)
- [x] Page loads without error (fixed form field name conflict - see Bug Fixes below)
- [ ] Can create new rentable space with pricing
- [ ] Can edit existing space
- [ ] Can toggle is_rentable
- [ ] Shows availability status

## Admin Contracts
- [x] Navigation works (nav.ex + layout.heex fixed)
- [ ] View all contracts with user info
- [ ] Filter by status works
- [ ] Contract detail modal shows correctly
- [ ] Admin cancel works

---

# Bug Fixes

## Admin Spaces Form Field Conflict (2024-12-21)

**Problem:** Visiting `/admin/spaces` caused an internal server error:
```
Protocol.UndefinedError: protocol Phoenix.HTML.Safe not implemented for
#Ecto.Association.NotLoaded<association :resource_type is not loaded>
```

**Root Cause:** The form used `:resource_type` as the select field name, which conflicts with the `belongs_to :resource_type` Ecto association on the Resource schema. When Phoenix tried to get the current value for the select, it accessed the unloaded association struct.

**Fix:** Renamed the form field from `:resource_type` to `:resource_type_name` in `admin_spaces_live.ex`:
- Line 74: `<.select form={f} field={:resource_type_name} ...>`
- Line 293: `Map.get(resource_params, "resource_type_name", "room")`

**Lesson:** Avoid using Ecto association names as form field names when the association isn't loaded.

---

# Reference Links

- [Stripe Checkout](https://stripe.com/docs/checkout/quickstart)
- [Stripe Webhooks](https://stripe.com/docs/webhooks)
- [Stripe Customer Portal](https://stripe.com/docs/billing/subscriptions/customer-portal)
- [stripity_stripe Docs](https://hexdocs.pm/stripity_stripe)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Swoosh Multipart Email](https://hexdocs.pm/swoosh/Swoosh.Email.html)

---

# Acknowledgments

Bug fix bounty (if applicable) should be donated to the **Erlang Ecosystem Foundation (EEF)** - a 501(c)(3) nonprofit that supports the Erlang/Elixir ecosystem, including Phoenix, LiveView, and the BEAM community that makes this project possible.

- Website: https://erlef.org
- Donate: https://erlef.org/sponsors
