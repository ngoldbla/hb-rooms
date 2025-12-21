# Hatchbridge Rooms - AI Assistant Guide

## Project Overview

**Name:** Overbooked (branded as Hatchbridge Rooms)
**Stack:** Phoenix 1.6.6 + LiveView 0.18 + Tailwind CSS + PostgreSQL + Swoosh (Mailgun) + Stripe
**Purpose:** Self-hosted coworking space management platform for indie co-working owners
**Language:** Elixir 1.14+

---

## 🚧 Phase 3.5: Admin Navigation UX Refactor (PLANNING)

### Problem Statement

The current admin navigation uses a horizontal tab bar (`flex flex-row space-x-2`) with 8 tabs:
- Users, Rooms, Desks, Amenities, Spaces, Contracts, Settings, Templates

**Critical UX Issues:**
1. **Horizontal scrolling on mobile** - violates mobile UX best practices
2. **Not all tabs visible at once** - users must discover options by swiping
3. **Insufficient touch targets** - tabs are too small for thumbs
4. **No responsive behavior** - desktop UI is "shrunk" rather than adapted

**Current Implementation:** `lib/overbooked_web/live/live_helpers.ex:753-767` (tabs component)

### Design Solution: Hybrid Approach

Combine multiple strategies from UX best practices:

#### Mobile (< 768px): Grouped Dropdown Navigation

**Pattern:** iOS Settings-style index with logical grouping

```
[Dropdown: People ▼]
┌─────────────────────────┐
│ People                  │
│ ├─ Users                │
│ └─ Contracts            │
│ Spaces                  │
│ ├─ Rooms                │
│ ├─ Desks                │
│ ├─ Amenities            │
│ └─ Office Spaces        │
│ Configuration           │
│ ├─ Settings             │
│ └─ Email Templates      │
└─────────────────────────┘
```

**Implementation:**
- Native `<select>` (accessible, platform-native feel)
- OR custom dropdown with touch-optimized targets (min 44px)
- Current section shown with down chevron
- Groups collapse in dropdown for scanability
- LiveView handles navigation on selection

#### Tablet (768px - 1024px): Vertical Sidebar

**Pattern:** Full vertical list, always visible

```
┌──────────────┐
│ People       │
│  Users       │ ← 44px min height
│  Contracts   │
│              │
│ Spaces       │
│  Rooms       │
│  Desks       │
│  Amenities   │
│  Office Sp.. │
│              │
│ Config       │
│  Settings    │
│  Templates   │
└──────────────┘
```

#### Desktop (> 1024px): Enhanced Horizontal Tabs

**Pattern:** Current horizontal tabs with grouping indicators

```
People          Spaces                    Configuration
─────────────   ────────────────────────  ─────────────────
Users Contracts Rooms Desks Amenities Spaces Settings Templates
```

### Logical Grouping

| Group | Items | Rationale |
|-------|-------|-----------|
| **People** | Users, Contracts | User management and their commitments |
| **Spaces** | Rooms, Desks, Amenities, Office Spaces | Physical resources |
| **Configuration** | Settings, Email Templates | System-wide configuration |

### Implementation Plan

#### Files to Modify

1. **`lib/overbooked_web/live/live_helpers.ex`**
   - Create `admin_nav_mobile/1` component (dropdown)
   - Create `admin_nav_tablet/1` component (vertical sidebar)
   - Create `admin_nav_desktop/1` component (enhanced horizontal)
   - Update `admin_tabs/1` to dispatch based on viewport

2. **CSS/Tailwind Classes**
   - Mobile: `block md:hidden` for dropdown
   - Tablet: `hidden md:block lg:hidden` for sidebar
   - Desktop: `hidden lg:flex` for horizontal tabs

#### Component Structure

