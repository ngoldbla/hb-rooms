# Hatchbridge Rooms - Agent Implementation Guide

## Project Overview

**Stack:** Phoenix 1.7 + LiveView + Tailwind CSS + PostgreSQL + Swoosh (Mailgun)
**Purpose:** Self-hosted coworking space management platform
**Goal:** Transform into world-class visitor management system (Envoy-like experience)

## Current State Summary

| Area | Status | Key Files |
|------|--------|-----------|
| Mobile Layout | Desktop-first, no hamburger menu | `lib/overbooked_web/templates/layout/live.html.heex` |
| Email System | Plain text only, Swoosh+Mailgun ready | `lib/overbooked/accounts/user_notifier.ex` |
| Check-in | Time-based bookings only, no actual check-in | `lib/overbooked/scheduler/booking.ex` |

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

# Phase 2: QR Codes + Kiosk Mode + Check-In Database

## 2.1 Database Schema

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 2.1.1 | Create check_ins migration | `priv/repo/migrations/` | Migration runs successfully |
| 2.1.2 | Create CheckIn schema | `lib/overbooked/check_ins/check_in.ex` | Schema compiles |
| 2.1.3 | Create CheckIns context | `lib/overbooked/check_ins.ex` | Context functions work |
| 2.1.4 | Add check-in relationship to bookings | `booking.ex` | `has_one :check_in` works |
| 2.1.5 | Create digital_passes migration | `priv/repo/migrations/` | Migration runs |
| 2.1.6 | Create DigitalPass schema | `lib/overbooked/passes/digital_pass.ex` | Schema compiles |

### Migration: Check-Ins

```elixir
# priv/repo/migrations/XXXXXX_create_check_ins.exs
defmodule Overbooked.Repo.Migrations.CreateCheckIns do
  use Ecto.Migration

  def change do
    create table(:check_ins, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :booking_id, references(:bookings, type: :binary_id, on_delete: :nilify_all)
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :resource_id, references(:resources, type: :binary_id, on_delete: :delete_all), null: false

      add :checked_in_at, :utc_datetime, null: false
      add :checked_out_at, :utc_datetime

      add :check_in_method, :string, null: false  # nfc, qr, manual, kiosk
      add :check_out_method, :string

      add :device_info, :map, default: %{}
      add :notes, :text

      timestamps()
    end

    create index(:check_ins, [:user_id])
    create index(:check_ins, [:resource_id])
    create index(:check_ins, [:booking_id])
    create index(:check_ins, [:checked_in_at])
  end
end
```

### Migration: Digital Passes

```elixir
# priv/repo/migrations/XXXXXX_create_digital_passes.exs
defmodule Overbooked.Repo.Migrations.CreateDigitalPasses do
  use Ecto.Migration

  def change do
    create table(:digital_passes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :pass_type, :string, null: false  # apple_wallet, google_pay, qr_only
      add :serial_number, :string, null: false
      add :authentication_token, :string, null: false

      add :qr_code_data, :string, null: false
      add :nfc_payload, :binary

      add :status, :string, default: "active"  # active, revoked, expired
      add :push_token, :string

      add :last_used_at, :utc_datetime
      add :expires_at, :utc_datetime

      timestamps()
    end

    create unique_index(:digital_passes, [:serial_number])
    create index(:digital_passes, [:user_id])
    create index(:digital_passes, [:status])
  end
end
```

---

## 2.2 QR Code Generation

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 2.2.1 | Add qrcode_ex dependency | `mix.exs` | `mix deps.get` succeeds |
| 2.2.2 | Create QR code generator module | `lib/overbooked/passes/qr_code.ex` | Generates valid QR PNG |
| 2.2.3 | Add QR code to booking confirmation email | `booking_confirmation.html.heex` | QR visible in email |
| 2.2.4 | Create QR code download endpoint | `controllers/` | GET `/api/passes/qr/:id` returns PNG |
| 2.2.5 | Add "Show QR" button to booking detail | `home_live.ex` or `booking_live.ex` | Button displays QR modal |

### QR Code Module

