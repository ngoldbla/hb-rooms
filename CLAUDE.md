# Hatchbridge Rooms - Agent Guide

## Project Overview

**Stack:** Phoenix 1.7 + LiveView + Tailwind CSS + PostgreSQL + Swoosh (Mailgun) + Stripe
**Purpose:** Self-hosted coworking space management platform

## Current State

| Area | Status | Key Files |
|------|--------|-----------|
| Mobile Layout | ✅ Done | `templates/layout/live.html.heex` |
| Email System | ✅ Done | `accounts/user_notifier.ex`, `templates/email/` |
| Mailgun Admin | ✅ Done | `live/admin/admin_settings_live.ex` |
| Spaces Browsing | ✅ Done | `live/spaces_live.ex` |
| Stripe Checkout | ✅ Done | `stripe.ex`, `stripe_webhook_controller.ex` |
| Contracts (User) | ✅ Done | `live/contracts_live.ex`, `contracts.ex` |
| Stripe Admin | ✅ Done | `settings/stripe_setting.ex`, `admin_settings_live.ex` |
| Admin Spaces | ✅ Done | `live/admin/admin_spaces_live.ex` |
| Admin Contracts | ✅ Done | `live/admin/admin_contracts_live.ex` |
| Contract Emails | ✅ Done | `templates/email/contract_*.html.heex` |
| Customer Portal | ✅ Done | `billing_controller.ex` |
| Refund Handling | ✅ Done | `stripe.ex`, `contracts.ex` |
| **Email Template Editor** | 📋 Next | Phase 3.1 below |
| **Contract Terms Editor** | 📋 Next | Phase 3.2 below |

## Brand Assets

- **Logo:** `priv/static/images/hatchbridge-logo.svg`, `logo.png`
- **Colors:** Yellow `#FFC421`, Blue `#2153FF`, Dark `#000824`
- **Font:** Nunito Sans

---

# Phase 3: Email Templates + Contract Terms

**Goal:** Admin customization of email content and contract terms without code changes.

---

## 3.1 Email Template Editor

Admin UI to customize all 6 email types with rich text editing, variable preview, and reset to default.

### Email Types
1. `welcome` - `templates/email/welcome.html.heex`
2. `password_reset` - `templates/email/reset_password.html.heex`
3. `update_email` - `templates/email/update_email.html.heex`
4. `contract_confirmation` - `templates/email/contract_confirmation.html.heex`
5. `contract_cancelled` - `templates/email/contract_cancelled.html.heex`
6. `refund_notification` - `templates/email/refund_notification.html.heex`

### Tasks

| # | Task | Files | Notes |
|---|------|-------|-------|
| 3.1.1 | Create `email_templates` migration | `priv/repo/migrations/` | `template_type` unique index |
| 3.1.2 | Create `EmailTemplate` schema | `lib/overbooked/settings/email_template.ex` | template_type, subject, html_body, text_body, variables, is_custom |
| 3.1.3 | Add Settings context functions | `lib/overbooked/settings.ex` | get_template, update_template, reset_to_default, list_templates |
| 3.1.4 | Seed default templates | `priv/repo/seeds.exs` | Convert current .heex content to DB records |
| 3.1.5 | Create AdminEmailTemplatesLive | `lib/overbooked_web/live/admin/admin_email_templates_live.ex` | Grid of template cards |
| 3.1.6 | Add rich text editor | `lib/overbooked_web/components/` | Trix.js integration with LiveView hook |
| 3.1.7 | Template edit modal | `admin_email_templates_live.ex` | Edit subject + HTML body |
| 3.1.8 | Variable substitution engine | `lib/overbooked/email_renderer.ex` | Replace @user.name, @contract.* patterns |
| 3.1.9 | Preview pane | `admin_email_templates_live.ex` | Live preview with sample data |
| 3.1.10 | Reset to default | `admin_email_templates_live.ex` | Restore original template |
| 3.1.11 | Update UserNotifier | `lib/overbooked/accounts/user_notifier.ex` | Load from DB, fallback to file |
| 3.1.12 | Add route + nav | `router.ex` | `/admin/email-templates` |

### Schema

```elixir
# lib/overbooked/settings/email_template.ex
schema "email_templates" do
  field :template_type, :string  # welcome, password_reset, etc.
  field :subject, :string
  field :html_body, :string
  field :text_body, :string
  field :variables, {:array, :string}, default: []
  field :is_custom, :boolean, default: false
  timestamps()
end

# Available variables per template type
def available_variables(:welcome), do: ["@user.name", "@user.email"]
def available_variables(:password_reset), do: ["@user.name", "@reset_url", "@expires_in"]
def available_variables(:update_email), do: ["@user.name", "@new_email", "@confirm_url"]
def available_variables(:contract_confirmation), do: [
  "@user.name", "@contract.resource.name", "@contract.start_date",
  "@contract.end_date", "@contract.duration_months", "@contract.total_amount", "@receipt_url"
]
def available_variables(:contract_cancelled), do: ["@user.name", "@contract.resource.name", "@contract.end_date", "@refund_info"]
def available_variables(:refund_notification), do: ["@user.name", "@contract.resource.name", "@refund_amount", "@refund_date"]
```

### Email Renderer