```elixir
def admin_tabs(assigns) do
  ~H"""
  <!-- Mobile: Dropdown -->
  <div class="block md:hidden">
    <.admin_nav_mobile active_tab={@active_tab} socket={@socket} />
  </div>

  <!-- Tablet: Vertical Sidebar -->
  <div class="hidden md:block lg:hidden">
    <.admin_nav_tablet active_tab={@active_tab} socket={@socket} />
  </div>

  <!-- Desktop: Horizontal Tabs -->
  <div class="hidden lg:flex">
    <.admin_nav_desktop active_tab={@active_tab} socket={@socket} />
  </div>
  """
end
```

#### Mobile Dropdown Implementation

```elixir
defp admin_nav_mobile(assigns) do
  ~H"""
  <div class="relative">
    <select
      phx-change="admin_nav_change"
      class="block w-full py-3 px-4 text-base border-gray-300 focus:outline-none focus:ring-primary-500 focus:border-primary-500 rounded-md"
    >
      <optgroup label="People">
        <option value="/admin/users" selected={@active_tab == :admin_users}>Users</option>
        <option value="/admin/contracts" selected={@active_tab == :admin_contracts}>Contracts</option>
      </optgroup>
      <optgroup label="Spaces">
        <option value="/admin/rooms" selected={@active_tab == :admin_rooms}>Rooms</option>
        <option value="/admin/desks" selected={@active_tab == :admin_desks}>Desks</option>
        <option value="/admin/amenities" selected={@active_tab == :admin_amenities}>Amenities</option>
        <option value="/admin/spaces" selected={@active_tab == :admin_spaces}>Office Spaces</option>
      </optgroup>
      <optgroup label="Configuration">
        <option value="/admin/settings" selected={@active_tab == :admin_settings}>Settings</option>
        <option value="/admin/email-templates" selected={@active_tab == :admin_email_templates}>Email Templates</option>
      </optgroup>
    </select>
  </div>
  """
end

# Handle navigation in mount/3
def handle_event("admin_nav_change", %{"value" => path}, socket) do
  {:noreply, push_navigate(socket, to: path)}
end
```

#### Tablet Vertical Sidebar Implementation

```elixir
defp admin_nav_tablet(assigns) do
  ~H"""
  <nav class="space-y-1 py-2">
    <!-- People Group -->
    <div class="px-3 py-2 text-xs font-semibold text-gray-500 uppercase tracking-wider">
      People
    </div>
    <.nav_link active={@active_tab == :admin_users} path={Routes.admin_users_path(@socket, :index)}>
      Users
    </.nav_link>
    <.nav_link active={@active_tab == :admin_contracts} path={Routes.admin_contracts_path(@socket, :index)}>
      Contracts
    </.nav_link>

    <!-- Spaces Group -->
    <div class="px-3 py-2 text-xs font-semibold text-gray-500 uppercase tracking-wider mt-4">
      Spaces
    </div>
    <.nav_link active={@active_tab == :admin_rooms} path={Routes.admin_rooms_path(@socket, :index)}>
      Rooms
    </.nav_link>
    <!-- ... more items ... -->
  </nav>
  """
end

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
```

### Touch Ergonomics Checklist

- [x] Minimum 44px tap targets (py-2.5 = 40px + text height ≈ 48px)
- [x] No truncated labels (full width on mobile)
- [x] Clear active state (bg-primary-100 for active)
- [x] All options visible without scrolling (dropdown reveals all)
- [x] Mobile-first breakpoint logic (explicit components per viewport)

### Testing Plan

1. **Mobile (< 768px)**
   - [ ] Dropdown shows current section
   - [ ] All 8 sections visible in dropdown
   - [ ] Tap targets ≥ 44px
   - [ ] Navigation works without page reload (LiveView)
   - [ ] No horizontal scrolling

2. **Tablet (768px - 1024px)**
   - [ ] Vertical sidebar visible
   - [ ] Grouped sections with labels
   - [ ] Active state clear
   - [ ] Sidebar doesn't interfere with content

3. **Desktop (> 1024px)**
   - [ ] Horizontal tabs with grouping
   - [ ] All tabs visible without scrolling
   - [ ] Hover states work

