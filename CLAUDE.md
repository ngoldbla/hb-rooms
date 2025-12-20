# Hatchbridge Rooms - Agent Implementation Guide

## Project Overview

**Stack:** Phoenix 1.7 + LiveView + Tailwind CSS + PostgreSQL + Swoosh (Mailgun)
**Purpose:** Self-hosted coworking space management platform
**Goal:** Transform into world-class visitor management system (Envoy-like experience)

## Current State Summary

| Area | Status | Key Files |
|------|--------|-----------|
| Mobile Layout | ✅ **COMPLETED** - Hamburger menu + responsive layout | `lib/overbooked_web/templates/layout/live.html.heex` |
| Email System | ✅ **COMPLETED** - Multipart HTML+text emails | `lib/overbooked/accounts/user_notifier.ex`, `lib/overbooked_web/templates/email/` |
| Mobile Components | ✅ **COMPLETED** - Card list + touch-friendly UI | `lib/overbooked_web/live/live_helpers.ex` |
| Check-in | 📋 Not started - Time-based bookings only | `lib/overbooked/scheduler/booking.ex` |

### Phase 1 Implementation Status

**Phase 1: Mobile Layout + Email Foundation** ✅ **COMPLETED**

All Phase 1 tasks have been implemented:
- ✅ 1.1 Mobile Sidebar (Hamburger Menu)
- ✅ 1.2 Mobile-Friendly Components
- ✅ 1.3 HTML Email Templates

Committed to branch: `claude/summarize-claude-phases-ffsVA`

## Brand Assets

- **Logo SVG:** `priv/static/images/hatchbridge-logo.svg`
- **Logo PNG:** `priv/static/images/logo.png`
- **Primary Yellow:** `#FFC421`
- **Secondary Blue:** `#2153FF`
- **Dark Blue:** `#000824`
- **Font:** Nunito Sans

---

# Phase 1: Mobile Layout + Email Foundation

## 1.1 Mobile Sidebar (Hamburger Menu)

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 1.1.1 | Add AlpineJS sidebar state to layout | `live.html.heex` | `x-data` attribute present on wrapper |
| 1.1.2 | Create mobile header with hamburger button | `live.html.heex` | Button visible at `< lg` breakpoint |
| 1.1.3 | Wrap existing sidebar in mobile drawer | `live.html.heex` | Sidebar hidden on mobile, visible on lg+ |
| 1.1.4 | Add backdrop overlay when drawer open | `live.html.heex` | Gray overlay appears, click closes |
| 1.1.5 | Add slide transition animations | `app.css` | Smooth 300ms slide-in animation |
| 1.1.6 | Add escape key handler to close drawer | `live.html.heex` | Press ESC closes sidebar |
| 1.1.7 | Add swipe-to-close gesture (optional) | `app.js` | Swipe left closes drawer |

### Implementation Pattern

```html
<!-- live.html.heex - Mobile wrapper structure -->
<div x-data="{ sidebarOpen: false }" class="flex h-screen overflow-hidden">

  <!-- Mobile backdrop -->
  <div
    x-show="sidebarOpen"
    x-transition:enter="transition-opacity ease-linear duration-300"
    x-transition:enter-start="opacity-0"
    x-transition:enter-end="opacity-100"
    x-transition:leave="transition-opacity ease-linear duration-300"
    x-transition:leave-start="opacity-100"
    x-transition:leave-end="opacity-0"
    class="fixed inset-0 z-40 bg-gray-600 bg-opacity-75 lg:hidden"
    @click="sidebarOpen = false"
  ></div>

  <!-- Mobile sidebar -->
  <div
    x-show="sidebarOpen"
    x-transition:enter="transition ease-in-out duration-300 transform"
    x-transition:enter-start="-translate-x-full"
    x-transition:enter-end="translate-x-0"
    x-transition:leave="transition ease-in-out duration-300 transform"
    x-transition:leave-start="translate-x-0"
    x-transition:leave-end="-translate-x-full"
    @keydown.escape.window="sidebarOpen = false"
    class="fixed inset-y-0 left-0 z-50 flex w-64 flex-col bg-dark-blue lg:hidden"
  >
    <!-- Close button -->
    <div class="absolute top-0 right-0 -mr-12 pt-2">
      <button @click="sidebarOpen = false" class="ml-1 flex h-10 w-10 items-center justify-center rounded-full">
        <svg class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
    <!-- Sidebar content (copy existing) -->
  </div>

  <!-- Desktop sidebar (existing, add lg:flex) -->
  <div class="hidden lg:flex lg:w-64 lg:flex-col bg-dark-blue">
    <!-- existing sidebar content -->
  </div>

  <!-- Mobile header -->
  <div class="lg:hidden fixed top-0 left-0 right-0 z-30 flex h-16 items-center bg-white border-b px-4">
    <button @click="sidebarOpen = true" class="text-gray-500 hover:text-gray-900">
      <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
      </svg>
    </button>
    <img src="/images/hatchbridge-logo.svg" alt="Hatchbridge" class="ml-4 h-8" />
  </div>

  <!-- Main content (add pt-16 on mobile for header) -->
  <main class="flex-1 overflow-y-auto pt-16 lg:pt-0">
    <!-- existing content -->
  </main>
</div>
```

