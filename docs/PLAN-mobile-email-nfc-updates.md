# Hatchbridge Rooms: World-Class Visitor Management Plan

**Goal**: Transform the platform into a world-class check-in experience comparable to Envoy.com

This plan addresses three key initiatives:
1. Mobile-First Responsive Layout (especially sidebar)
2. Branded HTML Email Templates
3. NFC Tap-to-Check-In/Out for Self-Registered Users

---

## 1. Mobile Layout Optimization

### Current State Analysis
- **Desktop-first design** with Tailwind CSS
- **Fixed sidebar** (256px/w-64) that doesn't collapse on mobile
- **No hamburger menu** or mobile navigation pattern
- Tables hidden on mobile (`hidden sm:block`) with no mobile alternative
- Responsive classes exist but mobile UX is an afterthought

### UX Expert Recommendations

#### 1.1 Mobile Navigation Patterns (Priority: High)

**Option A: Slide-Out Drawer (Recommended)**
- Hamburger icon in top-left corner on mobile
- Sidebar slides in from left as overlay
- Tap outside or swipe left to dismiss
- Maintains mental model consistency with desktop

**Option B: Bottom Navigation Bar**
- Fixed bottom nav with 4-5 primary actions
- Better thumb reachability on large phones
- Common in native apps (Envoy uses this pattern)
- Would require restructuring navigation hierarchy

**Recommendation**: Implement **Option A first** (lower effort, maintains existing IA), with **Option B as future enhancement** for key user flows like check-in.

#### 1.2 Mobile-First Component Redesign

| Component | Current Issue | Mobile Solution |
|-----------|--------------|-----------------|
| Sidebar | Always visible, blocks content | Collapsible drawer with hamburger trigger |
| Data Tables | Hidden on mobile | Card-based list view with key info |
| Forms | Desktop spacing | Touch-friendly inputs (min 44px tap targets) |
| Modals | Desktop-centered | Full-screen sheets on mobile |
| Date/Time Pickers | Browser default | Mobile-optimized touch pickers |

#### 1.3 Mobile Check-In Experience (Envoy-Inspired)

```
┌─────────────────────────────┐
│  ☰  Hatchbridge Rooms       │  <- Hamburger + Logo
├─────────────────────────────┤
│                             │
│     [Large QR/NFC Icon]     │
│                             │
│     Tap to Check In         │
│                             │
│  ─────────────────────────  │
│                             │
│  Today's Booking:           │
│  ┌─────────────────────┐   │
│  │ Desk 4A             │   │
│  │ 9:00 AM - 5:00 PM   │   │
│  │ [Check In Now]      │   │
│  └─────────────────────┘   │
│                             │
├─────────────────────────────┤
│  🏠    📅    ✓    ⚙️        │  <- Optional bottom nav
└─────────────────────────────┘
```

### SWE Implementation Approach

#### 1.4 Technical Architecture

**File Changes Required:**

1. **`lib/overbooked_web/templates/layout/live.html.heex`**
   - Add mobile header with hamburger toggle
   - Wrap sidebar in conditional visibility component
   - Add AlpineJS state for sidebar open/close

2. **`lib/overbooked_web/live/live_helpers.ex`**
   - Create `mobile_sidebar/1` component
   - Create `mobile_header/1` component
   - Add `card_list/1` as mobile alternative to tables
   - Update `modal/1` to be full-screen on mobile

3. **`assets/css/app.css`**
   - Add sidebar transition animations
   - Add touch-specific utilities
   - Add safe-area-inset padding for notched phones

4. **`assets/tailwind.config.js`**
   - Add `touch:` variant for touch-specific styling
   - Consider adding `xs:` breakpoint (480px) for small phones

**Implementation Pattern:**

