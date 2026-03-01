# KidsMaster v2

KidsMaster v2 is a nostalgic, extensible media-sharing platform inspired by classic portals (Wenoo, VidLii, ZippCast, KidsTube) with a modern **"2025 reveal"** option.

This repository contains a full PHP + MySQL scaffold implementing a **Channels 1.5 Deluxe** feature set:

- Multi-type media support (video, audio, images, software, games, storage)
- Channels with PFP/GIF banner/background/theme choices
- SMS-style channel chat with emoji & country flags (WebSocket + fallback)
- Reddit integration stubs
- Live stream management (RTMP/HLS worker integration)
- Threaded comments
- Uploads with resumable chunking
- Background encoding workers (FFmpeg)
- Admin tooling including an encoding jobs dashboard

This README documents what the project includes, how to get it running locally, the main endpoints and tools, how to run the worker, and recommendations for production hardening.

## Table of contents

- [Features](#features)
- [Repo layout (high-level)](#repo-layout-high-level)
- [Requirements](#requirements)
- [Quick start (development)](#quick-start-development)
- [Database migrations & schema](#database-migrations--schema)
- [Uploads and media processing (workers)](#uploads-and-media-processing-workers)
- [WebSocket chat & Redis pub/sub](#websocket-chat--redis-pubsub)
- [Admin & moderation](#admin--moderation)
- [API endpoints (quick reference)](#api-endpoints-quick-reference)
- [CI & testing](#ci--testing)
- [Deployment notes (systemd / supervisor)](#deployment-notes-systemd--supervisor)
- [Security & production hardening checklist](#security--production-hardening-checklist)
- [Postman & API docs](#postman--api-docs)
- [Developer tools & notes](#developer-tools--notes)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Features

- **Channels 1.5 Deluxe**: per-channel profile picture (PFP), GIF banner support, background images, theme choice (deluxe/retro/modern), channel versioning, and owner controls.
- **SMS-style channel chat**: emoji, country-flag metadata, avatar support. Real-time via Ratchet WebSocket server with Redis pub/sub; HTTP fallback persists to DB.
- **Upload system**: client-side resumable chunking, server chunk assembly, file-type detection, thumbnail generation (GD/Imagick), and quota checks (example 512GB).
- **Media processing pipeline**: `encoding_jobs` table + worker (PHP CLI) that runs FFmpeg to generate thumbnails, HLS manifests, trims, and remixes.
- **Admin jobs dashboard**: view, retry, requeue, cancel, and delete encoding jobs.
- **Threaded comments, reports, moderation endpoints**, and an admin moderation dashboard scaffold.
- **Community features**: categories, groups, group membership, contact form, curated/special videos pages, and people directory.
- **Retro 2011 theme** with a 2025 reveal toggle (`assets/css/retro2011.css` + JS).
- **Legacy (IE7–11) compatibility layer** (`compat.js`) and fallback assets (`legacy.css`) for broad support.
- **CI checks & tests**: FFmpeg availability script and worker smoke test; GitHub Actions workflow example.
- **Useful tools**: setup wizard, test master diagnostic page, batch upload UI, editor/remix stubs, and many AJAX endpoints.

## Repo layout (high-level)

```text
_includes/                # bootstrap, header/footer helpers, core init
assets/
  css/                    # styles (style.css, retro2011, legacy, channel_1_5_deluxe)
  js/                     # client-side scripts (compat, retro, channel actions, upload widget, legacy fallbacks)
ajax/                     # AJAX endpoints (media_api.php, editor_api.php, remix_api.php, admin APIs...)
admin/                    # admin UI (jobs dashboard)
workers/                  # worker CLI script processing encoding_jobs
websockets/               # Ratchet WebSocket server scaffold
db/                       # schema and migrations
storage/                  # generated/served assets (uploads, hls, thumbs)
pages: index.php, channels.php, watch.php, videos.php, audio.php, images.php,
       software.php, games.php, storage.php, archive.php, community.php, etc.
docs/                     # API reference + Postman collection
tests/                    # CI/test scripts (ffmpeg check, worker smoke)
README.md                 # this file
```

## Requirements

- PHP 8.x (recommended)
- MySQL / MariaDB (8+ recommended)
- Composer (to install Ratchet and other libraries)
- FFmpeg installed on PATH (worker jobs)
- Optional: Redis + phpredis extension (for job pub/sub and cache)
- Webserver: Nginx/Apache or PHP built-in server for development

## Quick start (development)

1. Clone the project:

   ```bash
   git clone kidsmaster
   cd kidsmaster
   ```

2. Install composer dependencies (for WebSocket server):

   ```bash
   composer install
   ```

3. Configure environment variables (or edit `_includes/init.php` DB credentials):

   ```bash
   export KM_DB_HOST=127.0.0.1
   export KM_DB_NAME=kidsmaster
   export KM_DB_USER=km_user
   export KM_DB_PASS=km_pass
   ```

4. Create DB and import schema:

   ```bash
   # Create database and user first.
   mysql -u root -p kidsmaster < db/schema.sql
   mysql -u root -p kidsmaster < db/migrations/20251120_jobs_and_processing.sql
   # Import other migration files in db/migrations as needed.
   ```

5. Start the PHP built-in server for quick dev:

   ```bash
   php -S 127.0.0.1:8000
   ```

6. Visit `http://127.0.0.1:8000/setup.php` and create an admin user with the setup wizard.
   This creates a default channel and seeds categories.

## Database migrations & schema

- Main schema file: `db/schema.sql`
  - Base tables: users, channels, media, comments, chat_messages, storage_files, playlists, etc.
- Jobs migration: `db/migrations/20251120_jobs_and_processing.sql`
  - Adds `encoding_jobs`, `hls_url`, and duration-related fields.
- Channel/chat metadata migrations:
  - `db/migrations/20251119_add_channel_chat_and_archive.sql`
  - `db/migrations/20251120_channel_chat_pubsub.sql`
  - Adds `channels.archived`, `chat_messages.channel_id`, `country_code`, `user_avatar`.

Run migrations in sequence and back up your DB before applying changes.

## Uploads and media processing (workers)

- Chunked upload endpoint: `upload.php`
  - Accepts chunked uploads, assembles file, runs basic MIME validation and thumbnail generation.
- Finalize endpoint: `ajax/upload_finalize.php`
  - Creates media DB record referencing uploaded file.
- Background worker: `workers/worker.php`
  - Consumes Redis queue `kidsmaster:jobs` (`BRPOP`) or polls `encoding_jobs` table and runs FFmpeg for:
    - HLS packaging (`hls` job)
    - Thumbnail generation (`thumbnail` job)
    - Trim operation (`trim` job)
    - Remix (`remix` job)

Queue work via `enqueue_hls` and `enqueue_thumbnail` in `ajax/media_api.php`.

Outputs are stored under `/storage/` (hls, thumbs, trims, remix), and media rows are updated with `hls_url`, `thumbnail`, and `processed` flags.

## WebSocket chat & Redis pub/sub

- WebSocket server: `websockets/chat-server.php` (Ratchet), room-aware by `channel_id`
- Broadcast payload metadata includes:
  - `user_name`
  - `user_avatar`
  - `country_code`
  - `message`
- Production recommendation:
  - Run WebSocket server as a supervised process
  - Use Redis pub/sub to share messages across multiple WS instances
- Client integration:
  - Connect via `KMWebSocket` (`compat.js`)
  - Poll fallback: `/api.php?rest=chat_poll`

## Admin & moderation

- Admin Jobs Dashboard:
  - `admin/jobs.php`
  - `ajax/admin_jobs_api.php`
  - Supports view, retry, requeue, cancel, and delete job actions
- Moderation scaffolding:
  - Comment reports
  - Archive/restore channels
  - Delete comments
  - Server-side moderation checks
- Developer utilities:
  - `testmaster.php` for diagnostics
  - `user_fix.php` for storage recalculation

## API endpoints (quick reference)

- `ajax/media_api.php`
  - `toggle_privacy`, `delete`, `enqueue_hls`, `enqueue_thumbnail`, `edit_meta`, playlist actions
- `ajax/editor_api.php`
  - Enqueue `trim` jobs
- `ajax/remix_api.php`
  - Enqueue `remix` jobs
- `ajax/admin_jobs_api.php`
  - Admin job management actions
- `ajax/channel_actions.php`
  - subscribe/unsubscribe, `chat_send` fallback, archive/restore channel, reddit stub
- `comment_post.php`
  - Comment posting, reporting, deletion
- `analytics.php`
  - `record_view` and generic events
- `api.php`
  - Listing, search, and lightweight channel/search actions

See `docs/API-endpoints.md` and `docs/postman_collection.json` for examples.

## CI & testing

Included scripts:

- `tests/ci_check_ffmpeg.sh` — verifies FFmpeg presence
- `tests/ci_worker_smoke.sh` — inserts a test encoding job to validate DB insertion

Example GitHub Actions workflow:

- `.github/workflows/ci.yml`
  - runs FFmpeg check and worker smoke test with a MySQL service

Recommended enhancements:

- Add PHP lint/static analysis
- Add integration tests with seeded DB and Redis
- Add endpoint-level API tests

## Deployment notes (systemd / supervisor)

Two recommended ways to supervise the worker:

1. **systemd**
   - Unit: `systemd/kidsmaster-worker.service`
   - Install and enable:

     ```bash
     sudo systemctl daemon-reload
     sudo systemctl enable --now kidsmaster-worker.service
     ```

2. **Supervisor**
   - Config: `supervisor/kidsmaster-worker.conf`
   - Place under `/etc/supervisor/conf.d/` and reload supervisor

Ensure worker runs as a user with write access to storage files (for example `www-data`).

If using WebSocket server, supervise `websockets/chat-server.php` similarly.

## Security & production hardening checklist

- Use HTTPS for all traffic
- Set secure session cookie flags: `Secure`, `HttpOnly`, `SameSite`
- Implement rate limiting on login/signup/upload/comment endpoints
- Add email verification and password reset flows before production
- Scan uploaded files and enforce strict MIME validation
- Consider sandboxed processing workers for untrusted uploads
- Serve media via CDN or signed URLs for private content
- Avoid serving raw uploads directly from webroot
- Move heavy FFmpeg jobs to dedicated worker nodes
- Keep web app nodes stateless where possible
- Use Redis for caching and pub/sub in multi-node deployments
- Add robust moderation roles, dashboards, and moderation action logging

## Unit tests & CI recommendations

Already included:

- `tests/ci_check_ffmpeg.sh`
- `tests/ci_worker_smoke.sh`

Recommended additions:

- Unit tests for API endpoints (PHPUnit + test DB)
- Integration tests for chunked upload + finalize flow
- Worker unit tests with small fixtures or FFmpeg stubs
- Extended CI matrix with MySQL + Redis services

## Postman & API docs

- `docs/postman_collection.json` contains sample requests (toggle privacy, enqueue HLS, trim)
- `docs/API-endpoints.md` summarizes AJAX endpoints and payload/response shapes
- Consider exporting full OpenAPI/Swagger docs for machine-readable integration support

## Developer tools & notes

- Use `testmaster.php` for diagnostics and quick SQL during development
- `setup.php` is a one-time setup wizard for admin creation and category seeding
  - Creates `storage/.setup_done` lock file to prevent reruns
- Retro theme (`assets/css/retro2011.css` + `assets/js/retro2011.js`) is optional
  - Toggle per channel or site-wide

## Contributing

Contributions are welcome.

- Open issues for bugs and feature requests
- For code changes:
  - Fork the repo
  - Create a topic branch
  - Open a pull request
  - Include schema migrations when needed
  - Include tests for new features when possible

## License

No license file is included by default.

Add a `LICENSE` file (for example MIT) if you intend to open source this scaffold.

## Acknowledgements

This scaffold builds on common open-source tools and ecosystems, including:

- PHP
- PDO
- Ratchet (WebSocket)
- FFmpeg
- Redis
- GD/Imagick

---

I packaged a complete README that documents the Channels 1.5 Deluxe features, installation steps, worker/encoding architecture, admin workflows, and CI checks.

Next options:

- **A)** More comprehensive OpenAPI/Swagger docs
- **B)** A full Postman collection with authentication flows included
- **C)** Automated database migration scripts (combined + idempotent) for production

Which one would you like next?