### Validation Checklist

- [ ] On mobile (< 1024px): Only hamburger + logo visible in header
- [ ] Tap hamburger: Sidebar slides in from left
- [ ] Tap backdrop: Sidebar closes
- [ ] Press Escape: Sidebar closes
- [ ] On desktop (≥ 1024px): Sidebar always visible, no hamburger
- [ ] Lighthouse mobile score ≥ 90
- [ ] No horizontal scroll on any mobile viewport

---

## 1.2 Mobile-Friendly Components

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 1.2.1 | Create `card_list/1` component for mobile tables | `live_helpers.ex` | Renders cards on mobile, table on desktop |
| 1.2.2 | Update booking list to use card_list | `home_live.ex` | Bookings show as cards on mobile |
| 1.2.3 | Update modal to be full-screen on mobile | `live_helpers.ex` | Modal fills screen on mobile |
| 1.2.4 | Add touch-friendly button sizes | `live_helpers.ex` | Min 44px tap targets |
| 1.2.5 | Fix flash message positioning for mobile header | `live.html.heex` | Flash below mobile header |

### Card List Component Pattern

```elixir
# live_helpers.ex
def card_list(assigns) do
  ~H"""
  <!-- Mobile: Card view -->
  <div class="space-y-4 sm:hidden">
    <%= for item <- @items do %>
      <div class="bg-white rounded-lg shadow p-4 border">
        <%= render_slot(@card, item) %>
      </div>
    <% end %>
  </div>

  <!-- Desktop: Table view -->
  <div class="hidden sm:block">
    <table class="min-w-full divide-y divide-gray-200">
      <thead><tr>
        <%= for col <- @columns do %>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
            <%= col.label %>
          </th>
        <% end %>
      </tr></thead>
      <tbody class="divide-y divide-gray-200">
        <%= for item <- @items do %>
          <tr>
            <%= render_slot(@row, item) %>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
  """
end
```

---

## 1.3 HTML Email Templates

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 1.3.1 | Create email templates directory | `lib/overbooked_web/templates/email/` | Directory exists |
| 1.3.2 | Create email view module | `lib/overbooked_web/views/email_view.ex` | Module compiles |
| 1.3.3 | Create base HTML email layout | `templates/email/_layout.html.heex` | Valid HTML email structure |
| 1.3.4 | Create base text email layout | `templates/email/_layout.text.heex` | Plain text fallback |
| 1.3.5 | Create booking confirmation HTML | `templates/email/booking_confirmation.html.heex` | Renders with booking data |
| 1.3.6 | Create booking confirmation text | `templates/email/booking_confirmation.text.heex` | Plain text version |
| 1.3.7 | Update user_notifier for multipart | `user_notifier.ex` | Sends HTML + text |
| 1.3.8 | Add email preview route (dev only) | `router.ex` | Can preview emails at `/dev/mailbox` |
| 1.3.9 | Create password reset HTML template | `templates/email/password_reset.html.heex` | Branded reset email |
| 1.3.10 | Create welcome/invitation HTML template | `templates/email/welcome.html.heex` | Branded welcome email |