```elixir
# New mobile sidebar component
def mobile_sidebar(assigns) do
  ~H"""
  <div
    x-data="{ open: false }"
    x-on:keydown.escape.window="open = false"
  >
    <!-- Backdrop -->
    <div
      x-show="open"
      x-transition:enter="transition-opacity ease-linear duration-300"
      x-transition:leave="transition-opacity ease-linear duration-300"
      class="fixed inset-0 bg-gray-600 bg-opacity-75 z-40 lg:hidden"
      @click="open = false"
    />

    <!-- Sidebar panel -->
    <div
      x-show="open"
      x-transition:enter="transition ease-in-out duration-300 transform"
      x-transition:enter-start="-translate-x-full"
      x-transition:enter-end="translate-x-0"
      x-transition:leave="transition ease-in-out duration-300 transform"
      x-transition:leave-start="translate-x-0"
      x-transition:leave-end="-translate-x-full"
      class="fixed inset-y-0 left-0 z-50 w-64 bg-dark-blue lg:hidden"
    >
      <%= render_slot(@inner_block) %>
    </div>

    <!-- Toggle button (exposed for header) -->
    <button @click="open = true" class="lg:hidden">
      <svg><!-- hamburger icon --></svg>
    </button>
  </div>
  """
end
```

#### 1.5 Responsive Breakpoint Strategy

```
xs: 0-479px    (small phones - single column, hamburger nav)
sm: 480-639px  (large phones - still hamburger nav)
md: 640-767px  (small tablets - optional sidebar peek)
lg: 768-1023px (tablets landscape - persistent sidebar)
xl: 1024px+    (desktop - full sidebar)
```

#### 1.6 Testing Requirements

- Test on iOS Safari (notch handling, safe areas)
- Test on Chrome Android (bottom nav interference)
- Test touch interactions (swipe to close, tap targets)
- Test with screen readers (ARIA labels for hamburger)
- Lighthouse mobile performance audit (target >90)

---

## 2. Branded HTML Email Templates

### Current State Analysis
- **Plain text only** - no HTML templates
- Using Swoosh + Mailgun (fully supports HTML)
- Brand assets available: `hatchbridge-logo.svg`, `logo.png`
- Brand colors defined in Tailwind config
- From name: "Hatchbridge Rooms"

### UX Expert Recommendations

#### 2.1 Email Design System

**Brand Application:**

| Element | Value | Usage |
|---------|-------|-------|
| Primary Color | `#FFC421` (Yellow) | CTAs, accents |
| Secondary Color | `#2153FF` (Blue) | Links, secondary buttons |
| Dark Blue | `#000824` | Headers, text |
| Font | Nunito Sans (fallback: Arial) | All text |
| Logo | hatchbridge-logo.svg | Header of all emails |

**Email Template Hierarchy:**

```
┌─────────────────────────────────────────┐
│  [LOGO]                    View Online  │  <- Preheader
├─────────────────────────────────────────┤
│                                         │
│  Welcome to Hatchbridge Rooms           │  <- Headline
│  ═══════════════════════════════════    │
│                                         │
│  Hi {name},                             │
│                                         │
│  {Body content with clear hierarchy}    │
│                                         │
│        ┌─────────────────────┐          │
│        │   Primary Action    │          │  <- CTA Button
│        └─────────────────────┘          │
│                                         │
│  {Secondary content if needed}          │
│                                         │
├─────────────────────────────────────────┤
│  Hatchbridge Rooms                      │  <- Footer
│  123 Address St, City                   │
│  Unsubscribe | Preferences              │
└─────────────────────────────────────────┘
```

#### 2.2 Email Types to Create

**Transactional (High Priority):**
1. Welcome/Registration confirmation
2. Booking confirmation
3. Check-in reminder (day before / hour before)
4. Check-out confirmation
5. Password reset
6. Email verification

**Future Additions:**
7. Weekly schedule summary
8. Visitor arrival notification (for hosts)
9. Contract renewal reminder
10. Payment receipt

#### 2.3 Mobile Email Optimization

- **Single column layout** (max-width: 600px)
- **Large tap targets** for buttons (min 44px height)
- **Responsive images** with alt text
- **Dark mode support** via `@media (prefers-color-scheme: dark)`
- **Preheader text** for email preview optimization

### SWE Implementation Approach

#### 2.4 Technical Architecture

**New Files to Create:**