```elixir
# lib/overbooked/passes/qr_code.ex
defmodule Overbooked.Passes.QRCode do
  @moduledoc "Generates QR codes for check-in."

  def generate_for_booking(booking) do
    data = encode_booking_data(booking)

    data
    |> EQRCode.encode()
    |> EQRCode.png(width: 300, background_color: <<255, 255, 255>>, color: <<0, 8, 36>>)
  end

  def generate_for_user(user) do
    data = encode_user_data(user)

    data
    |> EQRCode.encode()
    |> EQRCode.png(width: 300)
  end

  defp encode_booking_data(booking) do
    payload = %{
      type: "booking",
      bid: booking.id,
      uid: booking.user_id,
      exp: DateTime.to_unix(booking.end_at)
    }

    payload
    |> Jason.encode!()
    |> Base.url_encode64(padding: false)
  end

  defp encode_user_data(user) do
    payload = %{
      type: "user",
      uid: user.id,
      ts: DateTime.utc_now() |> DateTime.to_unix()
    }

    # Sign to prevent tampering
    signature = sign_payload(payload)

    %{payload: payload, sig: signature}
    |> Jason.encode!()
    |> Base.url_encode64(padding: false)
  end

  defp sign_payload(payload) do
    secret = Application.get_env(:overbooked, :qr_signing_key)
    :crypto.mac(:hmac, :sha256, secret, Jason.encode!(payload))
    |> Base.url_encode64(padding: false)
    |> binary_part(0, 16)  # Truncate for QR size
  end
end
```

### Dependency Addition

```elixir
# mix.exs - add to deps
{:eqrcode, "~> 0.1.10"}
```

---

## 2.3 Kiosk Mode Interface

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 2.3.1 | Create kiosk LiveView | `lib/overbooked_web/live/kiosk_live.ex` | Page loads at `/kiosk` |
| 2.3.2 | Add kiosk route (no auth) | `router.ex` | Route accessible without login |
| 2.3.3 | Create QR scanner component | `live/kiosk/qr_scanner.ex` | Camera activates, scans QR |
| 2.3.4 | Create check-in success screen | `kiosk_live.ex` | Shows welcome message |
| 2.3.5 | Create check-in error screen | `kiosk_live.ex` | Shows helpful error |
| 2.3.6 | Add auto-reset timer (10s) | `kiosk_live.ex` | Returns to scan screen |
| 2.3.7 | Add kiosk full-screen CSS | `app.css` | No scrollbars, full viewport |
| 2.3.8 | Create email lookup fallback | `kiosk_live.ex` | Can type email to find booking |

### Kiosk LiveView