### Alternative: Settings Index Pattern

If dropdown feels too "app-like" for a web context, consider a dedicated index page:

**Route:** `/admin` → Index page with cards
**Routes:** `/admin/users`, `/admin/rooms`, etc. → Specific sections

```elixir
# admin_index_live.ex
def render(assigns) do
  ~H"""
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
    <.admin_section_card
      title="People"
      items={[
        %{label: "Users", path: Routes.admin_users_path(@socket, :index)},
        %{label: "Contracts", path: Routes.admin_contracts_path(@socket, :index)}
      ]}
    />
    <.admin_section_card title="Spaces" items={[...]} />
    <.admin_section_card title="Configuration" items={[...]} />
  </div>
  """
end
```

**Pros:** Very clear on mobile, no navigation "chrome"
**Cons:** Extra tap to reach sections, breaks muscle memory

### Decision Required

Choose implementation approach:
1. **Dropdown (Recommended)** - Best mobile UX, minimal layout changes
2. **Index page** - Most orthodox, clearest mobile hierarchy
3. **Hybrid** - Dropdown on mobile, index on desktop

---

## Architecture Overview

### Application Structure

```
lib/
├── overbooked/                    # Business logic contexts
│   ├── accounts/                  # User authentication & management
│   │   ├── user.ex
│   │   ├── user_token.ex
│   │   ├── user_notifier.ex      # Email sending logic
│   │   └── registration_token.ex
│   ├── scheduler/                 # Booking system
│   │   └── booking.ex
│   ├── resources/                 # Rooms, desks, amenities
│   │   ├── resource.ex
│   │   ├── resource_type.ex
│   │   ├── amenity.ex
│   │   └── resource_amenity.ex
│   ├── contracts/                 # Long-term space rentals
│   │   └── contract.ex
│   ├── settings/                  # App configuration
│   │   ├── mail_setting.ex       # Mailgun config
│   │   ├── stripe_setting.ex     # Stripe config
│   │   ├── email_template.ex     # Custom email templates
│   │   ├── contract_term.ex      # Contract T&Cs with versioning
│   │   └── default_templates.ex  # Default email content
│   ├── stripe.ex                  # Stripe API integration
│   ├── email_renderer.ex          # Template variable substitution
│   ├── mailer.ex                  # Swoosh email delivery
│   └── repo.ex                    # Ecto repository
│
└── overbooked_web/                # Web layer
    ├── live/                      # LiveView modules
    │   ├── admin/                 # Admin-only pages
    │   │   ├── admin_users_live.ex
    │   │   ├── admin_rooms_live.ex
    │   │   ├── admin_desks_live.ex
    │   │   ├── admin_amenities_live.ex
    │   │   ├── admin_spaces_live.ex
    │   │   ├── admin_contracts_live.ex
    │   │   ├── admin_settings_live.ex        # Mailgun, Stripe, Contract Terms
    │   │   └── admin_email_templates_live.ex # Email template editor
    │   ├── scheduler/             # Calendar views
    │   │   ├── schedule_monthly_live.ex
    │   │   ├── schedule_weekly_live.ex
    │   │   └── booking_form_live.ex
    │   ├── user/                  # Auth pages
    │   │   ├── login_live.ex
    │   │   ├── signup_live.ex
    │   │   └── user_settings_live.ex
    │   ├── spaces_live.ex         # Browse & rent spaces (Stripe checkout)
    │   ├── contracts_live.ex      # User's contract management
    │   └── home_live.ex
    ├── controllers/
    │   ├── billing_controller.ex  # Stripe customer portal redirect
    │   └── stripe_webhook_controller.ex # Webhook handler
    ├── templates/
    │   └── email/                 # Email .heex templates (fallback)
    └── router.ex
```

### Key Design Patterns

