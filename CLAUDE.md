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

---

## Work To Do

### Phase 3.5: Admin Navigation UX Refactor (PLANNED)

**Problem:** Current admin navigation uses horizontal tabs that require horizontal scrolling on mobile.

**Solution:** Responsive navigation with three breakpoints:
- **Mobile (< 768px):** Grouped dropdown with `<optgroup>` labels
- **Tablet (768px - 1024px):** Vertical sidebar with grouped sections
- **Desktop (> 1024px):** Enhanced horizontal tabs

**Logical Grouping:**
| Group | Items |
|-------|-------|
| People | Users, Contracts |
| Spaces | Rooms, Desks, Amenities, Office Spaces |
| Configuration | Settings, Email Templates |

**Files to Modify:** `lib/overbooked_web/live/live_helpers.ex` (tabs component at line 753-767)

### Future Phases (Prioritized)

**Phase 4 - High Priority:**
1. Email Notifications (booking reminders, contract expiration warnings)
2. Analytics Dashboard (revenue tracking, space utilization)

**Phase 5 - Medium Priority:**
3. Recurring Bookings (weekly/daily patterns)
4. Availability Search (by date, amenities, capacity)

**Phase 6 - Lower Priority:**
5. Google Calendar Sync
6. Resource Images
7. Discount Codes
8. CSV Import/Export

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
│   ├── stripe.ex                  # Stripe API integration
│   └── email_renderer.ex          # Template variable substitution
│
└── overbooked_web/                # Web layer
    ├── live/                      # LiveView modules
    │   ├── admin/                 # Admin-only pages
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

**Cause:** iOS Safari calculates intrinsic width based on the selected option's text length, which can override CSS `width` properties.

**Fix:** Use both `w-full` and `min-w-full` on the select element:
```html
<!-- w-full alone is not sufficient on iOS Safari -->
<select class="block w-full min-w-full ...">
```

Also ensure all parent container divs have explicit `w-full` to guarantee width inheritance through the DOM hierarchy.

**File fixed:** `lib/overbooked_web/live/live_helpers.ex` (admin_tabs and admin_nav_mobile)

---

## Reference Links

- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Stripe Checkout](https://stripe.com/docs/checkout/quickstart)
- [stripity_stripe](https://hexdocs.pm/stripity_stripe)
- [Swoosh (Email)](https://hexdocs.pm/swoosh)

---

*Last Updated: 2024-12-21*
*Status: Phase 3 Complete, Phase 3.5 Planned*