```elixir
# lib/overbooked_web/live/kiosk_live.ex
defmodule OverbookedWeb.KioskLive do
  use OverbookedWeb, :live_view

  alias Overbooked.{CheckIns, Scheduler}

  @reset_timeout 10_000  # 10 seconds

  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      state: :scanning,
      error: nil,
      check_in: nil,
      email: ""
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="kiosk-container min-h-screen bg-dark-blue flex flex-col items-center justify-center p-8">

      <%= case @state do %>
        <% :scanning -> %>
          <div class="text-center">
            <img src="/images/hatchbridge-logo.svg" class="h-16 mx-auto mb-8" />
            <h1 class="text-4xl font-bold text-white mb-4">Welcome</h1>
            <p class="text-xl text-gray-300 mb-8">Scan your QR code or tap your phone</p>

            <div class="bg-white rounded-2xl p-8 mb-8">
              <div id="qr-scanner" phx-hook="QRScanner" class="w-80 h-80 bg-gray-100 rounded-lg"></div>
            </div>

            <div class="text-gray-400 mb-4">— OR —</div>

            <form phx-submit="lookup_email" class="max-w-md mx-auto">
              <input
                type="email"
                name="email"
                value={@email}
                placeholder="Enter your email"
                class="w-full px-6 py-4 text-xl rounded-lg border-2 border-gray-300 focus:border-primary"
              />
              <button type="submit" class="mt-4 w-full py-4 bg-primary text-dark-blue font-bold text-xl rounded-lg">
                Look Up Booking
              </button>
            </form>
          </div>

        <% :success -> %>
          <div class="text-center animate-fade-in">
            <div class="w-32 h-32 bg-green-500 rounded-full flex items-center justify-center mx-auto mb-8">
              <svg class="w-16 h-16 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h1 class="text-5xl font-bold text-white mb-4">Welcome!</h1>
            <p class="text-3xl text-primary mb-2"><%= @check_in.user.name %></p>
            <p class="text-2xl text-gray-300"><%= @check_in.resource.name %></p>
          </div>

        <% :error -> %>
          <div class="text-center animate-fade-in">
            <div class="w-32 h-32 bg-red-500 rounded-full flex items-center justify-center mx-auto mb-8">
              <svg class="w-16 h-16 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
            <h1 class="text-4xl font-bold text-white mb-4">Unable to Check In</h1>
            <p class="text-xl text-gray-300 mb-8"><%= @error %></p>
            <button phx-click="reset" class="py-4 px-8 bg-primary text-dark-blue font-bold text-xl rounded-lg">
              Try Again
            </button>
          </div>
      <% end %>

    </div>
    """
  end

  def handle_event("qr_scanned", %{"data" => qr_data}, socket) do
    case CheckIns.process_qr_check_in(qr_data) do
      {:ok, check_in} ->
        check_in = Overbooked.Repo.preload(check_in, [:user, :resource])
        Process.send_after(self(), :reset, @reset_timeout)
        {:noreply, assign(socket, state: :success, check_in: check_in)}

      {:error, reason} ->
        Process.send_after(self(), :reset, @reset_timeout)
        {:noreply, assign(socket, state: :error, error: humanize_error(reason))}
    end
  end

  def handle_event("lookup_email", %{"email" => email}, socket) do
    case Scheduler.get_current_booking_for_email(email) do
      {:ok, booking} ->
        case CheckIns.create_check_in(booking, :kiosk) do
          {:ok, check_in} ->
            check_in = Overbooked.Repo.preload(check_in, [:user, :resource])
            Process.send_after(self(), :reset, @reset_timeout)
            {:noreply, assign(socket, state: :success, check_in: check_in)}
          {:error, reason} ->
            {:noreply, assign(socket, state: :error, error: humanize_error(reason))}
        end
      {:error, :no_booking} ->
        {:noreply, assign(socket, state: :error, error: "No booking found for today")}
    end
  end

  def handle_event("reset", _, socket) do
    {:noreply, assign(socket, state: :scanning, error: nil, check_in: nil, email: "")}
  end

  def handle_info(:reset, socket) do
    {:noreply, assign(socket, state: :scanning, error: nil, check_in: nil, email: "")}
  end

  defp humanize_error(:already_checked_in), do: "You're already checked in"
  defp humanize_error(:booking_not_started), do: "Your booking hasn't started yet"
  defp humanize_error(:booking_expired), do: "Your booking has ended"
  defp humanize_error(:invalid_qr), do: "Invalid QR code"
  defp humanize_error(_), do: "Something went wrong"
end
```

### QR Scanner JavaScript Hook

```javascript
// assets/js/hooks/qr_scanner.js
import QrScanner from 'qr-scanner';

export const QRScanner = {
  mounted() {
    const videoElem = document.createElement('video');
    videoElem.className = 'w-full h-full object-cover rounded-lg';
    this.el.appendChild(videoElem);

    this.scanner = new QrScanner(
      videoElem,
      result => {
        this.pushEvent('qr_scanned', { data: result.data });
        // Pause briefly to prevent duplicate scans
        this.scanner.stop();
        setTimeout(() => this.scanner.start(), 3000);
      },
      {
        highlightScanRegion: true,
        highlightCodeOutline: true,
      }
    );

    this.scanner.start();
  },

  destroyed() {
    if (this.scanner) {
      this.scanner.stop();
      this.scanner.destroy();
    }
  }
};
```

### Validation Checklist

- [ ] Kiosk page loads without authentication
- [ ] QR scanner activates camera
- [ ] Scanning valid QR shows success with name
- [ ] Scanning invalid QR shows error
- [ ] Screen auto-resets after 10 seconds
- [ ] Email lookup finds current booking
- [ ] Full-screen mode works (no scrollbars)

---

# Phase 3: Apple Wallet + Google Pay Integration