1. **Phoenix Contexts**: Business logic organized in contexts (Accounts, Scheduler, Resources, Contracts, Settings)
2. **LiveView**: Real-time UI without JavaScript framework
3. **Ecto Schemas**: All database tables have corresponding schemas with changesets
4. **Environment + Database Config**: Critical settings (Stripe, Mailgun) stored in DB with env var fallback
5. **Template Rendering**: Email templates use variable substitution (`{{user.name}}` → actual value)

---

## Feature Status

| Area | Status | Key Files |
|------|--------|-----------|
| **Authentication** | ✅ Done | `accounts/`, `user_auth.ex` |
| **User Invitations** | ✅ Done | `registration_token.ex`, `admin_users_live.ex` |
| **Booking System** | ✅ Done | `scheduler/`, `schedule_*_live.ex` |
| **Resources (Rooms/Desks)** | ✅ Done | `resources/`, `admin_rooms_live.ex` |
| **Amenities** | ✅ Done | `amenity.ex`, `admin_amenities_live.ex` |
| **Mobile Layout** | ✅ Done | `templates/layout/live.html.heex` |
| **Email System** | ✅ Done | `user_notifier.ex`, `templates/email/` |
| **Mailgun Admin** | ✅ Done | `mail_setting.ex`, `admin_settings_live.ex` |
| **Office Spaces (Rental)** | ✅ Done | `spaces_live.ex`, `contracts/` |
| **Stripe Checkout** | ✅ Done | `stripe.ex`, `stripe_webhook_controller.ex` |
| **Stripe Admin** | ✅ Done | `stripe_setting.ex`, `admin_settings_live.ex` |
| **Admin Spaces** | ✅ Done | `admin_spaces_live.ex` |
| **Admin Contracts** | ✅ Done | `admin_contracts_live.ex` |
| **Customer Portal** | ✅ Done | `billing_controller.ex` |
| **Refund Handling** | ✅ Done | `stripe.ex`, `contracts.ex` |
| **Email Template Editor** | ✅ Done | `admin_email_templates_live.ex`, `email_template.ex` |
| **Contract Terms Editor** | ✅ Done | `contract_term.ex`, `admin_settings_live.ex` |

---

## Phase 3: Email Templates + Contract Terms ✅ COMPLETED

### 3.1 Email Template Editor ✅

**Features:**
- Admin UI to customize 6 email types with subject + HTML/text body
- Variable substitution engine (`{{user.name}}`, `{{contract.resource.name}}`, etc.)
- Live preview with sample data
- Reset to default functionality
- "Customized" badge for modified templates

**Email Types:**
1. `welcome` - New user welcome
2. `password_reset` - Password reset instructions
3. `update_email` - Email change confirmation (deprecated in favor of password_reset)
4. `contract_confirmation` - Contract payment successful
5. `contract_cancelled` - Contract cancellation notice
6. `refund_notification` - Refund processed

**Implementation:**
- **Schema:** `settings/email_template.ex` (`template_type`, `subject`, `html_body`, `text_body`, `variables`, `is_custom`)
- **Admin UI:** `/admin/email-templates` (`admin_email_templates_live.ex`)
- **Renderer:** `email_renderer.ex` - Replaces `{{variable}}` with actual values
- **Integration:** `user_notifier.ex` loads from DB, falls back to `.heex` files

### 3.2 Contract Terms Editor ✅

**Features:**
- DB-backed contract terms with automatic versioning
- Admin editor with rich text (HTML) support
- Preview modal
- Reset to default
- Terms displayed at checkout with required acceptance
- Contracts store accepted terms version for compliance

**Implementation:**
- **Schema:** `settings/contract_term.ex` (`content`, `version`, `effective_date`, `is_active`)
- **Versioning:** Auto-increments version when content changes
- **Admin UI:** `/admin/settings` Contract Terms section (`admin_settings_live.ex:346-463`)
- **Checkout:** `spaces_live.ex` shows terms with acceptance checkbox
- **Contract Fields:** `accepted_terms_version`, `terms_accepted_at`
- **Validation:** Checkout button disabled until terms accepted

