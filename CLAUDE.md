# Hatchbridge Rooms - AI Assistant Guide

## Project Overview

**Name:** Overbooked (branded as Hatchbridge Rooms)
**Stack:** Phoenix 1.6.6 + LiveView 0.18 + Tailwind CSS + PostgreSQL + Swoosh (Mailgun) + Stripe
**Purpose:** Self-hosted coworking space management platform for indie co-working owners
**Language:** Elixir 1.14+

---

## Work Completed

### Phase 1-2: Core Platform (DONE)

| Feature | Status | Key Files |
|---------|--------|-----------|
| Authentication | ✅ | `accounts/`, `user_auth.ex` |
| User Invitations | ✅ | `registration_token.ex`, `admin_users_live.ex` |
| Booking System | ✅ | `scheduler/`, `schedule_*_live.ex` |
| Resources (Rooms/Desks) | ✅ | `resources/`, `admin_rooms_live.ex` |
| Amenities | ✅ | `amenity.ex`, `admin_amenities_live.ex` |
| Mobile Layout | ✅ | `templates/layout/live.html.heex` |
| Email System | ✅ | `user_notifier.ex`, `templates/email/` |
| Mailgun Admin | ✅ | `mail_setting.ex`, `admin_settings_live.ex` |
| Office Spaces (Rental) | ✅ | `spaces_live.ex`, `contracts/` |
| Stripe Checkout | ✅ | `stripe.ex`, `stripe_webhook_controller.ex` |
| Stripe Admin | ✅ | `stripe_setting.ex`, `admin_settings_live.ex` |
| Admin Spaces | ✅ | `admin_spaces_live.ex` |
| Admin Contracts | ✅ | `admin_contracts_live.ex` |
| Customer Portal | ✅ | `billing_controller.ex` |
| Refund Handling | ✅ | `stripe.ex`, `contracts.ex` |

### Phase 3: Email Templates + Contract Terms (DONE)

**3.1 Email Template Editor**
- Admin UI to customize 6 email types with subject + HTML/text body
- Variable substitution engine (`{{user.name}}`, `{{contract.resource.name}}`, etc.)
- Live preview, reset to default, "Customized" badge
- Files: `admin_email_templates_live.ex`, `email_template.ex`, `email_renderer.ex`

**3.2 Contract Terms Editor**
- DB-backed contract terms with automatic versioning
- Admin editor with rich text (HTML) support
- Terms displayed at checkout with required acceptance
- Contracts store accepted terms version for compliance
- Files: `contract_term.ex`, `admin_settings_live.ex`

Phase 3.5: Admin Navigation UX Refactor (Complete)

**Implementation TODOs:**
- [x] Replace `admin_nav_mobile/1` with custom dropdown component
- [x] Add `get_nav_label/1` helper function for tab labels
- [x] Ensure accessibility (ARIA attributes, keyboard support)
- [x] Test on iOS Safari, Android Chrome, desktop browsers
- [x] Commit and push

### Phase 4: Email Notifications + Analytics (DONE)

**4.1 Email Notifications (Oban + Background Jobs)**
- Oban 2.17 for job queue and cron scheduling
- Booking reminder emails (24h before booking start)
- Contract expiration warnings (7 days before expiry)
- Notification sweeper cron job (runs every 15 minutes)
- Two new email template types with admin customization
- Idempotency tracking via timestamps
- Files: `workers/`, `analytics.ex`, `admin_analytics_live.ex`

**4.2 Analytics Dashboard**
- Revenue tracking (monthly, by resource, trends)
- Space utilization metrics (per resource and overall)
- Chart.js integration with LiveView hooks
- Date range filters (Today, 7/30/90 days, Custom)
- KPI cards with real-time data
- URL-shareable analytics with query params
- Files: `analytics.ex`, `admin_analytics_live.ex`, `assets/js/hooks/charts.js`

### Phase 5: Recurring Bookings + Availability Search (IN PROGRESS)

**5.1 Recurring Bookings (Backend Complete)**
- RecurringRule schema with pattern validation (daily/weekly/biweekly/monthly)
- RecurringExpander service for date calculation using Timex
- Ecto.Multi atomic creation with conflict detection
- Series management functions (delete single occurrence, delete series)
- Files: `scheduler/recurring_rule.ex`, `scheduler/recurring_expander.ex`, `scheduler.ex`

**5.2 Availability Search (Backend Complete)**
- AvailabilitySearch module with NOT EXISTS queries
- SearchLive at `/search` with filters (date, time, type, capacity, amenities)
- Performance indexes on bookings table
- Capacity field added to resources
- Files: `resources/availability_search.ex`, `search_live.ex`

**Remaining UI Work:**
- Recurring booking UI in calendar forms
- Visual indicator for recurring bookings
- Capacity field in admin forms

### Future Phases (Prioritized)

**Phase 6 - Lower Priority:**
1. Google Calendar Sync
2. Resource Images
3. Discount Codes
4. CSV Import/Export

---

## Architecture Quick Reference

```
lib/
├── overbooked/                    # Business logic contexts
│   ├── accounts/                  # User auth & management
│   ├── scheduler/                 # Booking system
│   ├── resources/                 # Rooms, desks, amenities
│   ├── contracts/                 # Long-term space rentals
│   ├── settings/                  # App configuration
│   ├── workers/                   # Oban background jobs
│   │   ├── booking_reminder_worker.ex
│   │   ├── contract_expiration_worker.ex
│   │   └── notification_sweeper.ex
│   ├── analytics.ex               # Revenue & utilization queries
│   ├── stripe.ex                  # Stripe API integration
│   └── email_renderer.ex          # Template variable substitution
│
└── overbooked_web/                # Web layer
    ├── live/                      # LiveView modules
    │   ├── admin/                 # Admin-only pages
    │   │   ├── admin_analytics_live.ex
    │   │   └── ...
    │   ├── scheduler/             # Calendar views
    │   └── user/                  # Auth pages
    ├── controllers/
    │   ├── billing_controller.ex  # Stripe customer portal
    │   └── stripe_webhook_controller.ex
    └── router.ex
```