## 3.1 Apple Wallet (.pkpass)

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 3.1.1 | Obtain Apple Developer Pass Type ID | Apple Developer Portal | Certificate downloaded |
| 3.1.2 | Generate pass signing certificate | Apple Developer Portal | .p12 file created |
| 3.1.3 | Create pass template JSON | `priv/passes/pass.json` | Valid PassKit structure |
| 3.1.4 | Create pass icons (1x, 2x, 3x) | `priv/passes/` | icon.png, icon@2x.png, icon@3x.png |
| 3.1.5 | Create AppleWalletPass module | `lib/overbooked/passes/apple_wallet.ex` | Generates .pkpass |
| 3.1.6 | Add pass download endpoint | `controllers/pass_controller.ex` | Returns .pkpass file |
| 3.1.7 | Add "Add to Wallet" button | Email templates | Button links to download |
| 3.1.8 | Implement PassKit web service | `controllers/passkit_controller.ex` | Apple can update passes |

### Apple Wallet Module

```elixir
# lib/overbooked/passes/apple_wallet.ex
defmodule Overbooked.Passes.AppleWallet do
  @moduledoc "Generates Apple Wallet .pkpass files."

  @pass_type_id Application.compile_env(:overbooked, :apple_pass_type_id)
  @team_id Application.compile_env(:overbooked, :apple_team_id)

  def generate(user, booking, digital_pass) do
    pass_json = build_pass_json(user, booking, digital_pass)

    # Create temp directory for pass contents
    tmp_dir = System.tmp_dir!() |> Path.join("pass_#{digital_pass.serial_number}")
    File.mkdir_p!(tmp_dir)

    try do
      # Write pass.json
      File.write!(Path.join(tmp_dir, "pass.json"), Jason.encode!(pass_json))

      # Copy icons
      copy_icons(tmp_dir)

      # Create manifest.json (SHA1 hashes of all files)
      manifest = create_manifest(tmp_dir)
      File.write!(Path.join(tmp_dir, "manifest.json"), Jason.encode!(manifest))

      # Sign manifest to create signature
      create_signature(tmp_dir)

      # Zip everything into .pkpass
      create_pkpass(tmp_dir, digital_pass.serial_number)
    after
      File.rm_rf!(tmp_dir)
    end
  end

  defp build_pass_json(user, booking, digital_pass) do
    %{
      formatVersion: 1,
      passTypeIdentifier: @pass_type_id,
      serialNumber: digital_pass.serial_number,
      teamIdentifier: @team_id,
      authenticationToken: digital_pass.authentication_token,
      webServiceURL: "#{OverbookedWeb.Endpoint.url()}/api/v1/passkit",

      organizationName: "Hatchbridge Rooms",
      description: "Workspace Access",
      logoText: "Hatchbridge",

      backgroundColor: "rgb(0, 8, 36)",
      foregroundColor: "rgb(255, 255, 255)",
      labelColor: "rgb(255, 196, 33)",

      generic: %{
        primaryFields: [
          %{key: "resource", label: "WORKSPACE", value: booking.resource.name}
        ],
        secondaryFields: [
          %{key: "date", label: "DATE", value: format_date(booking.start_at)},
          %{key: "time", label: "TIME", value: format_time_range(booking)}
        ],
        auxiliaryFields: [
          %{key: "member", label: "MEMBER", value: user.name}
        ]
      },

      barcodes: [
        %{
          format: "PKBarcodeFormatQR",
          message: digital_pass.qr_code_data,
          messageEncoding: "iso-8859-1"
        }
      ],

      nfc: %{
        message: Base.encode64(digital_pass.nfc_payload),
        encryptionPublicKey: get_nfc_public_key()
      }
    }
  end
end
```

---

## 3.2 Google Pay Pass

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 3.2.1 | Create Google Pay API project | Google Cloud Console | API enabled |
| 3.2.2 | Create service account | Google Cloud Console | JSON key downloaded |
| 3.2.3 | Create GooglePayPass module | `lib/overbooked/passes/google_pay.ex` | Generates JWT |
| 3.2.4 | Add "Add to Google Pay" button | Email templates | Button with save link |

### Google Pay Module