**Default Terms Content:**
```html
<h2>Office Space Rental Agreement</h2>
<ol>
  <li><strong>Payment:</strong> Payment is due in full at the time of booking.</li>
  <li><strong>Cancellation:</strong> Cancellations within 48 hours are non-refundable.</li>
  <li><strong>Use:</strong> Must comply with building rules.</li>
  <li><strong>Liability:</strong> Responsible for damage during rental.</li>
</ol>
```

---

## Database Schema

### Key Tables

**users** - Authentication
- Standard Phoenix auth fields
- `is_admin` boolean

**bookings** - Short-term reservations
- `resource_id`, `user_id`
- `start_at`, `end_at` (timestamps)

**contracts** - Long-term space rentals
- `resource_id`, `user_id`
- `start_date`, `end_date`, `duration_months` (1 or 3)
- `monthly_rate_cents`, `total_amount_cents`
- `status` (pending, active, cancelled, expired)
- Stripe fields: `stripe_checkout_session_id`, `stripe_payment_intent_id`, `stripe_customer_id`
- Refund fields: `refund_amount_cents`, `refund_id`, `refunded_at`
- Terms fields: `accepted_terms_version`, `terms_accepted_at`

**resources** - Rooms, desks, office spaces
- `name`, `description`, `color`
- `resource_type_id` (room/desk/space)
- `monthly_rate_cents` (for rentable spaces)

**email_templates**
- `template_type` (unique)
- `subject`, `html_body`, `text_body`
- `variables` (array), `is_custom` (boolean)

**contract_terms**
- `content` (HTML), `version`, `effective_date`, `is_active`

**mail_settings** - Singleton
- `enabled`, `mailgun_api_key` (encrypted), `mailgun_domain`
- `from_email`, `from_name`

**stripe_settings** - Singleton
- `enabled`, `environment` (test/live)
- `secret_key` (encrypted), `publishable_key`, `webhook_secret` (encrypted)

---

## Development Workflows

### Making Changes to Features

1. **Schema Changes**
   - Create migration: `mix ecto.gen.migration description`
   - Edit migration file in `priv/repo/migrations/`
   - Run: `mix ecto.migrate`

2. **Adding LiveView Pages**
   - Create in `lib/overbooked_web/live/`
   - Add route in `router.ex` under appropriate `live_session`
   - Use existing pages as templates (e.g., `admin_settings_live.ex`)

3. **Email Changes**
   - Edit default templates in `settings/default_templates.ex`
   - OR customize via admin UI at `/admin/email-templates`
   - Variables defined in `email_template.ex:available_variables/1`

4. **Adding Context Functions**
   - Add public functions to context modules (`Accounts`, `Settings`, etc.)
   - Follow pattern: `get_*`, `list_*`, `create_*`, `update_*`, `delete_*`
   - Use changesets for validation

### Testing Strategy

**Manual Testing Checklist:**
- [ ] Test as admin user (is_admin: true)
- [ ] Test as regular user (is_admin: false)
- [ ] Test Stripe webhooks with Stripe CLI: `stripe listen --forward-to localhost:4000/webhooks/stripe`
- [ ] Test emails via `/dev/mailbox` (development) or send test email in admin settings

**Database Reset:**
```bash
mix ecto.reset  # Drops DB, recreates, runs migrations + seeds
```

---

## Environment Variables

### Required

```bash
SECRET_KEY_BASE=...        # Generate with: mix phx.gen.secret
DATABASE_URL=postgres://...
PHX_HOST=your-domain.com
PHX_SERVER=true
```

### Optional (Fallback to DB Config)

```bash
# Stripe - configure in DB via /admin/settings instead
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Mailgun - configure in DB via /admin/settings instead
MAILGUN_API_KEY=key-...
MAILGUN_DOMAIN=mg.yourdomain.com
```

