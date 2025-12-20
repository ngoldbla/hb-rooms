# Railway Deployment Guide

This guide covers deploying Hatchbridge Rooms to [Railway](https://railway.app).

## Prerequisites

- Railway account (sign up at [railway.app](https://railway.app))
- GitHub repository with this code
- Stripe account with production API keys

## Quick Deploy

### 1. Create Project

1. Go to [railway.app](https://railway.app) → **New Project**
2. Select **Deploy from GitHub repo**
3. Select the `hb-rooms` repository

### 2. Add PostgreSQL

1. In project dashboard, click **+ New** → **Database** → **PostgreSQL**
2. Railway automatically creates `DATABASE_URL`

### 3. Configure Variables

In your app service, go to **Variables** and add:

```
SECRET_KEY_BASE=<run: mix phx.gen.secret>
PHX_HOST=your-app.up.railway.app
PHX_SERVER=true
PORT=4000
POOL_SIZE=10
STRIPE_SECRET_KEY=sk_live_xxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxx
```

**Link DATABASE_URL**: Click "Add Reference" → PostgreSQL → DATABASE_URL

Note: `DATABASE_URL` should end up as a full Postgres URL (starting with `postgres://` or `postgresql://`). If you see a literal template like `{{Postgres.DATABASE_URL}}` or you manually prefixed `postgresql://` in front of a referenced URL, migrations will fail.

### 4. Deploy

Railway will automatically:
- Build using the Dockerfile
- Run migrations via `/app/bin/migrate`
- Start the server via `/app/bin/server`

### 5. Get Your Domain

1. Go to **Settings** → **Networking**
2. Click **Generate Domain**
3. Update `PHX_HOST` to match

## Stripe Webhook Setup

1. Go to [Stripe Webhooks](https://dashboard.stripe.com/webhooks)
2. Click **Add endpoint**
3. URL: `https://your-app.up.railway.app/webhooks/stripe`
4. Events: `checkout.session.completed`, `payment_intent.succeeded`
5. Copy the signing secret to `STRIPE_WEBHOOK_SECRET`

## Email (Mailgun)

To enable transactional email (invites, password resets, etc.) with Mailgun, follow:

- `docs/MAILGUN_RAILWAY.md`

## Seed Data

After deployment, make resources rentable:

```bash
# Install Railway CLI
npm install -g @railway/cli
railway login
railway link

# Seed rentable resources
railway run mix run -e '
alias Overbooked.{Repo, Resources.Resource}
import Ecto.Query
room = Repo.one(from r in Resource, limit: 1)
room |> Ecto.Changeset.change(%{is_rentable: true, monthly_rate_cents: 50000, description: "Private office"}) |> Repo.update!()
'
```

## Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `SECRET_KEY_BASE` | ✅ | Phoenix secret (64 chars) |
| `DATABASE_URL` | ✅ | Auto-linked from PostgreSQL |
| `PHX_HOST` | ✅ | Your Railway domain |
| `PHX_SERVER` | ✅ | Set to `true` |
| `PORT` | Recommended | Default: 4000 |
| `STRIPE_SECRET_KEY` | ✅ | Stripe secret key |
| `STRIPE_WEBHOOK_SECRET` | ✅ | Stripe webhook signing secret |
| `MAILGUN_API_KEY` | Recommended | Mailgun private API key (fallback if in-app email settings are disabled) |
| `MAILGUN_DOMAIN` | Recommended | Mailgun sending domain (fallback if in-app email settings are disabled) |

## Troubleshooting

**App won't start**: Check `SECRET_KEY_BASE` is set and 64+ characters

**Database errors**: Ensure `DATABASE_URL` is linked from PostgreSQL service

**Payments not working**: Verify `STRIPE_WEBHOOK_SECRET` matches Stripe dashboard

**Migrations failed**: Check deploy logs; run `/app/bin/migrate` manually via Railway shell