```elixir
# lib/overbooked/passes/google_pay.ex
defmodule Overbooked.Passes.GooglePay do
  @moduledoc "Generates Google Pay pass save links."

  @issuer_id Application.compile_env(:overbooked, :google_issuer_id)

  def generate_save_link(user, booking, digital_pass) do
    jwt = create_jwt(user, booking, digital_pass)
    "https://pay.google.com/gp/v/save/#{jwt}"
  end

  defp create_jwt(user, booking, digital_pass) do
    claims = %{
      iss: get_service_account_email(),
      aud: "google",
      typ: "savetowallet",
      iat: DateTime.utc_now() |> DateTime.to_unix(),
      payload: %{
        genericObjects: [
          build_generic_object(user, booking, digital_pass)
        ]
      }
    }

    Joken.Signer.sign(claims, signer())
  end

  defp build_generic_object(user, booking, digital_pass) do
    %{
      id: "#{@issuer_id}.#{digital_pass.serial_number}",
      classId: "#{@issuer_id}.workspace_pass",
      genericType: "GENERIC_TYPE_UNSPECIFIED",
      hexBackgroundColor: "#000824",
      logo: %{
        sourceUri: %{uri: "#{OverbookedWeb.Endpoint.url()}/images/logo.png"}
      },
      cardTitle: %{defaultValue: %{language: "en", value: "Hatchbridge Rooms"}},
      header: %{defaultValue: %{language: "en", value: booking.resource.name}},
      subheader: %{defaultValue: %{language: "en", value: user.name}},
      textModulesData: [
        %{id: "date", header: "DATE", body: format_date(booking.start_at)},
        %{id: "time", header: "TIME", body: format_time_range(booking)}
      ],
      barcode: %{
        type: "QR_CODE",
        value: digital_pass.qr_code_data
      }
    }
  end
end
```

---

# Phase 4: NFC Hardware Integration

## 4.1 NFC Reader API

### Tasks

| # | Task | File(s) | Validation |
|---|------|---------|------------|
| 4.1.1 | Create nfc_readers migration | `priv/repo/migrations/` | Migration runs |
| 4.1.2 | Create NfcReader schema | `lib/overbooked/hardware/nfc_reader.ex` | Schema compiles |
| 4.1.3 | Create NFC check-in API endpoint | `controllers/api/nfc_controller.ex` | POST works |
| 4.1.4 | Add reader authentication | `plugs/reader_auth.ex` | API key validation |
| 4.1.5 | Create reader management admin UI | `live/admin/readers_live.ex` | Can add/remove readers |
| 4.1.6 | Add NFC payload decryption | `lib/overbooked/crypto.ex` | Decrypts payloads |
| 4.1.7 | Create reader heartbeat endpoint | `controllers/api/nfc_controller.ex` | Readers ping for status |

### NFC Check-In Controller

```elixir
# lib/overbooked_web/controllers/api/nfc_controller.ex
defmodule OverbookedWeb.Api.NfcController do
  use OverbookedWeb, :controller

  alias Overbooked.{CheckIns, Hardware}

  plug :authenticate_reader

  def check_in(conn, %{"payload" => encrypted_payload}) do
    reader = conn.assigns.reader

    with {:ok, data} <- Overbooked.Crypto.decrypt(encrypted_payload),
         {:ok, parsed} <- Jason.decode(data),
         {:ok, check_in} <- CheckIns.process_nfc_check_in(parsed, reader) do

      check_in = Overbooked.Repo.preload(check_in, [:user, :resource])

      json(conn, %{
        status: "success",
        action: determine_action(check_in),
        user: %{
          name: check_in.user.name,
          id: check_in.user.id
        },
        resource: %{
          name: check_in.resource.name,
          id: check_in.resource.id
        },
        message: build_message(check_in)
      })
    else
      {:error, :invalid_payload} ->
        conn |> put_status(400) |> json(%{status: "error", code: "invalid_payload"})
      {:error, :no_valid_booking} ->
        conn |> put_status(403) |> json(%{status: "error", code: "no_booking"})
      {:error, :expired} ->
        conn |> put_status(403) |> json(%{status: "error", code: "expired"})
      {:error, reason} ->
        conn |> put_status(400) |> json(%{status: "error", code: to_string(reason)})
    end
  end

  def heartbeat(conn, _params) do
    reader = conn.assigns.reader
    Hardware.update_reader_seen(reader)
    json(conn, %{status: "ok", server_time: DateTime.utc_now()})
  end

  defp authenticate_reader(conn, _opts) do
    case get_req_header(conn, "x-reader-api-key") do
      [api_key] ->
        case Hardware.get_reader_by_api_key(api_key) do
          nil -> conn |> put_status(401) |> json(%{error: "Invalid API key"}) |> halt()
          reader -> assign(conn, :reader, reader)
        end
      _ ->
        conn |> put_status(401) |> json(%{error: "Missing API key"}) |> halt()
    end
  end

  defp determine_action(check_in) do
    if check_in.checked_out_at, do: "check_out", else: "check_in"
  end

  defp build_message(check_in) do
    if check_in.checked_out_at do
      "Goodbye, #{check_in.user.name}!"
    else
      "Welcome, #{check_in.user.name}!"
    end
  end
end
```