```elixir
# lib/overbooked/email_renderer.ex
def render(template, assigns) do
  Regex.replace(~r/@(\w+(?:\.\w+)*)/, template, fn _, path ->
    get_nested_value(assigns, String.split(path, "."))
  end)
end

defp get_nested_value(map, [key]) when is_map(map), do: Map.get(map, String.to_atom(key)) |> to_string()
defp get_nested_value(map, [key | rest]) when is_map(map) do
  case Map.get(map, String.to_atom(key)) do
    nil -> ""
    value -> get_nested_value(value, rest)
  end
end
defp get_nested_value(_, _), do: ""
```

### Rich Text Editor Hook

```javascript
// assets/js/app.js
Hooks.RichTextEditor = {
  mounted() {
    this.el.addEventListener("trix-change", (e) => {
      this.pushEvent(this.el.dataset.changeEvent, { content: e.target.value });
    });
  }
}
```

Add Trix via CDN in `root.html.heex`:
```html
<link rel="stylesheet" href="https://unpkg.com/trix@2.0.0/dist/trix.css">
<script src="https://unpkg.com/trix@2.0.0/dist/trix.umd.min.js"></script>
```

---

## 3.2 Contract Terms Editor

DB-backed contract terms with versioning, shown at checkout with required acceptance.

### Tasks

| # | Task | Files | Notes |
|---|------|-------|-------|
| 3.2.1 | Create `contract_terms` migration | `priv/repo/migrations/` | content, version, effective_date, is_active |
| 3.2.2 | Create `ContractTerm` schema | `lib/overbooked/settings/contract_term.ex` | Auto-increment version on content change |
| 3.2.3 | Add Settings context functions | `lib/overbooked/settings.ex` | get_current_terms, update_terms, get_version |
| 3.2.4 | Add terms section to AdminSettingsLive | `admin_settings_live.ex` | Rich text editor, version display |
| 3.2.5 | Add fields to contracts table | Migration | accepted_terms_version, terms_accepted_at |
| 3.2.6 | Update checkout modal | `spaces_live.ex` | Display terms, acceptance checkbox |
| 3.2.7 | Add acceptance validation | `contracts.ex` | Require terms acceptance before contract creation |
| 3.2.8 | Terms preview modal | `spaces_live.ex` | Expandable full terms view |

### Schema

```elixir
# lib/overbooked/settings/contract_term.ex
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
    changeset
    |> put_change(:version, (get_field(changeset, :version) || 0) + 1)
    |> put_change(:effective_date, Date.utc_today())
  else
    changeset
  end
end
```

### Contract Schema Addition

```elixir
# Add to lib/overbooked/contracts/contract.ex
field :accepted_terms_version, :integer
field :terms_accepted_at, :utc_datetime
```

### Default Terms Content

```html
<h2>Office Space Rental Agreement</h2>
<p>By proceeding with this reservation, you agree to the following terms:</p>
<ol>
  <li><strong>Payment:</strong> Payment is due in full at the time of booking.</li>
  <li><strong>Cancellation:</strong> Cancellations made within 48 hours of the start date are non-refundable.</li>
  <li><strong>Use:</strong> The space must be used in accordance with building rules and regulations.</li>
  <li><strong>Liability:</strong> You are responsible for any damage to the space during your rental period.</li>
</ol>
<p>For full terms and conditions, please contact our support team.</p>
```

---

## Database Migrations (Phase 3)

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
```

### contracts additions
```sql
ALTER TABLE contracts ADD COLUMN accepted_terms_version INTEGER;
ALTER TABLE contracts ADD COLUMN terms_accepted_at TIMESTAMP;
```

---

## Testing Checklist (Phase 3)

### Email Templates
- [ ] View all 6 templates in admin grid
- [ ] Edit subject and HTML body with rich text editor
- [ ] Variable substitution (@user.name, @contract.*)
- [ ] Live preview with sample data
- [ ] Reset to default works
- [ ] "Customized" badge shows for modified templates
- [ ] Emails use DB templates, fall back to files

### Contract Terms
- [ ] Edit terms in admin settings with rich text
- [ ] Version auto-increments on content change
- [ ] Checkout modal shows terms with scroll
- [ ] Acceptance checkbox required to proceed
- [ ] Contract stores accepted version
- [ ] Historical versions preserved

---

# Environment Variables

```bash
# Required
SECRET_KEY_BASE=...
DATABASE_URL=...
PHX_HOST=...

# Stripe (env fallback if not in DB)
STRIPE_SECRET_KEY=sk_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Mailgun (env fallback if not in DB)
MAILGUN_API_KEY=key-...
MAILGUN_DOMAIN=mg.yourdomain.com
```

---

# Reference Links

- [Stripe Checkout](https://stripe.com/docs/checkout/quickstart)
- [Stripe Webhooks](https://stripe.com/docs/webhooks)
- [Stripe Customer Portal](https://stripe.com/docs/billing/subscriptions/customer-portal)
- [stripity_stripe](https://hexdocs.pm/stripity_stripe)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Trix Editor](https://trix-editor.org/)

---

# Known Issues

## Form Field vs Association Conflict
When using form fields, avoid names that match `belongs_to` associations (e.g., don't use `:resource_type` field when schema has `belongs_to :resource_type`). Phoenix will try to render the unloaded association. Use an alternate name like `:resource_type_name`.
