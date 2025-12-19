# Hatchbridge Rooms - Developer Setup Guide

This guide covers setting up the development environment for Hatchbridge Rooms, including the Stripe payments integration for long-term office space contracts.

## Prerequisites

- Elixir 1.14+
- Erlang/OTP 25+
- PostgreSQL 13+
- Node.js 16+ (for asset compilation)
- Stripe CLI (optional, for webhook testing)

## Quick Start

```bash
# Clone and enter the project
cd rome

# Install dependencies
mix deps.get

# Set up the database
mix ecto.setup

# Start the server
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000)

---

## Stripe Payments Setup

The application includes Stripe integration for long-term office space rentals. Follow these steps to enable payments:

### 1. Get Stripe API Keys

1. Sign up or log in at [https://dashboard.stripe.com](https://dashboard.stripe.com)
2. Go to [Developers > API Keys](https://dashboard.stripe.com/test/apikeys)
3. Copy your **Publishable key** (`pk_test_...`) and **Secret key** (`sk_test_...`)

### 2. Set Environment Variables

```bash
# Add to your shell profile (~/.zshrc, ~/.bashrc, etc.) or export in terminal
export STRIPE_SECRET_KEY="sk_test_your_secret_key_here"
export STRIPE_WEBHOOK_SECRET="whsec_your_webhook_secret_here"
```

### 3. Set Up Webhook Forwarding (Local Development)

Stripe uses webhooks to notify your app when payments complete. For local development, use the Stripe CLI:

```bash
# Install Stripe CLI (macOS)
brew install stripe/stripe-cli/stripe

# Login to Stripe
stripe login

# Forward webhooks to your local server
stripe listen --forward-to localhost:4000/webhooks/stripe
```

The CLI will output a webhook signing secret like:
```
Ready! Your webhook signing secret is whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Use this as your `STRIPE_WEBHOOK_SECRET`.

### 4. Mark Resources as Rentable

Resources need to be marked as rentable with pricing to appear on the Spaces page:

```bash
# Via IEx
iex -S mix

# In IEx, run:
alias Overbooked.{Repo, Resources.Resource}
import Ecto.Query

# Get a resource and make it rentable
resource = Repo.one(from r in Resource, where: r.name == "Conference Room A", limit: 1)
resource
|> Ecto.Changeset.change(%{
  is_rentable: true,
  monthly_rate_cents: 50000,  # $500/month
  description: "Private office space with panoramic views, includes desk and ergonomic chair"
})
|> Repo.update!()
```

Or via direct SQL:
```sql
UPDATE resources
SET is_rentable = true,
    monthly_rate_cents = 50000,
    description = 'Private office space with panoramic views'
WHERE name = 'Office A';
```

### 5. Test the Payment Flow

1. Start the server: `mix phx.server`
2. Navigate to [http://localhost:4000/spaces](http://localhost:4000/spaces)
3. Click "Book Now" on a rentable space
4. Select 1-month or 3-month duration
5. Click "Proceed to Payment"
6. Use Stripe test card: `4242 4242 4242 4242` (any future expiry, any CVC)
7. Complete checkout
8. You should be redirected to the success page
9. View your contract at [http://localhost:4000/contracts](http://localhost:4000/contracts)

### Stripe Test Cards

| Card Number | Result |
|-------------|--------|
| `4242 4242 4242 4242` | Success |
| `4000 0000 0000 0002` | Card declined |
| `4000 0000 0000 9995` | Insufficient funds |
| `4000 0025 0000 3155` | Requires 3D Secure |

See [Stripe Testing Docs](https://stripe.com/docs/testing) for more test cards.

---

## Project Structure

```
lib/
├── overbooked/
│   ├── accounts.ex           # User management
│   ├── contracts.ex          # Contract business logic (NEW)
│   ├── contracts/
│   │   └── contract.ex       # Contract schema (NEW)
│   ├── resources.ex          # Resource management (updated)
│   ├── resources/
│   │   └── resource.ex       # Resource schema (updated with pricing)
│   ├── scheduler.ex          # Booking logic
│   └── stripe.ex             # Stripe service (NEW)
│
└── overbooked_web/
    ├── controllers/
    │   └── stripe_webhook_controller.ex  # Webhook handler (NEW)
    ├── live/
    │   ├── spaces_live.ex               # Browse rentable spaces (NEW)
    │   ├── contracts_live.ex            # Manage contracts (NEW)
    │   └── contract_success_live.ex     # Payment success (NEW)
    └── plugs/
        └── fetch_raw_body.ex            # For webhook signatures (NEW)
```

---

## Database Migrations

New migrations for Stripe integration:

```bash
# Run migrations
mix ecto.migrate

# Rollback if needed
mix ecto.rollback
```

| Migration | Description |
|-----------|-------------|
| `20251219185500_add_pricing_to_resources` | Adds `is_rentable`, `monthly_rate_cents`, `description` to resources |
| `20251219185600_create_contracts` | Creates contracts table with Stripe payment fields |

---

## Configuration Files

| File | Purpose |
|------|---------|
| `config/config.exs` | Base Stripe config (API version) |
| `config/dev.exs` | Development Stripe config (uses env vars with defaults) |
| `config/runtime.exs` | Production Stripe config (requires env vars) |

---

## Troubleshooting

### "Could not start checkout" error
- Check that `STRIPE_SECRET_KEY` is set correctly
- Verify you're using test mode keys (start with `sk_test_`)

### Webhook events not being received
- Ensure `stripe listen` is running and forwarding to the correct URL
- Check that `STRIPE_WEBHOOK_SECRET` matches the CLI output
- Look at the terminal running `stripe listen` for errors

### No spaces showing on /spaces page
- Verify resources are marked as `is_rentable = true`
- Ensure `monthly_rate_cents` is set (not null)

### Contract not appearing after payment
- Check webhook was received (look at `stripe listen` terminal)
- Verify webhook secret is correct
- Check Phoenix server logs for errors

---

## Useful Commands

```bash
# Run tests
mix test

# Run specific test file
mix test test/overbooked/contracts_test.exs

# Format code
mix format

# Check for issues
mix credo

# Interactive console
iex -S mix

# Reset database
mix ecto.reset
```
