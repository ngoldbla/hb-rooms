# 🍚 Overbooked

<a href="https://www.producthunt.com/posts/overbooked?utm_source=badge-featured&utm_medium=badge&utm_souce=badge-overbooked" target="_blank"><img src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=371582&theme=light" alt="Overbooked - Self&#0045;hosted&#0032;workplace&#0032;platform&#0032;for&#0032;indie&#0032;co&#0045;working&#0032;owners | Product Hunt" style="width: 250px; height: 54px;" width="250" height="54" /></a>

<img width="100%" alt="image" src="https://files.gitbook.com/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FXBpGv7Idn7C40VULL8H1%2Fuploads%2FZDxnzHzr2wVXP6l3TOF6%2Foverbooked-overview.gif?alt=media&token=d3e40a60-01d7-4375-b979-81338bba01c7">

Overbooked is a self-hosted flexible workplace platform for indie co-working owners.

<br>

**Docs:** https://overbookedapp.gitbook.io/docs/

<br>

## Deploy

### Methods

1. Clone repo, change configs, deploy to Fly.io
2. Run docker image
3. Deploy to Railway (see below)

### Railway Deployment

1. Create a new project on [Railway](https://railway.app)
2. Add a PostgreSQL database service
3. Connect your GitHub repository
4. Set the following environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | ✅ | PostgreSQL connection string (auto-set by Railway if using their Postgres) |
| `SECRET_KEY_BASE` | ✅ | Generate with `mix phx.gen.secret` |
| `PHX_HOST` | ✅ | Your app domain (e.g., `your-app.railway.app`) |
| `PHX_SERVER` | ✅ | Set to `true` |
| `STRIPE_SECRET_KEY` | ✅ | Stripe API secret key from [dashboard.stripe.com](https://dashboard.stripe.com/apikeys) |
| `STRIPE_WEBHOOK_SECRET` | ⚪ | Stripe webhook signing secret (for payment webhooks) |
| `SENDINBLUE_API_KEY` | ⚪ | Sendinblue API key for emails |
| `PORT` | ⚪ | Defaults to `4000` |
| `POOL_SIZE` | ⚪ | Database pool size, defaults to `10` |

5. Deploy! Railway will automatically run migrations via the pre-deploy command.

### Configs

1. Domain
2. Email provider

## Features

### Home

- [x] Upcoming reservations
- [ ] Who's coming today/tomorrow

### Schedule

- [x] Block unavalible resources
- [x] Reservations' Monthly view
- [x] Reservations' Weekly view
- [ ] Search available resources
- [ ] Timezones
- [ ] Reservations' visibility

### Rooms and Desks

- [x] Resources' colors
- [x] Resources' amenities
- [ ] Amenities' quantities
- [ ] Resources' capacity


### Admin

#### Resources

- [x] Manage rooms and desks
- [x] Manage amenities
- [x] Invite and manage users
- [x] Edit amenities and resources

#### Integrations

- [ ] Google calendar 2-way sync
- [ ] CSV import/export

#### Analytics

- [ ] Reservations overtime
- [ ] Most used resources