```
lib/overbooked_web/templates/email/
├── _layout.html.heex          # Base HTML template
├── _layout.text.heex          # Plain text fallback
├── welcome.html.heex          # Registration
├── welcome.text.heex
├── booking_confirmation.html.heex
├── booking_confirmation.text.heex
├── check_in_reminder.html.heex
├── check_in_reminder.text.heex
├── password_reset.html.heex
├── password_reset.text.heex
└── ...
```

**Modified Files:**

1. **`lib/overbooked/accounts/user_notifier.ex`**
   - Update to use HTML templates
   - Add multipart email support (HTML + text fallback)

2. **`lib/overbooked_web.ex`**
   - Add email view module

#### 2.5 Email Template Implementation

**Base Layout Template (`_layout.html.heex`):**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light dark">
  <title><%= @subject %></title>
  <!--[if mso]>
  <style type="text/css">
    table { border-collapse: collapse; }
    .button { padding: 12px 24px !important; }
  </style>
  <![endif]-->
  <style>
    /* Reset styles */
    body { margin: 0; padding: 0; width: 100%; }
    table { border-spacing: 0; }
    img { border: 0; display: block; }

    /* Brand styles */
    .brand-yellow { color: #FFC421; }
    .brand-blue { color: #2153FF; }
    .brand-dark { color: #000824; }

    /* Button styles */
    .button {
      background-color: #FFC421;
      color: #000824;
      padding: 14px 28px;
      text-decoration: none;
      border-radius: 6px;
      font-weight: 600;
      display: inline-block;
    }

    /* Dark mode */
    @media (prefers-color-scheme: dark) {
      .email-body { background-color: #1a1a2e !important; }
      .content-card { background-color: #000824 !important; }
      .text-dark { color: #ffffff !important; }
    }

    /* Mobile */
    @media only screen and (max-width: 600px) {
      .container { width: 100% !important; }
      .mobile-padding { padding: 20px !important; }
    }
  </style>
</head>
<body style="margin: 0; padding: 0; background-color: #f4f4f5;">
  <!-- Preheader text (hidden) -->
  <div style="display: none; max-height: 0; overflow: hidden;">
    <%= @preheader %>
  </div>

  <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table class="container" width="600" cellpadding="0" cellspacing="0">
          <!-- Header with logo -->
          <tr>
            <td align="center" style="padding-bottom: 24px;">
              <img src="<%= @logo_url %>" alt="Hatchbridge Rooms" width="180" />
            </td>
          </tr>

          <!-- Content card -->
          <tr>
            <td class="content-card" style="background-color: #ffffff; border-radius: 8px; padding: 40px;">
              <%= render_slot(@inner_block) %>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding-top: 24px; color: #6b7280; font-size: 12px;">
              <p>Hatchbridge Rooms</p>
              <p>
                <a href="<%= @unsubscribe_url %>" style="color: #6b7280;">Unsubscribe</a>
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

#### 2.6 Swoosh Multipart Email Pattern

```elixir
defmodule Overbooked.Accounts.UserNotifier do
  import Swoosh.Email
  alias Overbooked.Mailer
  alias OverbookedWeb.EmailView

  defp deliver(recipient, subject, template, assigns) do
    assigns = Map.merge(assigns, %{
      subject: subject,
      logo_url: "#{OverbookedWeb.Endpoint.url()}/images/hatchbridge-logo.svg",
      preheader: Map.get(assigns, :preheader, ""),
      unsubscribe_url: "#"
    })

    email =
      new()
      |> to(recipient)
      |> from({"Hatchbridge Rooms", "noreply@hatchbridge.com"})
      |> subject(subject)
      |> html_body(EmailView.render("#{template}.html", assigns))
      |> text_body(EmailView.render("#{template}.text", assigns))

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def deliver_booking_confirmation(user, booking) do
    deliver(user.email, "Your booking is confirmed", "booking_confirmation", %{
      user: user,
      booking: booking,
      preheader: "Your desk is reserved for #{format_date(booking.start_at)}"
    })
  end
end
```

#### 2.7 Testing Strategy

- **Litmus/Email on Acid** for cross-client testing
- Test on: Gmail, Outlook, Apple Mail, Yahoo, mobile clients
- Validate HTML with W3C validator
- Check spam score with mail-tester.com
- Test dark mode rendering

---

## 3. NFC Tap-to-Check-In/Out

### Current State Analysis
- **No contactless features** currently implemented
- Booking system is time-based (pre-scheduled only)
- No actual check-in/check-out timestamps recorded
- No QR code generation or scanning
- No visitor/guest management flow

### UX Expert Recommendations (Envoy-Inspired)

#### 3.1 User Journey Mapping

**Self-Registered User Check-In Flow:**

```
┌─────────────────────────────────────────────────────────────┐
│                    PRE-VISIT                                │
├─────────────────────────────────────────────────────────────┤
│  1. User registers via invitation link                      │
│  2. User creates booking for desk/room                      │
│  3. System sends confirmation email with:                   │
│     - Booking details                                       │
│     - Digital badge/pass (Apple Wallet / Google Pay)        │
│     - QR code as fallback                                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    ARRIVAL                                  │
├─────────────────────────────────────────────────────────────┤
│  Option A: NFC Tap (Primary - Seamless)                     │
│  ┌─────────────────────────────────────┐                   │
│  │  User approaches NFC reader at      │                   │
│  │  entrance → Taps phone/watch        │                   │
│  │  → System validates booking         │                   │
│  │  → Door unlocks / Check-in recorded │                   │
│  └─────────────────────────────────────┘                   │
│                                                             │
│  Option B: QR Code Scan (Fallback)                          │
│  ┌─────────────────────────────────────┐                   │
│  │  User opens app/email → Shows QR    │                   │
│  │  → Scans at kiosk → Check-in        │                   │
│  └─────────────────────────────────────┘                   │
│                                                             │
│  Option C: Manual Check-In (Edge Case)                      │
│  ┌─────────────────────────────────────┐                   │
│  │  User taps "Check In" button in     │                   │
│  │  web app while on-site (geo-fenced) │                   │
│  └─────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    DEPARTURE                                │
├─────────────────────────────────────────────────────────────┤
│  - NFC tap at exit reader                                   │
│  - Or automatic checkout at booking end time                │
│  - Or manual checkout via app                               │
│  - System records actual departure time                     │
└─────────────────────────────────────────────────────────────┘
```

#### 3.2 Mobile Wallet Integration (Key Differentiator)

**Apple Wallet / Google Pay Pass:**

This is what makes Envoy's experience seamless - users don't need to open an app.

```
┌─────────────────────────────────────┐
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│                                     │
│       HATCHBRIDGE ROOMS             │
│       ─────────────────             │
│                                     │
│       John Smith                    │
│       Desk 4A                       │
│                                     │
│       Dec 20, 2024                  │
│       9:00 AM - 5:00 PM             │
│                                     │
│       ┌─────────────┐               │
│       │ ▒▒▒ QR ▒▒▒  │               │
│       │ ▒▒▒ CODE▒▒▒ │               │
│       └─────────────┘               │
│                                     │
│  TAP TO CHECK IN                    │
└─────────────────────────────────────┘
```

**Benefits:**
- Works with phone locked (Express Mode)
- Integrates with Apple Watch
- Auto-updates when booking changes
- Works offline (NFC is local)
- No app download required

#### 3.3 Kiosk Mode Interface

For locations without NFC readers, a tablet-based kiosk:

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│              HATCHBRIDGE ROOMS                          │
│              ═══════════════                            │
│                                                         │
│         Welcome! Please check in below.                 │
│                                                         │
│    ┌─────────────────┐    ┌─────────────────┐          │
│    │                 │    │                 │          │
│    │   [QR Scanner]  │    │  Tap Your       │          │
│    │                 │    │  Phone Here     │          │
│    │   Show your QR  │    │                 │          │
│    │   code here     │    │  [NFC Symbol]   │          │
│    │                 │    │                 │          │
│    └─────────────────┘    └─────────────────┘          │
│                                                         │
│              ─── OR ───                                 │
│                                                         │
│         ┌─────────────────────────────┐                │
│         │  Enter your email address   │                │
│         └─────────────────────────────┘                │
│                                                         │
│              [ Look Up Booking ]                        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### SWE Implementation Approach

#### 3.4 Database Schema Extensions

**New Tables:**

```sql
-- Track actual check-in/out events (separate from scheduled bookings)
CREATE TABLE check_ins (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id),
  user_id UUID REFERENCES users(id) NOT NULL,
  resource_id UUID REFERENCES resources(id) NOT NULL,

  -- Timestamps
  checked_in_at TIMESTAMP WITH TIME ZONE NOT NULL,
  checked_out_at TIMESTAMP WITH TIME ZONE,

  -- Method tracking
  check_in_method VARCHAR(20) NOT NULL, -- 'nfc', 'qr', 'manual', 'kiosk'
  check_out_method VARCHAR(20),

  -- Device/location info
  device_id VARCHAR(255),
  reader_id VARCHAR(255), -- Which NFC reader was used

  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Digital passes/badges for users
CREATE TABLE digital_passes (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) NOT NULL,

  -- Pass identifiers
  pass_type VARCHAR(20) NOT NULL, -- 'apple_wallet', 'google_pay', 'qr_only'
  pass_serial_number VARCHAR(255) UNIQUE NOT NULL,
  authentication_token VARCHAR(255) NOT NULL,

  -- NFC payload
  nfc_payload BYTEA, -- Encrypted NFC data

  -- QR fallback
  qr_code_data VARCHAR(255) NOT NULL,

  -- Status
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'revoked', 'expired'

  -- Apple/Google specific
  push_token VARCHAR(255), -- For pass updates

  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- NFC readers registry
CREATE TABLE nfc_readers (
  id UUID PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  location VARCHAR(255),
  reader_type VARCHAR(20) NOT NULL, -- 'entry', 'exit', 'room'
  resource_id UUID REFERENCES resources(id), -- Optional: specific room

  -- Hardware config
  hardware_id VARCHAR(255) UNIQUE NOT NULL,
  api_key_hash VARCHAR(255) NOT NULL,

  status VARCHAR(20) DEFAULT 'active',
  last_seen_at TIMESTAMP,

  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

#### 3.5 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         FRONTEND                                │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Mobile Web   │  │ Kiosk Mode   │  │ Admin Panel  │          │
│  │ (LiveView)   │  │ (LiveView)   │  │ (LiveView)   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      PHOENIX API LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐                    │
│  │ /api/v1/checkin  │  │ /api/v1/passes   │                    │
│  │ POST /nfc        │  │ GET /apple/:id   │                    │
│  │ POST /qr         │  │ GET /google/:id  │                    │
│  │ POST /manual     │  │ POST /register   │                    │
│  └──────────────────┘  └──────────────────┘                    │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Apple Wallet Web Service (PassKit)                        │  │
│  │ - POST /v1/devices/:id/registrations/:pass_type/:serial   │  │
│  │ - DELETE /v1/devices/:id/registrations/:pass_type/:serial │  │
│  │ - GET /v1/passes/:pass_type/:serial                       │  │
│  │ - GET /v1/devices/:id/registrations/:pass_type            │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      BUSINESS LOGIC                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ CheckIns    │  │ Passes      │  │ Scheduler   │             │
│  │ Context     │  │ Context     │  │ Context     │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Pass Generation Service                                  │   │
│  │ - Apple Wallet .pkpass creation (uses PassKit)          │   │
│  │ - Google Pay JWT generation                              │   │
│  │ - QR code generation (qrcode library)                   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL INTEGRATIONS                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ Apple Push  │  │ Google Pay  │  │ NFC Reader  │             │
│  │ Notification│  │ API         │  │ Hardware    │             │
│  │ Service     │  │             │  │ (MQTT/REST) │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

#### 3.6 Key Implementation Components

**A. Pass Generation Service:**

```elixir
defmodule Overbooked.Passes do
  @moduledoc """
  Generates and manages digital passes for Apple Wallet and Google Pay.
  """

  alias Overbooked.Passes.{AppleWalletPass, GooglePayPass, QRCode}

  def create_pass_for_user(user, booking) do
    serial = generate_serial()
    auth_token = generate_auth_token()
    qr_data = encode_qr_data(user.id, booking.id)

    pass = %DigitalPass{
      user_id: user.id,
      pass_serial_number: serial,
      authentication_token: auth_token,
      qr_code_data: qr_data,
      pass_type: determine_pass_type(user),
      nfc_payload: generate_nfc_payload(user, booking)
    }

    with {:ok, pass} <- Repo.insert(pass) do
      # Generate platform-specific passes
      apple_pass = AppleWalletPass.generate(pass, user, booking)
      google_pass = GooglePayPass.generate(pass, user, booking)

      {:ok, %{pass: pass, apple: apple_pass, google: google_pass}}
    end
  end

  defp generate_nfc_payload(user, booking) do
    # Create encrypted payload that NFC readers can validate
    data = %{
      user_id: user.id,
      booking_id: booking.id,
      valid_from: booking.start_at,
      valid_until: booking.end_at
    }

    Overbooked.Crypto.encrypt(Jason.encode!(data))
  end
end
```

**B. Check-In API:**

```elixir
defmodule OverbookedWeb.Api.CheckInController do
  use OverbookedWeb, :controller

  alias Overbooked.CheckIns

  @doc """
  NFC check-in endpoint - called by NFC readers.
  """
  def nfc_check_in(conn, %{"payload" => encrypted_payload, "reader_id" => reader_id}) do
    with {:ok, reader} <- validate_reader(reader_id, conn),
         {:ok, data} <- decrypt_payload(encrypted_payload),
         {:ok, check_in} <- CheckIns.process_check_in(data, :nfc, reader) do
      json(conn, %{
        status: "success",
        user_name: check_in.user.name,
        resource_name: check_in.resource.name,
        message: "Welcome, #{check_in.user.name}!"
      })
    else
      {:error, :invalid_booking} ->
        json(conn |> put_status(403), %{status: "error", message: "No valid booking found"})
      {:error, :already_checked_in} ->
        json(conn, %{status: "already_in", message: "Already checked in"})
      {:error, reason} ->
        json(conn |> put_status(400), %{status: "error", message: reason})
    end
  end

  @doc """
  QR code check-in - used by kiosk or mobile scanning.
  """
  def qr_check_in(conn, %{"qr_data" => qr_data}) do
    with {:ok, data} <- decode_qr(qr_data),
         {:ok, check_in} <- CheckIns.process_check_in(data, :qr, nil) do
      json(conn, %{status: "success", check_in: check_in})
    end
  end
end
```

**C. Apple Wallet Pass Generation:**

```elixir
defmodule Overbooked.Passes.AppleWalletPass do
  @moduledoc """
  Generates .pkpass files for Apple Wallet.
  Requires Apple Developer account and PassKit certificates.
  """

  @pass_type_identifier "pass.com.hatchbridge.rooms"
  @team_identifier "XXXXXXXXXX"  # From Apple Developer account

  def generate(pass, user, booking) do
    pass_json = %{
      formatVersion: 1,
      passTypeIdentifier: @pass_type_identifier,
      serialNumber: pass.pass_serial_number,
      teamIdentifier: @team_identifier,
      authenticationToken: pass.authentication_token,
      webServiceURL: "#{OverbookedWeb.Endpoint.url()}/api/v1/passes",

      # Visual appearance
      backgroundColor: "rgb(0, 8, 36)",  # Dark blue
      foregroundColor: "rgb(255, 255, 255)",
      labelColor: "rgb(255, 196, 33)",  # Yellow

      # Organization
      organizationName: "Hatchbridge Rooms",
      description: "Workspace Access Pass",
      logoText: "Hatchbridge",

      # Pass content
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
        ],
        backFields: [
          %{key: "terms", label: "Terms", value: "Present this pass at entry..."}
        ]
      },

      # NFC for tap-to-check-in
      nfc: %{
        message: pass.nfc_payload |> Base.encode64(),
        encryptionPublicKey: get_nfc_public_key()
      },

      # Barcode fallback
      barcodes: [
        %{
          format: "PKBarcodeFormatQR",
          message: pass.qr_code_data,
          messageEncoding: "iso-8859-1"
        }
      ]
    }

    # Create .pkpass (signed zip file)
    create_signed_pass(pass_json)
  end
end
```

#### 3.7 Hardware Integration Options

**Option A: Dedicated NFC Readers (Enterprise)**
- Hardware: HID iCLASS SE, ASSA ABLOY Aperio
- Protocol: MQTT or REST API callbacks
- Cost: $200-500 per reader + door hardware
- Best for: Permanent installations with access control

**Option B: Tablet-Based Kiosk (Budget-Friendly)**
- Hardware: iPad with NFC (iPhone XS+) or Android tablet
- Protocol: Web-based PWA with Web NFC API (Chrome Android only)
- Cost: $300-800 per kiosk
- Best for: Reception desks, flexible deployments

**Option C: Smartphone Reader Mode (Zero Hardware)**
- User's own phone reads NFC from kiosk display
- Or admin phone scans visitor's QR code
- Cost: $0 additional hardware
- Best for: Small spaces, low volume

**Recommended Starting Point**: Option B (tablet kiosk) with QR code primary, NFC secondary. This provides the best UX with minimal hardware investment.

#### 3.8 Security Considerations

1. **Pass Authentication**
   - Each pass has unique serial + auth token
   - Tokens are hashed in database
   - Passes can be remotely revoked

2. **NFC Payload Security**
   - AES-256 encryption of payload
   - Time-limited validity (booking window only)
   - Replay protection via timestamps

3. **API Security**
   - Reader authentication via API keys
   - Rate limiting on check-in endpoints
   - Audit logging of all check-ins

4. **Privacy**
   - Minimal data in NFC payload
   - No PII in QR codes (just IDs)
   - GDPR-compliant data handling

---

## Implementation Roadmap

### Phase 1: Foundation (Mobile + Email)
1. **Mobile sidebar** - Collapsible hamburger menu
2. **Email templates** - Base HTML layout + booking confirmation
3. **Mobile check-in page** - Simple "Check In" button for booked users

### Phase 2: Digital Passes
4. **QR code generation** - Add QR to booking confirmation emails
5. **Kiosk mode** - Full-screen tablet interface for QR scanning
6. **Database schema** - Check-ins table, passes table

### Phase 3: Native Wallet Integration
7. **Apple Wallet passes** - .pkpass generation
8. **Google Pay passes** - JWT generation
9. **Pass updates** - Push notifications for booking changes

### Phase 4: NFC Hardware
10. **NFC reader integration** - API for hardware callbacks
11. **Reader management** - Admin UI for reader configuration
12. **Access control** - Door unlock integration (optional)

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Mobile usability score | >90 Lighthouse | Automated testing |
| Email open rate | >40% | Mailgun analytics |
| Check-in time | <3 seconds | P95 latency |
| Pass adoption | >60% of users | Database analytics |
| NFC success rate | >99% | Error rate monitoring |

---

## Competitive Positioning vs Envoy

| Feature | Envoy | Hatchbridge (Current) | Hatchbridge (Planned) |
|---------|-------|----------------------|----------------------|
| Mobile-first UI | ✅ | ❌ | ✅ Phase 1 |
| Branded emails | ✅ | ❌ | ✅ Phase 1 |
| QR check-in | ✅ | ❌ | ✅ Phase 2 |
| Apple Wallet | ✅ | ❌ | ✅ Phase 3 |
| Google Pay | ✅ | ❌ | ✅ Phase 3 |
| NFC tap-in | ✅ | ❌ | ✅ Phase 4 |
| Kiosk mode | ✅ | ❌ | ✅ Phase 2 |
| Self-hosted | ❌ | ✅ | ✅ |
| Open source | ❌ | ✅ | ✅ |

**Key Differentiator**: Self-hosted, privacy-first visitor management with enterprise-grade features.
