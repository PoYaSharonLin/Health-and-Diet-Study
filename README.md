# Survey User Behavior Tracking

A full-stack survey website with fine-grained user behavior tracking.

- **Backend**: Ruby (Roda + Sequel ORM) with Domain-Driven Design architecture
- **Frontend**: Vue 3 + Vue Router + Element Plus UI
- **Build**: Webpack
- **Tracking**: Pixel-level mouse movement, clicks, text highlights, hover, scroll, and custom slider interactions

Users arrive via a unique URL (`?uid=…`). The app records their session and all behavior events, and exposes a `share_url` API so other applications can retrieve the tracked URL by user ID.

The backend follows a **Domain-Driven Design (DDD)** architecture, mirroring the patterns established in [Tyto](../tyto).

## Setup

**Requirements:** Ruby 3.4+, Node.js 20+

1. Install dependencies and copy config templates:

   ```shell
   rake setup
   ```

2. Configure `backend_app/config/secrets.yml`:
   - `DATABASE_URL` is pre-filled for SQLite (dev/test). No changes needed to get started.

3. Setup databases:

   ```shell
   bundle exec rake db:setup                 # Development database
   RACK_ENV=test bundle exec rake db:setup   # Test database
   ```

4. Configure `frontend_app/.env.local` (optional):
   - `VUE_APP_BASE_URL`: Override the base URL used in generated `share_url` values (default: `http://localhost:8080`)

> **Note:** If you encounter `SQLite3::CantOpenException`, run:
> ```shell
> sudo chown -R $USER backend_app/db/store/
> ```

## Running Locally

Start both servers in separate terminals:

```shell
# Terminal 1: Frontend (webpack dev server with hot reload)
rake run:frontend

# Terminal 2: Backend API server
rake run:api
```

Then open <http://localhost:9292/survey?uid=your-user-id> in your browser (the backend port). The backend serves both the API and the frontend files from `dist/`.

## How It Works

1. A user receives a link such as `http://your-domain.com/survey?uid=abc-123`
2. On load, the app reads `uid` from the URL, stores it in `localStorage`, and registers a session with the backend
3. All interactions (mouse movement, clicks, text highlights, hover, scroll, slider changes) are captured and batched to the backend every 300 ms
4. Other applications can call `GET /api/survey/session/:respondent_id` to retrieve the `share_url` containing the user ID

## API Reference

### Session

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/survey/session` | Create or resume a session (`{ respondent_id, original_url }`) |
| `GET` | `/api/survey/session/:respondent_id` | Get session details including `share_url` |

### Behavior Events

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/behavior/:respondent_id/events` | Record a batch of events (`{ events: [...] }`) |

**Tracked event types:** `mousemove`, `click`, `highlight`, `hover`, `scroll`, `slider`

## Testing

```shell
bundle exec rake spec    # Run all backend tests
bundle exec rake         # Same (default task)
```

Ensure the test database is set up first:

```shell
RACK_ENV=test bundle exec rake db:setup
```

## Database Commands

```shell
bundle exec rake db:migrate     # Run pending migrations
bundle exec rake db:setup       # Migrate
bundle exec rake db:reset       # Drop + migrate (destructive)
bundle exec rake db:drop        # Delete database (destructive)
```

## Inspecting uploaded S3 data

Session event blobs are uploaded to S3 under `behavior_data/`. The bucket name
is read from `S3_BUCKET_NAME` in `backend_app/config/secrets.yml`. Requires the
`aws` CLI on `PATH` with credentials configured.

```shell
# List all uploaded sessions
bundle exec rake s3:list

# Sync all sessions to ./data/
bundle exec rake s3:sync

# Sync to a custom destination
bundle exec rake "s3:sync[./mydata/]"
```

## Production

Set `DATABASE_URL` to a PostgreSQL connection string in `secrets.yml` or as an environment variable. For high-volume event data, [TimescaleDB](https://www.timescale.com/) is a drop-in upgrade — no application code changes required:

```sql
CREATE EXTENSION IF NOT EXISTS timescaledb;
SELECT create_hypertable('behavior_events', 'timestamp');
```

## Debug Panel

The live-event debug overlay (`DebugOverlay.vue`) is disabled by default. To re-enable it on the survey page:

1. Open `frontend_app/pages/SurveyPage.vue`.
2. In `<script>`, add the import:
   ```js
   import DebugOverlay from '@/components/DebugOverlay.vue';
   ```
3. Register the component:
   ```js
   components: { BehaviorTracker, SliderBar, DebugOverlay },
   ```
4. In `<template>`, add `<DebugOverlay />` as the first child of `.survey-wrapper` (before `<BehaviorTracker>`):
   ```html
   <div class="survey-wrapper" data-track="page-background">
     <DebugOverlay />
     <BehaviorTracker>
   ```

The overlay renders in the bottom-right corner, shows up to 200 live tracking events, and can be cleared or dismissed via its own buttons.

## Key Dependencies

**Backend:**

- [Roda](https://roda.jeremyevans.net/) — Routing
- [Sequel](https://sequel.jeremyevans.net/) — Database ORM
- [dry-struct](https://dry-rb.org/gems/dry-struct/) — Domain entities
- [dry-operation](https://dry-rb.org/gems/dry-operation/) — Railway-oriented services
- [Roar](https://github.com/trailblazer/roar) — JSON representers

**Frontend:**

- [Vue 3](https://vuejs.org/)
- [Element Plus](https://element-plus.org/) — UI components
- [Axios](https://axios-http.com/) — HTTP client
