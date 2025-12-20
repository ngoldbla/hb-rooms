# Mailgun Email Setup (Railway)

This guide covers configuring Mailgun for transactional email (invites, password resets, etc.) when this app is deployed on Railway.

The app can send email in two ways:

1. **Admin UI (recommended):** Configure Mailgun + “From” address in the app at `/admin/settings` (saved in the database; no redeploy needed).
2. **Railway variables (fallback):** Configure Mailgun via `MAILGUN_API_KEY` / `MAILGUN_DOMAIN` environment variables.

## Prerequisites

- Deployed on Railway (see `docs/RAILWAY_DEPLOY.md`)
- A Mailgun account
- A verified Mailgun sending domain (or a Mailgun sandbox domain for testing)

## 1) Create + verify a Mailgun sending domain

1. In Mailgun, go to **Sending** → **Domains** → **Add New Domain**
2. Choose a sending domain (commonly a subdomain like `mg.yourdomain.com`)
3. Add the DNS records Mailgun provides (SPF/DKIM/MX/CNAME) to your DNS provider
4. Wait for Mailgun to mark the domain as **Verified**

## 2) Get your Mailgun API key

1. In Mailgun, go to **Settings** → **API Keys**
2. Copy the **Private API key** (it usually looks like `key-...`)

## 3) Configure Mailgun in Railway (recommended as a fallback)

In Railway, open your app service → **Variables**, then set:

- `MAILGUN_API_KEY` = your Mailgun **Private API key** (mark as a secret)
- `MAILGUN_DOMAIN` = your verified Mailgun domain (example: `mg.yourdomain.com`)

If you only use the Admin UI method below, these variables are optional, but keeping them set provides a safe fallback if email settings are later disabled in-app.

## 4) Configure email in the app (recommended)

1. Sign in to the app
2. Visit `https://<your-domain>/admin/settings`
3. Under **Email Settings**:
   - Toggle **Enable email sending**
   - Set **Mailgun API Key** (Private API key)
   - Set **Mailgun Domain** (verified domain)
   - Set **From Name** (example: `Hatchbridge Rooms`)
   - Set **From Email** (must be from your verified Mailgun domain, example: `noreply@mg.yourdomain.com`)
4. Click **Save Settings**
5. Click **Send Test Email** to verify delivery (sends to the currently signed-in user)

## Troubleshooting

- **401 / unauthorized**: Make sure you used the Mailgun **Private** API key (not a public key).
- **Emails not arriving**: Verify the domain is marked **Verified** in Mailgun and that your DNS records have propagated.
- **“From” address rejected**: Ensure the **From Email** domain matches the Mailgun domain you configured.
- **No “Send Test Email” button**: Enable email sending and save settings first.