### Email View Module

```elixir
# lib/overbooked_web/views/email_view.ex
defmodule OverbookedWeb.EmailView do
  use OverbookedWeb, :view

  def render_email(template, assigns) do
    assigns = Map.merge(assigns, %{
      logo_url: "#{OverbookedWeb.Endpoint.url()}/images/hatchbridge-logo.svg",
      base_url: OverbookedWeb.Endpoint.url(),
      current_year: Date.utc_today().year
    })

    render(template, assigns)
  end
end
```

### Base Email Layout Structure

```html
<!-- templates/email/_layout.html.heex -->
<!DOCTYPE html>
<html lang="en" xmlns:v="urn:schemas-microsoft-com:vml">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light dark">
  <meta name="supported-color-schemes" content="light dark">
  <title><%= @subject %></title>
  <style>
    :root { color-scheme: light dark; }

    /* Reset */
    body, table, td { margin: 0; padding: 0; }
    img { border: 0; display: block; max-width: 100%; }

    /* Brand colors */
    .brand-yellow { color: #FFC421; }
    .brand-blue { color: #2153FF; }
    .brand-dark { color: #000824; }
    .bg-brand-yellow { background-color: #FFC421; }
    .bg-brand-dark { background-color: #000824; }

    /* Button */
    .button {
      display: inline-block;
      padding: 14px 28px;
      background-color: #FFC421;
      color: #000824 !important;
      text-decoration: none;
      border-radius: 6px;
      font-weight: 600;
      font-family: 'Nunito Sans', Arial, sans-serif;
    }

    /* Dark mode */
    @media (prefers-color-scheme: dark) {
      .email-bg { background-color: #1a1a2e !important; }
      .content-bg { background-color: #000824 !important; }
      .text-primary { color: #ffffff !important; }
      .text-secondary { color: #a0aec0 !important; }
    }

    /* Mobile */
    @media only screen and (max-width: 600px) {
      .container { width: 100% !important; }
      .content-padding { padding: 24px 16px !important; }
    }
  </style>
</head>
<body style="margin: 0; padding: 0; background-color: #f4f4f5; font-family: 'Nunito Sans', Arial, sans-serif;">
  <!-- Preheader (hidden preview text) -->
  <div style="display: none; max-height: 0; overflow: hidden;">
    <%= assigns[:preheader] || "" %>
    &#847; &#847; &#847; <!-- Prevent Gmail from showing body text -->
  </div>

  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" class="email-bg" style="background-color: #f4f4f5;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <!-- Container -->
        <table role="presentation" class="container" width="600" cellpadding="0" cellspacing="0">

          <!-- Logo Header -->
          <tr>
            <td align="center" style="padding-bottom: 32px;">
              <img src="<%= @logo_url %>" alt="Hatchbridge Rooms" width="180" style="height: auto;">
            </td>
          </tr>

          <!-- Content Card -->
          <tr>
            <td class="content-bg content-padding" style="background-color: #ffffff; border-radius: 12px; padding: 40px;">
              <%= render_slot(@inner_block) %>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding-top: 32px;">
              <p class="text-secondary" style="margin: 0; color: #6b7280; font-size: 12px;">
                Hatchbridge Rooms<br>
                <a href="<%= @base_url %>" style="color: #6b7280;">Visit Dashboard</a>
              </p>
              <p style="margin: 16px 0 0; color: #9ca3af; font-size: 11px;">
                © <%= @current_year %> Hatchbridge. All rights reserved.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

### Multipart Email Sending Pattern

```elixir
# lib/overbooked/accounts/user_notifier.ex
defmodule Overbooked.Accounts.UserNotifier do
  import Swoosh.Email
  alias Overbooked.Mailer
  alias OverbookedWeb.EmailView

  defp deliver_multipart(recipient, subject, template, assigns) do
    base_assigns = %{
      subject: subject,
      preheader: Map.get(assigns, :preheader, "")
    }

    full_assigns = Map.merge(base_assigns, assigns)

    email =
      new()
      |> to(recipient)
      |> from(get_from_address())
      |> subject(subject)
      |> html_body(EmailView.render_email("#{template}.html", full_assigns))
      |> text_body(EmailView.render_email("#{template}.text", full_assigns))

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp get_from_address do
    case Overbooked.Settings.get_mail_setting() do
      %{from_name: name, from_email: email} when is_binary(email) -> {name, email}
      _ -> {"Hatchbridge Rooms", "noreply@hatchbridge.com"}
    end
  end

  def deliver_booking_confirmation(user, booking) do
    deliver_multipart(
      user.email,
      "Your booking is confirmed",
      "booking_confirmation",
      %{
        user: user,
        booking: booking,
        preheader: "#{booking.resource.name} on #{format_date(booking.start_at)}"
      }
    )
  end