**Note:** Stripe and Mailgun can be configured entirely through the admin UI. Environment variables are used as fallback if DB config is disabled.

---

## Key Conventions for AI Assistants

### When Modifying Code

1. **Always Read First**: Use `Read` tool before suggesting changes to files
2. **Follow Existing Patterns**:
   - Contexts for business logic (`lib/overbooked/`)
   - LiveViews for UI (`lib/overbooked_web/live/`)
   - Schemas always use changesets for validation
3. **Changesets Over Raw Updates**: Never bypass Ecto changesets
4. **Encrypted Secrets**: API keys stored in DB use `encode_key/decode_key` functions
5. **Admin vs User**: Check `@current_user.is_admin` for admin-only features

### Schema Naming

- **Avoid conflicts:** Don't use field names that match `belongs_to` associations
  - ❌ Bad: `:resource_type` field when `belongs_to :resource_type` exists
  - ✅ Good: `:resource_type_name` or use the association directly

### LiveView Patterns

**Mount Pattern:**
```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(data: get_data())
   |> assign(changeset: changeset())}
end
```

**Form Pattern:**
```elixir
<.form :let={f} for={@changeset} phx-change="validate" phx-submit="save">
  <.text_input form={f} field={:name} />
  <.error form={f} field={:name} />
  <.button type="submit">Save</.button>
</.form>
```

### Stripe Integration

**Checkout Flow:**
1. User clicks "Proceed to Payment" → `handle_event("checkout", ...)`
2. Create contract record with `status: :pending`
3. Create Stripe checkout session via `Overbooked.Stripe.create_checkout_session/1`
4. Redirect to Stripe hosted page
5. User pays → Stripe sends webhook to `/webhooks/stripe`
6. Webhook handler updates contract to `status: :active`
7. User redirected to `/contracts/success`

**Customer Portal:**
- Route: `/billing` → `BillingController.portal/2`
- Creates Stripe portal session for subscription management
- Redirects to Stripe hosted portal

### Email Rendering

**Variable Substitution:**
```elixir
# Template: "Hello {{user.name}}, your contract for {{contract.resource.name}}..."
# Assigns: %{user: %{name: "Alice"}, contract: %{resource: %{name: "Office 1"}}}
# Result: "Hello Alice, your contract for Office 1..."

EmailRenderer.render(template_body, assigns)
```

**Available Variables by Template:**
- `welcome`: `user.name`, `user.email`
- `password_reset`: `user.name`, `reset_url`, `expires_in`
- `contract_confirmation`: `user.name`, `contract.resource.name`, `contract.start_date`, `contract.end_date`, `contract.duration_months`, `contract.total_amount`, `receipt_url`
- `contract_cancelled`: `user.name`, `contract.resource.name`, `contract.end_date`, `refund_info`
- `refund_notification`: `user.name`, `contract.resource.name`, `refund_amount`, `refund_date`

---

## Brand Assets

- **Logo:** `priv/static/images/hatchbridge-logo.svg`, `logo.png`
- **Colors:**
  - Yellow: `#FFC421`
  - Blue: `#2153FF` (primary)
  - Dark: `#000824`
- **Font:** Nunito Sans
- **Tailwind Config:** Uses custom primary color classes

---

## Common Tasks

### Adding a New Admin Setting

1. Add field to appropriate setting schema (e.g., `MailSetting`)
2. Update changeset in schema
3. Add form field in `admin_settings_live.ex`
4. Update context functions in `settings.ex`
5. Test via `/admin/settings`

### Adding a New Email Type

1. Add template type to `EmailTemplate.template_types/0`
2. Add default content to `DefaultTemplates.default_*`
3. Define variables in `EmailTemplate.available_variables/1`
4. Add sender function in `UserNotifier`
5. Call from appropriate context

### Debugging Stripe Webhooks

```bash
# Terminal 1: Start server
mix phx.server

# Terminal 2: Forward webhooks
stripe listen --forward-to localhost:4000/webhooks/stripe

# Terminal 3: Trigger test event
stripe trigger checkout.session.completed
```