---

# Testing Strategy

## Unit Tests

| Module | Test File | Key Tests |
|--------|-----------|-----------|
| CheckIns | `test/overbooked/check_ins_test.exs` | Create, validate booking, prevent duplicates |
| Passes.QRCode | `test/overbooked/passes/qr_code_test.exs` | Generate, encode, decode |
| Passes.AppleWallet | `test/overbooked/passes/apple_wallet_test.exs` | Generate valid .pkpass |
| Passes.GooglePay | `test/overbooked/passes/google_pay_test.exs` | Generate valid JWT |

## Integration Tests

| Feature | Test File | Key Scenarios |
|---------|-----------|---------------|
| Kiosk Flow | `test/overbooked_web/live/kiosk_live_test.exs` | QR scan, email lookup, errors |
| NFC API | `test/overbooked_web/controllers/api/nfc_controller_test.exs` | Auth, check-in, check-out |
| Email Delivery | `test/overbooked/accounts/user_notifier_test.exs` | HTML + text sent |

## E2E Tests (Playwright/Cypress)

- [ ] Mobile sidebar toggle works on all breakpoints
- [ ] Kiosk mode full flow
- [ ] Email renders in browser preview

---

# Dependencies to Add

```elixir
# mix.exs
defp deps do
  [
    # Existing deps...

    # QR Code generation
    {:eqrcode, "~> 0.1.10"},

    # JWT for Google Pay
    {:joken, "~> 2.6"},

    # Encryption for NFC payloads
    {:plug_crypto, "~> 2.0"},  # Already included with Phoenix

    # QR scanning (JS library - add via npm)
    # npm install qr-scanner
  ]
end
```

```json
// assets/package.json - add
{
  "dependencies": {
    "qr-scanner": "^1.4.2"
  }
}
```

---

# Environment Variables

```bash
# .env.example additions

# QR Code signing
QR_SIGNING_KEY=your-32-byte-secret-key

# Apple Wallet
APPLE_PASS_TYPE_ID=pass.com.hatchbridge.rooms
APPLE_TEAM_ID=XXXXXXXXXX
APPLE_PASS_CERTIFICATE_PATH=/path/to/pass.p12
APPLE_PASS_CERTIFICATE_PASSWORD=your-password
APPLE_WWDR_CERTIFICATE_PATH=/path/to/AppleWWDRCA.cer

# Google Pay
GOOGLE_PAY_ISSUER_ID=your-issuer-id
GOOGLE_SERVICE_ACCOUNT_JSON=/path/to/service-account.json

# NFC Encryption
NFC_ENCRYPTION_KEY=your-32-byte-aes-key
```

---

# Quick Start for Next Agent

1. **Start with Phase 1.1** - Mobile sidebar is highest impact, lowest complexity
2. **Run existing tests first**: `mix test` to establish baseline
3. **Check Tailwind config**: `assets/tailwind.config.js` for brand colors
4. **Review current layout**: `lib/overbooked_web/templates/layout/live.html.heex`

## Immediate Next Steps

```bash
# 1. Create feature branch (if not on one)
git checkout -b feature/mobile-sidebar

# 2. Start with mobile header + hamburger
# Edit: lib/overbooked_web/templates/layout/live.html.heex

# 3. Test on mobile viewport
mix phx.server
# Open Chrome DevTools > Toggle device toolbar > Select mobile

# 4. Run tests
mix test
```

---

# Reference Links

- [Tailwind Responsive Design](https://tailwindcss.com/docs/responsive-design)
- [Alpine.js Transitions](https://alpinejs.dev/directives/transition)
- [Apple PassKit Docs](https://developer.apple.com/documentation/passkit)
- [Google Pay Passes API](https://developers.google.com/pay/passes)
- [Swoosh Multipart Email](https://hexdocs.pm/swoosh/Swoosh.Email.html)
- [EQRCode Library](https://hexdocs.pm/eqrcode)