end
```

### Validation Checklist

- [ ] Emails render correctly in Gmail (web + mobile)
- [ ] Emails render correctly in Outlook (2019+)
- [ ] Emails render correctly in Apple Mail
- [ ] Dark mode works in supported clients
- [ ] Plain text fallback is readable
- [ ] All links are clickable and correct
- [ ] Logo displays properly
- [ ] CTA buttons have sufficient contrast

---

# Testing Strategy

## Unit Tests

| Module | Test File | Key Tests |
|--------|-----------|-----------|
| EmailView | `test/overbooked_web/views/email_view_test.exs` | Renders HTML and text emails |
| UserNotifier | `test/overbooked/accounts/user_notifier_test.exs` | Sends multipart emails |

## Integration Tests

| Feature | Test File | Key Scenarios |
|---------|-----------|---------------|
| Email Delivery | `test/overbooked/accounts/user_notifier_test.exs` | HTML + text sent correctly |
| Mobile Layout | Manual testing | Sidebar works on all breakpoints |

## E2E Tests (Manual)

- [ ] Mobile sidebar toggle works on all breakpoints
- [ ] Email renders in Gmail, Outlook, and Apple Mail
- [ ] Email renders in browser preview

---

# Quick Start for Testing Phase 1

Phase 1 is **complete**! Here's how to test the implementation:

## Testing Mobile Layout

1. **Start the Phoenix server**:
   ```bash
   mix phx.server
   ```

2. **Test mobile viewport** (< 1024px):
   - Open browser at http://localhost:4000
   - Open Chrome DevTools (F12)
   - Toggle device toolbar (Ctrl+Shift+M / Cmd+Shift+M)
   - Select mobile device (iPhone, Pixel, etc.)
   - Verify:
     - ✅ Hamburger menu appears in top-left
     - ✅ Hatchbridge logo appears in header
     - ✅ Clicking hamburger opens sidebar from left
     - ✅ Clicking backdrop closes sidebar
     - ✅ Pressing ESC closes sidebar

3. **Test desktop viewport** (≥ 1024px):
   - Resize window to desktop size
   - Verify:
     - ✅ Sidebar always visible on left
     - ✅ No hamburger menu or mobile header
     - ✅ Normal desktop layout

## Testing Email Templates

1. **Send a test email** (in IEx):
   ```elixir
   # Start IEx
   iex -S mix phx.server

   # Get a user and booking
   user = Overbooked.Accounts.get_user!(1)
   booking = Overbooked.Scheduler.get_booking!(1)

   # Send booking confirmation
   Overbooked.Accounts.UserNotifier.deliver_booking_confirmation(user, booking)

   # Send password reset
   url = "http://localhost:4000/reset/token123"
   Overbooked.Accounts.UserNotifier.deliver_reset_password_instructions(user, url)
   ```

2. **View sent emails**:
   - Check your configured email provider (Mailgun, etc.)
   - Or configure Swoosh local preview in `config/dev.exs`

## Running Tests

```bash
mix test
```

---

# Reference Links

- [Tailwind Responsive Design](https://tailwindcss.com/docs/responsive-design)
- [Alpine.js Transitions](https://alpinejs.dev/directives/transition)
- [Swoosh Multipart Email](https://hexdocs.pm/swoosh/Swoosh.Email.html)
- [Phoenix LiveView Guides](https://hexdocs.pm/phoenix_live_view)
