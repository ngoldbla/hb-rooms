# Phase 4-5 Feature Development Tracking

**Started:** 2024-12-21
**Status:** Planning Phase
**Branch:** `claude/plan-phase-4-5-features-0ucmN`

---

## Team Assembly

For each feature, we'll engage specialized expertise:

| Expert Role | Domain | Features |
|-------------|--------|----------|
| **Backend Architect** | Elixir/OTP, Oban, Ecto | Email Notifications, Recurring Bookings |
| **Data Engineer** | Ecto Queries, Analytics | Analytics Dashboard, Availability Search |
| **Frontend Specialist** | LiveView, Tailwind, JS Hooks | All UI Components |
| **DevOps/Integration** | Config, Migrations, Testing | All Features |

---

## Current Infrastructure Assessment

### ✅ Already Implemented
- [x] Swoosh email system with Mailgun adapter
- [x] DB-customizable email templates (6 types)
- [x] Email variable substitution engine (`EmailRenderer`)
- [x] Booking system with conflict detection
- [x] Contract lifecycle management
- [x] Stripe payments and webhooks
- [x] Contract terms versioning
- [x] Admin panel with settings UI

### ❌ Not Yet Implemented (Required for Phase 4+)
- [ ] **Oban** - Job queue for async/scheduled tasks
- [ ] Analytics data aggregation queries
- [ ] Recurring booking patterns
- [ ] Advanced availability search

---

## Phase 4: High Priority

### 4.1 Email Notifications (Oban + Swoosh)

**Goal:** Automated booking reminders and contract expiration warnings

#### Step 1: Oban Setup & Configuration
- [ ] Add `oban ~> 2.18` to `mix.exs`
- [ ] Configure Oban in `config/config.exs` with Postgres queue
- [ ] Create migration for `oban_jobs` table
- [ ] Add Oban.Telemetry for observability
- [ ] Configure queues: `default`, `notifications`, `scheduled`

#### Step 2: Notification Worker Architecture
- [ ] Create `Overbooked.Workers.EmailWorker` module
- [ ] Pattern match on job types:
  - `:booking_reminder` (24h before)
  - `:booking_morning_reminder` (morning of)
  - `:contract_expiration_warning` (7 days before)
  - `:contract_expired` (on expiration)
- [ ] Implement idempotency (track `reminder_sent` on bookings)
- [ ] Add retry logic with exponential backoff

#### Step 3: Email Templates (New Types)
- [ ] Add `booking_reminder` template type
- [ ] Add `contract_expiration_warning` template type
- [ ] Create default template content in `default_templates.ex`
- [ ] Add to admin email template editor

#### Step 4: Scheduling Logic
- [ ] Create `Overbooked.Workers.NotificationSweeper` Oban.Cron job
- [ ] Run hourly: query bookings starting in 24h where `reminder_sent: false`
- [ ] Run daily: query contracts expiring in 7 days
- [ ] Insert jobs atomically with Ecto.Multi

#### Step 5: Schema Updates
- [ ] Add `reminder_sent` boolean to `bookings` table
- [ ] Add `expiration_warning_sent` boolean to `contracts` table
- [ ] Create migrations

