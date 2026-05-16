# Hustlers Backend

A FastAPI-powered marketplace backend API with authentication, sellers, products, orders, payments, messaging, and real-time features.

## Tech Stack

- **Framework**: FastAPI
- **Database**: PostgreSQL with SQLAlchemy + Alembic
- **Auth**: JWT with Google OAuth support
- **Realtime**: Ably
- **Payments**: Paystack
- **Email**: Resend / SMTP
- **Images**: Cloudinary
- **Maps**: Google Maps / Geoapify
- **Monitoring**: Sentry

## Getting Started

### Prerequisites

- Python 3.14+
- PostgreSQL
- uv (package manager)

### Setup

1. Clone the repository:

```bash
git clone <repository-url>
cd hustlers_backend
```

2. Install dependencies:

```bash
uv sync
```

3. Copy environment file and configure variables:

```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Run database migrations:

```bash
uv run task migrate
```

5. Start the development server:

```bash
uv run task dev
```

The API will be available at `http://localhost:8000`. API documentation is at `http://localhost:8000/docs`.

### Local Development with Paystack

When running the project locally, you need to set up Paystack webhooks:

1. Use a tunneling service (e.g., [ngrok](https://ngrok.com), [localtunnel](https://localtunnel.github.io/www/), or [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps)) to expose your local server to the internet:

   ```bash
   # Example using ngrok
   ngrok http 8000
   ```

2. Copy the forwarded URL (e.g., `https://abc123.ngrok.io`)

3. Set up your Paystack webhook URL in the [Paystack Dashboard](https://dashboard.paystack.com):
   - Go to Settings → Webhooks
   - Add your forwarded URL + `/api/v1/payments/webhook` (e.g., `https://abc123.ngrok.io/api/v1/payments/webhook`)
   - Copy your webhook secret and add it to your `.env` file as `PAYSTACK_WEBHOOK_SECRET`

### Available Commands

| Task           | Command                 |
| -------------- | ----------------------- |
| Run dev server | `uv run task dev`       |
| Run production | `uv run task start`     |
| Run tests      | `uv run task test`      |
| Run lint       | `uv run task lint`      |
| Run format     | `uv run task format`    |
| Run typecheck  | `uv run task typecheck` |

## Running GitHub Actions Locally

This project uses [act](https://github.com/nektos/act) to run GitHub Actions workflows locally using Docker.

### Prerequisites

- Docker installed and running
- `docker-compose.act.yml` file in the project root

### Commands

Run all push workflows:

```bash
docker compose -f docker-compose.act.yml run act
```

Run a specific job:

```bash
ACT_ARGS="-j test" docker compose -f docker-compose.act.yml run act
```

Pass secrets (for workflows that require them):

```bash
ACT_ARGS="-j test --secret-file .secrets" docker compose -f docker-compose.act.yml run act
```

Create a `.secrets` file with your GitHub secrets in the format `KEY=VALUE` (one per line).

## Deployment

### Render.com

1. Create a new Web Service on Render
2. Link your repository
3. Set the **Start Command** to:
   ```bash
   alembic upgrade head && gunicorn src.main:app -k uvicorn.workers.UvicornWorker
   ```
4. Add your environment variables (copy from `.env.example` and fill in your values)
5. Ensure `DATABASE_URL` is set (Render's managed Postgres will auto-set this)

The `start` task runs `alembic upgrade head && uv run gunicorn app.main:app -k uvicorn.workers.UvicornWorker`, which uses Gunicorn with Uvicorn workers for production deployment.

## Remaining Tasks

- [ ] Configure Google OAuth credentials in Google Cloud Console - Add your Google Client ID and Client Secret to the `.env` file under `GOOGLE_CLIENT_IDS`. Follow [Google's OAuth setup guide](https://developers.google.com/identity/protocols/oauth2) to create credentials.

## Frontend Setup

### Ably Realtime

This backend uses Ably for real-time features. To configure the frontend:

1. Create an Ably account at [https://ably.com](https://ably.com)
2. Create an Ably app and get your API keys
3. Add the following to your frontend environment:
   - `ABLY_API_KEY`: Your Ably API key (server-side only, never expose publicly)
   - `ABLY_SUBSCRIBE_KEY`: Your Ably subscribe key for client-side connections

For client-side authentication, generate tokens server-side using the `/api/v1/auth/ably/token` endpoint and use the [Ably Flutter SDK](https://github.com/ably/ably-flutter) to connect.

For more details, see:

- [Ably Documentation](https://ably.com/docs)
- [Ably Flutter SDK](https://github.com/ably/ably-flutter)
- [Ably Flutter Getting Started](https://ably.com/docs/getting-started/flutter)
- [Ably Auth Best Practices](https://ably.com/docs/auth)