**Check webhook logs:** `lib/overbooked_web/controllers/stripe_webhook_controller.ex`

---

## Known Issues & Gotchas

### Form Field vs Association Conflict
When using form fields, avoid names that match `belongs_to` associations. Phoenix will try to render the unloaded association, causing errors.

**Example:**
```elixir
# Schema has: belongs_to :resource_type, ResourceType
# ❌ Don't do: field :resource_type, :string
# ✅ Do: field :resource_type_name, :string
```

### Stripe Test Mode
- Always use test mode during development
- Test cards: `4242 4242 4242 4242` (any future date, any CVC)
- Configure via `/admin/settings` or `STRIPE_SECRET_KEY` env var

### Email Delivery
- Development: Emails go to `/dev/mailbox` (Swoosh preview)
- Production: Requires Mailgun API key configured in `/admin/settings`

### Migration Failures
If migration fails partway:
1. Connect to DB: `psql $DATABASE_URL` or Railway dashboard
2. Drop incomplete tables: `DROP TABLE IF EXISTS table_name;`
3. Remove from tracking: `DELETE FROM schema_migrations WHERE version = 'YYYYMMDDHHMMSS';`
4. Rerun: `mix ecto.migrate`

---

## Reference Links

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Ecto](https://hexdocs.pm/ecto)
- [Stripe Checkout](https://stripe.com/docs/checkout/quickstart)
- [Stripe Webhooks](https://stripe.com/docs/webhooks)
- [Stripe Customer Portal](https://stripe.com/docs/billing/subscriptions/customer-portal)
- [stripity_stripe (Elixir client)](https://hexdocs.pm/stripity_stripe)
- [Swoosh (Email)](https://hexdocs.pm/swoosh)
- [Tailwind CSS](https://tailwindcss.com/)

---

## Next Steps / Future Enhancements

### High Priority (High Impact, Moderate Effort)

These features provide significant value to users and space owners with reasonable implementation complexity.

1. **Email Notifications** 📧
   - Booking reminders (1 day before, 1 hour before)
   - Contract expiration warnings (30 days, 7 days before)
   - New booking confirmations
   - **Impact:** Reduces no-shows, improves user engagement
   - **Complexity:** Low - leverages existing email system
   - **Dependencies:** None

2. **Analytics Dashboard** 📊
   - Contract revenue tracking and forecasting
   - Space utilization rates (% booked vs. available)
   - Popular resources and peak usage times
   - Monthly/quarterly reports
   - **Impact:** Business intelligence for space owners, data-driven decisions
   - **Complexity:** Medium - requires aggregation queries and charts
   - **Dependencies:** None

3. **Recurring Bookings** 🔁
   - Weekly/daily booking patterns (e.g., "every Monday 9am-5pm")
   - Bulk booking creation
   - Exception handling (skip holidays)
   - **Impact:** Reduces friction for regular users, increases bookings
   - **Complexity:** Medium - need recurring pattern logic
   - **Dependencies:** None

4. **Availability Search** 🔍
   - Search by date range, amenities, capacity
   - Filter by resource type
   - "Find me a desk with monitor on Friday"
   - **Impact:** Improves user experience, reduces booking time
   - **Complexity:** Medium - search UI + query optimization
   - **Dependencies:** Resource Capacity (optional but complementary)

### Medium Priority (Good Value, Higher Effort)

Features that add value but require more significant development effort.

5. **Google Calendar Sync** 📅
   - 2-way sync: bookings ↔ Google Calendar
   - OAuth integration
   - Conflict detection
   - **Impact:** Helps users manage schedules, reduces double-bookings
   - **Complexity:** High - OAuth, API integration, sync logic
   - **Dependencies:** None

6. **Resource Images** 🖼️
   - Photo galleries for spaces/rooms/desks
   - Image upload and management
   - Thumbnail generation
   - Display in browsing views
   - **Impact:** Better user decision-making, more professional appearance
   - **Complexity:** Medium - file uploads, storage, image processing
   - **Dependencies:** None

7. **Discount Codes** 💰
   - Promo codes for contracts (% off or fixed amount)
   - Code management (expiration, usage limits)
   - Stripe coupon integration
   - **Impact:** Marketing tool, customer acquisition
   - **Complexity:** Medium - Stripe integration, validation logic
   - **Dependencies:** None

8. **CSV Import/Export** 📁
   - Bulk import/export for resources, users, bookings
   - Data backup and migration
   - Template downloads
   - **Impact:** Easier data management, onboarding
   - **Complexity:** Medium - CSV parsing, validation, error handling
   - **Dependencies:** None

### Lower Priority (Nice-to-Have)

Features that add value in specific scenarios or for scaling.

9. **Resource Capacity** 👥
   - Support for multi-person spaces (meeting rooms, hot desks)
   - Track current occupancy vs. max capacity
   - Partial booking support
   - **Impact:** Enables new use cases (meeting rooms, shared spaces)
   - **Complexity:** Medium - schema changes, booking logic updates
   - **Dependencies:** Would enhance Availability Search

10. **Payment Plans** 💳
    - Monthly installments for 3+ month contracts
    - Stripe subscription integration
    - Auto-renewal options
    - **Impact:** Reduces barrier for long-term contracts
    - **Complexity:** High - Stripe subscriptions, payment tracking, failed payment handling
    - **Dependencies:** None

11. **Amenity Quantities** 🔢
    - Track available vs. total amenities (e.g., 5 monitors, 3 in use)
    - Real-time availability
    - Booking-amenity linkage
    - **Impact:** Better resource management for limited amenities
    - **Complexity:** Medium - inventory tracking, availability checks
    - **Dependencies:** None

12. **Booking Analytics** 📈
    - User activity reports
    - Most booked times/resources
    - User engagement metrics
    - **Impact:** Business insights, identifies trends
    - **Complexity:** Low-Medium - extends Analytics Dashboard
    - **Dependencies:** Analytics Dashboard

13. **Multi-tenancy** 🏢
    - Support multiple coworking locations
    - Per-location admin controls
    - Location-specific resources and pricing
    - **Impact:** Enables scaling to multiple sites
    - **Complexity:** Very High - major architectural change
    - **Dependencies:** Significant refactoring required

---

### Recommended Roadmap

**Phase 4 (Q1):** Email Notifications + Analytics Dashboard
- Quick wins with high user and business value
- Builds on existing email infrastructure

**Phase 5 (Q2):** Recurring Bookings + Availability Search
- Major UX improvements
- Complementary features that work well together

**Phase 6 (Q3+):** Google Calendar Sync, Resource Images, Discount Codes
- Polish and marketing features
- Evaluate based on user feedback from Phases 4-5

---

## Deployment

### Railway (Recommended)

**Setup:**
1. Create Railway project with PostgreSQL
2. Connect GitHub repo
3. Set environment variables (see Environment Variables section)
4. Deploy - migrations run automatically via `railway.json`

**Important:** If deploying to a new environment, run seeds to create admin user:
```bash
railway run mix run priv/repo/seeds.exs
```

### Other Platforms

Works on any platform supporting Phoenix + PostgreSQL:
- Fly.io
- Render
- Heroku
- Docker (see `Dockerfile`)

**Requirements:**
- PostgreSQL 12+
- Elixir 1.14+
- Erlang 24+
- Node.js (for asset compilation)

---

## Getting Help

- **Documentation:** https://overbookedapp.gitbook.io/docs/
- **Issues:** Check git history for similar problems
- **Code Examples:** Look at existing LiveView modules for patterns
- **Admin UI:** Many features configurable at runtime via `/admin/*` routes

---

*Last Updated: 2024-12-21*
*Status: Phase 3 Complete (Email Template Editor + Contract Terms Editor)*
