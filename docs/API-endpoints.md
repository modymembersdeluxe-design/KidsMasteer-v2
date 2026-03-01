# KidsMaster v2 API Endpoints (Quick Reference)

This document provides a practical reference for the most-used AJAX/API endpoints included in the KidsMaster v2 scaffold.

> Notes:
> - Most endpoints are session-authenticated and expect standard cookies.
> - Response envelopes generally follow `{ ok: boolean, error?: string, ... }`.
> - Validate permission/role checks server-side for all moderation/admin actions.

## `ajax/media_api.php`

### Actions

- `toggle_privacy`
- `delete`
- `enqueue_hls`
- `enqueue_thumbnail`
- `edit_meta`
- playlist actions (`playlist_add`, `playlist_remove`, etc.)

### Example: Toggle privacy

```http
POST /ajax/media_api.php
Content-Type: application/x-www-form-urlencoded

action=toggle_privacy&media_id=145&is_private=1
```

### Example response

```json
{
  "ok": true,
  "media_id": 145,
  "is_private": 1
}
```

---

## `ajax/editor_api.php`

Queue edit-related worker jobs.

### Actions

- `trim`

### Example

```http
POST /ajax/editor_api.php
Content-Type: application/json

{
  "action": "trim",
  "media_id": 145,
  "start": 3.25,
  "end": 19.5
}
```

---

## `ajax/remix_api.php`

Queue remix worker jobs.

### Actions

- `remix`

### Example

```http
POST /ajax/remix_api.php
Content-Type: application/json

{
  "action": "remix",
  "media_id": 145,
  "preset": "vhs_boost",
  "audio_mix": "retro"
}
```

---

## `ajax/admin_jobs_api.php`

Admin-only management endpoint for FFmpeg worker jobs in `encoding_jobs`.

### Actions

- `list`
- `retry`
- `requeue`
- `cancel`
- `delete`

### Example: retry

```http
POST /ajax/admin_jobs_api.php
Content-Type: application/x-www-form-urlencoded

action=retry&job_id=912
```

---

## `ajax/channel_actions.php`

Channel actions for subscriptions, channel moderation, and fallback chat send.

### Actions

- `subscribe`
- `unsubscribe`
- `chat_send`
- `archive_channel`
- `restore_channel`
- `reddit_stub_sync`

### Example: fallback chat send

```http
POST /ajax/channel_actions.php
Content-Type: application/x-www-form-urlencoded

action=chat_send&channel_id=15&message=hello+world
```

---

## `comment_post.php`

Comment create/delete/report endpoint.

### Actions

- post comment
- post reply (threaded)
- report comment
- delete comment (owner/mod/admin)

---

## `analytics.php`

Simple event tracking endpoint.

### Common events

- `record_view`
- `like`
- `share`
- custom event names for internal dashboards

---

## `api.php`

General listing/search and lightweight REST-style actions.

### Examples

- `GET /api.php?rest=chat_poll&channel_id=15&since=1700000000`
- `GET /api.php?rest=search&q=retro+music&type=video`

---

## Error handling guidance

- Return explicit status codes (400/401/403/404/429/500) with JSON payloads.
- Include user-safe messages; avoid leaking internals.
- Log detailed failures server-side with request IDs.

## Recommended next step

Export this endpoint catalog to OpenAPI 3.1 for stronger schema validation and SDK generation.