#### Step 6: Testing & Validation
- [ ] Write unit tests for workers
- [ ] Write integration tests with Oban.Testing
- [ ] Test idempotency (same job doesn't duplicate)
- [ ] Verify Mailgun delivery in staging

**Files to Create/Modify:**
```
lib/overbooked/workers/email_worker.ex (new)
lib/overbooked/workers/notification_sweeper.ex (new)
lib/overbooked/scheduler/booking.ex (add reminder_sent)
lib/overbooked/contracts/contract.ex (add warning_sent)
lib/overbooked/settings/default_templates.ex (new templates)
config/config.exs (Oban config)
priv/repo/migrations/XXXX_add_oban_jobs_table.exs
priv/repo/migrations/XXXX_add_notification_tracking_fields.exs
```

---

### 4.2 Analytics Dashboard

**Goal:** Revenue tracking and space utilization metrics

#### Step 7: Analytics Context
- [ ] Create `Overbooked.Analytics` context module
- [ ] Implement revenue queries:
  - `monthly_revenue(year, month)` - from contracts
  - `revenue_by_resource(start_date, end_date)`
  - `revenue_trend(months)` - for charting
- [ ] Implement utilization queries:
  - `space_utilization(resource, start_date, end_date)`
  - Formula: `booked_minutes / available_minutes`
  - Use `date_trunc` for grouping

#### Step 8: Analytics LiveView
- [ ] Create `AdminAnalyticsLive` in `/admin/analytics`
- [ ] Add date range filter (Today, Week, Month, Custom)
- [ ] Handle URL query params for shareable links
- [ ] Display KPI cards: Total Revenue, Utilization %, Active Contracts

#### Step 9: Charting Integration
- [ ] Add Chart.js via CDN or npm
- [ ] Create `ChartHook` LiveView hook
- [ ] Use `push_event` to send data to hook
- [ ] Implement revenue line chart
- [ ] Implement utilization bar chart per resource

#### Step 10: Admin Navigation Update
- [ ] Add "Analytics" tab to admin nav
- [ ] Add analytics route to router

**Files to Create/Modify:**
```
lib/overbooked/analytics.ex (new)
lib/overbooked_web/live/admin/admin_analytics_live.ex (new)
assets/js/hooks/chart_hook.js (new)
assets/js/app.js (register hook)
lib/overbooked_web/router.ex (add route)
lib/overbooked_web/nav.ex (add nav item)
```

---

## Phase 5: Medium Priority

### 5.1 Recurring Bookings

**Goal:** Support weekly/daily booking patterns

#### Step 11: RecurringRule Schema
- [ ] Create `recurring_rules` table:
  - `pattern` enum: `:daily`, `:weekly`, `:biweekly`, `:monthly`
  - `interval` integer (e.g., every 2 weeks)
  - `days_of_week` array (for weekly: [1,3,5] = Mon/Wed/Fri)
  - `end_date` or `occurrences` limit
  - `belongs_to :user`
  - `belongs_to :resource`
- [ ] Add `recurring_rule_id` foreign key to `bookings`

#### Step 12: Expansion Service
- [ ] Create `Overbooked.Scheduler.RecurringExpander` module
- [ ] Use Timex to calculate occurrence dates
- [ ] Return list of booking attributes
- [ ] Validate all occurrences don't conflict

#### Step 13: Atomic Creation
- [ ] Use `Ecto.Multi` to insert rule + all bookings
- [ ] Rollback entire series on any conflict
- [ ] Return meaningful error for conflict (which date?)

#### Step 14: Recurring Booking UI
- [ ] Add "Repeat" option to booking form
- [ ] Show pattern selector (weekly, daily, etc.)
- [ ] Day-of-week checkboxes for weekly
- [ ] End date or occurrence count
- [ ] Preview generated dates before confirm

#### Step 15: Series Management
- [ ] "Edit all future" vs "Edit this only" choice
- [ ] "Cancel series" with confirmation
- [ ] Visual indicator for recurring bookings on calendar

**Files to Create/Modify:**
```
lib/overbooked/scheduler/recurring_rule.ex (new)
lib/overbooked/scheduler/recurring_expander.ex (new)
lib/overbooked/scheduler/booking.ex (add recurring_rule_id)
lib/overbooked/scheduler.ex (recurring functions)
lib/overbooked_web/live/scheduler/calendar_live.ex (UI)
priv/repo/migrations/XXXX_create_recurring_rules.exs
priv/repo/migrations/XXXX_add_recurring_to_bookings.exs
```

---

### 5.2 Availability Search

**Goal:** Find available resources by date, amenities, and capacity

#### Step 16: Search Query Logic
- [ ] Create `Overbooked.Resources.AvailabilitySearch` module
- [ ] Build "gap" query using `NOT EXISTS` for overlapping bookings
- [ ] Filter by:
  - Date/time range
  - Resource type (room/desk)
  - Minimum capacity (future schema addition)
  - Amenities (using `@>` jsonb or join)
- [ ] Return available resources with availability windows

#### Step 17: Performance Indexes
- [ ] Add index on `bookings.start_at`
- [ ] Add index on `bookings.end_at`
- [ ] Add composite index `(resource_id, start_at, end_at)`
- [ ] Add GIN index on amenities if using JSONB

#### Step 18: Search LiveView
- [ ] Create `SearchLive` at `/search`
- [ ] Side panel with filters
- [ ] Use `phx-change` for live updates
- [ ] Display matching resources with availability
- [ ] Click to book from results

#### Step 19: Capacity Field (Optional)
- [ ] Add `capacity` integer to `resources` table
- [ ] Add to admin room/desk forms
- [ ] Include in search filters

**Files to Create/Modify:**
```
lib/overbooked/resources/availability_search.ex (new)
lib/overbooked_web/live/search_live.ex (new)
lib/overbooked_web/router.ex (add route)
priv/repo/migrations/XXXX_add_booking_indexes.exs
priv/repo/migrations/XXXX_add_resource_capacity.exs (optional)
```

---

## Progress Log

### 2024-12-21
- [x] Initial codebase exploration completed
- [x] Created todos.md tracking document
- [ ] Begin Phase 4.1: Email Notifications

---

## Execution Order

1. **Phase 4.1** - Email Notifications (Oban foundation enables future scheduled tasks)
2. **Phase 4.2** - Analytics Dashboard (provides business value quickly)
3. **Phase 5.1** - Recurring Bookings (complex but high user value)
4. **Phase 5.2** - Availability Search (depends on indexes from recurring work)

---

## Testing Strategy

Each feature should include:
- [ ] Unit tests for context functions
- [ ] Integration tests for LiveView
- [ ] Migration rollback testing
- [ ] Manual QA checklist

---

*Last Updated: 2024-12-21*