---

## Key Conventions

### LiveView Patterns

**Slots must be direct children of components.** Use `:if` attribute for conditional slots:
```elixir
# ✅ Correct
<:confirm :if={not @older}>Book</:confirm>

# ❌ Wrong - causes ParseError
<%= unless @older do %>
  <:confirm>Book</:confirm>
<% end %>
```

**Schema naming:** Don't use field names that match `belongs_to` associations:
```elixir
# Schema has: belongs_to :resource_type, ResourceType
# ❌ Bad: field :resource_type, :string
# ✅ Good: field :resource_type_name, :string
```

### Stripe Integration

1. User clicks "Proceed to Payment" → creates pending contract
2. Redirect to Stripe hosted checkout
3. Webhook updates contract to active on success
4. Test card: `4242 4242 4242 4242`

### Email Rendering

Variables use `{{dot.notation}}` syntax:
- `welcome`: `user.name`, `user.email`
- `contract_confirmation`: `user.name`, `contract.resource.name`, `contract.total_amount`

---

## Environment Variables

```bash
# Required
SECRET_KEY_BASE=...
DATABASE_URL=postgres://...
PHX_HOST=your-domain.com
PHX_SERVER=true

# Optional (can configure via /admin/settings instead)
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
MAILGUN_API_KEY=key-...
MAILGUN_DOMAIN=mg.yourdomain.com
```

---

## Deployment

**Railway (Recommended):**
1. Create Railway project with PostgreSQL
2. Connect GitHub repo
3. Set environment variables
4. Deploy - migrations run automatically

**Other Platforms:** Fly.io, Render, Heroku, Docker

---

## Known Issues & Gotchas

### LiveView Slot Conditional Error (Fixed 2024-12-21)

**Issue:** `Phoenix.LiveView.HTMLTokenizer.ParseError: invalid slot entry <:confirm>. A slot entry must be a direct child of a component`

**Cause:** Slot entries wrapped in EEx conditionals like `<%= if/unless %>` are invalid in LiveView 0.18.

**Fix:** Use the `:if` attribute on the slot itself:
```elixir
# Before (broken)
<%= unless @older do %>
  <:confirm>Book</:confirm>
<% end %>

# After (fixed)
<:confirm :if={not @older}>Book</:confirm>
```

**File fixed:** `lib/overbooked_web/live/scheduler/calendar_live.ex:297`

### Stripe Test Mode
- Always use test mode during development
- Configure via `/admin/settings` or `STRIPE_SECRET_KEY` env var

### Email Delivery
- Development: Emails go to `/dev/mailbox` (Swoosh preview)
- Production: Requires Mailgun API key in `/admin/settings`

### Migration Failures
If migration fails partway:
1. Connect to DB and drop incomplete tables
2. Remove from `schema_migrations`: `DELETE FROM schema_migrations WHERE version = 'YYYYMMDDHHMMSS';`
3. Rerun: `mix ecto.migrate`

### iOS Safari Select Element Width (Fixed 2024-12-21)

**Issue:** Native `<select>` elements shrink to fit the selected option text on iOS Safari, even with `width: 100%`.

**Cause:** iOS Safari calculates intrinsic width based on the selected option's text length. CSS `width` and `min-width` properties cannot reliably override this browser behavior.

**Fix:** Replace native `<select>` with a custom button-triggered dropdown:
- Use a `<button>` element as the trigger (respects CSS width)
- Display dropdown panel with grouped options
- Current selection shown with checkmark indicator
- Proper ARIA attributes for accessibility

**Implementation details:**
- `admin_nav_mobile/1` - Custom dropdown component
- `mobile_nav_option/1` - Individual option component
- `get_nav_label/1` - Helper to get display label for tab

### Oban/Ecto Dependency Compatibility (Fixed 2024-12-21)

**Issue:** Railway deployment failed during `mix deps.compile` with:
```
** (FunctionClauseError) no function clause matching in Ecto.Query.with_cte/3
    (ecto 3.9.1) expanding macro: Ecto.Query.with_cte/3
    lib/oban/engines/basic.ex:107
```

**Cause:** Oban 2.17.4 (added for Phase 4 background jobs) requires **Ecto 3.10+** because it uses `Ecto.Query.with_cte/3` which was introduced in Ecto 3.10. The project had `{:ecto_sql, "~> 3.6"}` which resolved to Ecto 3.9.1.

**Fix:** Update `mix.exs` dependency:
```elixir
# Changed from:
{:ecto_sql, "~> 3.6"}

# To:
{:ecto_sql, "~> 3.10"}
```

**Impact:** Ecto 3.10 is backward compatible with Phoenix 1.6.6 and all existing code.

---

## Reference Links

- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Stripe Checkout](https://stripe.com/docs/checkout/quickstart)
- [stripity_stripe](https://hexdocs.pm/stripity_stripe)
- [Swoosh (Email)](https://hexdocs.pm/swoosh)

---

*Last Updated: 2024-12-21*
*Status: Phase 4 Complete (Email Notifications + Analytics Dashboard), Phase 5-6 Planned*
