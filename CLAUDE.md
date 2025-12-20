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
| Admin Spaces | ✅ Complete | `lib/overbooked_web/live/admin/admin_spaces_live.ex` |
| Admin Contracts | ✅ Complete | `lib/overbooked_web/live/admin/admin_contracts_live.ex` |
| Nav Integration | ✅ Fixed | `lib/overbooked_web/live/nav.ex`, `templates/layout/live.html.heex` |
| Contract Emails | ✅ Complete | `templates/email/contract_confirmation.html.heex`, `contract_cancelled.html.heex` |

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
        Subscribe to: <code>checkout.session.completed</code>, <code>payment_intent.succeeded</code>
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

## 2.5 Stripe Customer Portal (Priority: LOW)

Allow users to manage billing through Stripe.

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 2.5.1 | Add create_portal_session | `stripe.ex` | Creates portal session |
| 2.5.2 | Add billing route | `router.ex` | `/billing` redirects to Stripe |
| 2.5.3 | Add portal link to contracts page | `contracts_live.ex` | "Manage Billing" button |

---

## 2.6 Refund Handling (Priority: LOW)

Handle refunds for cancelled contracts.

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 2.6.1 | Add create_refund function | `stripe.ex` | Initiates Stripe refund |
| 2.6.2 | Add refund fields to contract | Migration + schema | refund_amount_cents, refunded_at |
| 2.6.3 | Handle charge.refunded webhook | `stripe_webhook_controller.ex` | Update contract |
| 2.6.4 | Add refund button for admin | `admin_contracts_live.ex` | Admin initiates refund |

---

# Implementation Order

## Phase 2A: Admin Foundation ✅ COMPLETED
1. ✅ **2.1 Stripe Admin Settings** - DB-backed config with Stripe section in admin settings
2. ✅ **2.2 Admin Spaces Management** - Full CRUD at `/admin/spaces`
3. ✅ **2.3 Admin Contracts Management** - View/filter/cancel at `/admin/contracts`

## Phase 2B: User Experience ✅ COMPLETED
4. ✅ **2.4 Contract Email Templates** - Confirmation + cancellation emails

## Phase 2C: Operations (Future)
5. 📋 **2.5 Stripe Customer Portal** - Self-service billing
6. 📋 **2.6 Refund Handling** - Handle cancellation refunds

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

# Reference Links

- [Stripe Checkout](https://stripe.com/docs/checkout/quickstart)
- [Stripe Webhooks](https://stripe.com/docs/webhooks)
- [Stripe Customer Portal](https://stripe.com/docs/billing/subscriptions/customer-portal)
- [stripity_stripe Docs](https://hexdocs.pm/stripity_stripe)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Swoosh Multipart Email](https://hexdocs.pm/swoosh/Swoosh.Email.html)
