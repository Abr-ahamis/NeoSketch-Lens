# AGENTS.md: SketchLens (Sketch Overlay Drawing App)

> This file is the single source of truth for AI coding agents (Codex, Claude Code, others) and for humans.
> Read it fully before changing anything. Work through the **Task Board (section 14)** in order.
> Never commit secrets. Never send user images to any server.

---

## 1. Project Summary

**SketchLens** is a mobile app that:
1. Imports an image (gallery or camera) and converts it to a sketch / line drawing.
2. Opens the live camera and projects the sketch over the real world, on top of the user's paper.
3. Lets the user mark the paper (4 draggable corners), pick the real paper size (A4, Letter, ...), and fits the sketch to it with a perspective transform so the user can draw by hand.
4. Sends anonymous diagnostics (crashes, performance, usage events, feedback) to the owner's own server, which stores them and forwards important ones to the owner's **Telegram bot**.

### Goals
- G1: Reliable image to sketch conversion, fully on-device and offline.
- G2: Accurate overlay alignment (target error under 3 mm on an A4 sheet).
- G3: Smooth camera overlay (30 fps on mid-range Android).
- G4: Full observability: crash, performance, usage and feedback data reach the owner's server and Telegram.
- G5: Privacy by design: consent toggle, no PII, no user images ever leave the device.

### Non-goals (for now)
- No user accounts or cloud storage of drawings.
- No social features.
- No server-side image processing.

---
### refarance file ChatGPT_ Chat, Work, Create & Code with AI.html
### use this to as a base file system and change it to the project "fuckyounati.zip "
## 2. Tech Stack

| Layer | Choice | Notes |
|-------|--------|-------|
| App | **Flutter** (stable channel), Dart | Android first, iOS later |
| State | Riverpod | |
| Image processing | OpenCV via `opencv_dart` (FFI) | Fallback: custom FFI/C++ if needed |
| Camera | `camera` package | Overlay drawn with Flutter `Transform` + `Matrix4` |
| Local DB | `drift` (SQLite) | Projects + telemetry queue |
| HTTP | `dio` | Retry + gzip |
| Background flush | `workmanager` | Batch upload |
| Device info | `device_info_plus`, `package_info_plus`, `connectivity_plus` | |
| Sensors | `sensors_plus` | Tilt indicator |
| Keep awake | `wakelock_plus` | |
| Server | **Python 3.12 + FastAPI** | |
| Server DB | PostgreSQL | SQLite acceptable for local dev |
| Server ORM/migrations | SQLAlchemy 2 + Alembic | |
| Telegram | Bot API via `httpx` | Server-side only |
| Deploy | Docker Compose + Caddy (auto HTTPS) | |
| Dashboard (optional) | Grafana on PostgreSQL | |

Use the latest stable version of each package. Check pub.dev / PyPI and pin exact versions in lockfiles. Do not invent APIs; read the package docs when unsure.

---

## 3. Repository Layout

```
sketchlens/
├─ AGENTS.md                  <- this file
├─ CLAUDE.md                  <- points to AGENTS.md
├─ README.md
├─ app/                       <- Flutter app
│  ├─ lib/
│  │  ├─ main.dart            <- error hooks, app bootstrap
│  │  ├─ core/                <- constants, theme, utils, result types
│  │  ├─ features/
│  │  │  ├─ home/
│  │  │  ├─ import_image/
│  │  │  ├─ sketch_editor/    <- styles, sliders, preview
│  │  │  ├─ paper_setup/      <- presets, custom size, orientation
│  │  │  ├─ camera_overlay/   <- live preview, corners, overlay controls
│  │  │  ├─ projects/         <- saved list
│  │  │  ├─ feedback/         <- in-app feedback modal
│  │  │  └─ settings/         <- units, theme, telemetry consent
│  │  ├─ processing/          <- sketch pipeline (OpenCV wrappers)
│  │  ├─ geometry/            <- homography, corner ordering, fitting, detection
│  │  ├─ data/                <- drift DB, repositories, file storage
│  │  └─ telemetry/           <- SDK: events, errors, perf, queue, uploader
│  ├─ test/
│  └─ integration_test/
├─ server/                    <- FastAPI telemetry server
│  ├─ app/
│  │  ├─ main.py
│  │  ├─ api/                 <- routers: register, telemetry, feedback, health
│  │  ├─ core/                <- config, security, rate limiting
│  │  ├─ models/              <- SQLAlchemy models
│  │  ├─ schemas/             <- Pydantic schemas
│  │  ├─ services/            <- fingerprinting, telegram notifier, digests
│  │  └─ workers/             <- background tasks
│  ├─ alembic/
│  ├─ tests/
│  ├─ Dockerfile
│  └─ pyproject.toml
├─ deploy/
│  ├─ docker-compose.yml
│  ├─ Caddyfile
│  └─ .env.example
├─ prototypes/                <- Python OpenCV prototypes (sketch + homography)
└─ docs/                      <- plan, API spec, privacy policy draft
```

---

## 4. Setup and Install

### 4.1 Machine prerequisites (Linux / Ubuntu)
```bash
# Flutter SDK (follow https://docs.flutter.dev/get-started/install/linux), then:
flutter doctor            # fix everything it reports
sudo apt install -y git curl unzip clang cmake ninja-build pkg-config libgtk-3-dev
# Android Studio or command-line Android SDK + accept licenses:
flutter doctor --android-licenses

# Server side
sudo apt install -y python3.12 python3.12-venv postgresql docker.io docker-compose-plugin
```

### 4.2 Bootstrap the repo
```bash
mkdir sketchlens && cd sketchlens && git init
flutter create --org com.abrahamis --project-name sketchlens app
mkdir -p server deploy prototypes docs
python3 -m venv server/.venv && source server/.venv/bin/activate
pip install fastapi "uvicorn[standard]" sqlalchemy alembic psycopg[binary] pydantic-settings httpx pytest ruff
cd app && flutter pub add flutter_riverpod opencv_dart camera image_picker dio drift sqlite3_flutter_libs path_provider workmanager device_info_plus package_info_plus connectivity_plus sensors_plus wakelock_plus uuid
flutter pub add --dev drift_dev build_runner flutter_lints mocktail
```
If a package name or version fails to resolve, check pub.dev and adapt. Do not leave the project in a broken state.

### 4.3 Common commands
| Task | Command |
|------|---------|
| Run app | `cd app && flutter run` |
| Analyze | `cd app && flutter analyze` |
| Test app | `cd app && flutter test` |
| Codegen (drift) | `cd app && dart run build_runner build --delete-conflicting-outputs` |
| Run server | `cd server && uvicorn app.main:app --reload` |
| Test server | `cd server && pytest` |
| Lint server | `cd server && ruff check . && ruff format .` |
| Migrate DB | `cd server && alembic upgrade head` |
| Full stack deploy | `cd deploy && docker compose up -d --build` |

Agents must run analyze + tests before declaring any task done.

---

## 5. Agent Skills and Capabilities Needed

An agent working on this repo needs competence in:
- **Flutter/Dart:** Riverpod, platform channels, FFI, CustomPainter, `Matrix4` transforms.
- **Computer vision (OpenCV):** grayscale, Gaussian blur, color dodge, Canny, XDoG, contours, `approxPolyDP`, `getPerspectiveTransform`, `warpPerspective`.
- **Geometry:** homography, corner ordering (TL, TR, BR, BL), aspect-ratio fitting (contain/fill).
- **Android camera:** permissions, preview aspect ratio, lifecycle.
- **Local persistence:** drift/SQLite migrations, durable queues.
- **Backend:** FastAPI, Pydantic validation, SQLAlchemy, Alembic, rate limiting, HMAC auth.
- **Telegram Bot API:** `sendMessage`, MarkdownV2/HTML escaping, rate limits.
- **DevOps:** Docker Compose, Caddy HTTPS, env-based secrets.
- **Privacy/security:** PII scrubbing, consent, GDPR/CCPA basics.

### Suggested agent setup
- **Claude Code:** keep this file as `AGENTS.md` and `CLAUDE.md` containing `@AGENTS.md`. Optionally add project subagents in `.claude/agents/` (e.g. `flutter-dev`, `cv-engineer`, `backend-dev`, `reviewer`) and a slash command `/verify` that runs analyze + tests.
- **Codex:** reads `AGENTS.md` automatically. Run it from the repo root. Nested `AGENTS.md` files may be added in `app/` and `server/` for stack-specific rules.

---

## 6. Core Feature Specs

### 6.1 Image to Sketch (`app/lib/processing/`)
Pipeline (pencil style):
1. Decode image, downscale preview to max 1024 px for slider interaction (full resolution only on save/export).
2. Grayscale, invert, Gaussian blur (kernel odd, user-controlled), color dodge: `out = gray * 256 / (255 - blurredInv)` (clamp, avoid div by zero).
3. Optional contrast/brightness, optional invert (white lines on black).

Other styles: `Canny` outline, `XDoG` ink, adaptive-threshold comic.
Controls: style, blur radius, line thickness, contrast, detail, invert.
Requirements: runs in an isolate (never block UI), result cached, deterministic, offline.

**Acceptance:** 10 sample images in `app/test/assets/` produce visually acceptable output; preview updates under 300 ms at 1024 px.

### 6.2 Paper Setup
- Presets: A5, A4, A3, Letter, Legal, Square; custom width/height in mm or inches; portrait/landscape.
- Store as `PaperSize(name, widthMm, heightMm)`.

### 6.3 Camera Overlay and Paper Selection
- Live camera preview with the sketch drawn on top using `Transform` with a `Matrix4` built from the homography.
- 4 draggable corner handles with a magnifier loupe, ordered TL, TR, BR, BL.
- Homography: map `dst = [(0,0),(W,0),(W,H),(0,H)]` (paper space, aspect from paper size) to `src` = corner points in preview coordinates. Fit sketch inside paper rect (contain by default, fill option), allow user pan/zoom inside the paper.
- Controls: opacity, blend mode (multiply), flip H/V, rotate 90, lock (disables gestures), flashlight, grid toggle, keep-screen-awake.
- Tilt indicator via accelerometer: warn if phone is not roughly parallel to the paper.
- Level 0 (MVP): fixed overlay, phone on a stand. Show onboarding hint.
- Level 1 (v2): auto paper detection (`findContours` on edges, largest convex quad via `approxPolyDP`) with user confirmation, temporal smoothing.
- Level 2+ (later): feature tracking (ORB/optical flow) or ARCore anchoring for occlusion-tolerant tracking.

**Acceptance:** printed A4 sketch laid on the paper matches overlay within 3 mm in a test with the phone on a stand.

### 6.4 Projects
Save/restore: original image path, sketch settings, paper size, corner points, overlay transform, timestamps, thumbnail. List, open, rename, delete.

---

## 7. Extra Improvements and Ideas (backlog, in priority order)

1. **Onboarding tutorial** (3 cards) and a "good photo" tips screen.
2. **Print/export at real size** (PDF at exact paper dimensions) for light-box tracing.
3. **Grid overlay** with adjustable rows/columns for the grid drawing method.
4. **Simplify / beginner mode**: reduce detail, show big shapes first, then add layers.
5. **Layered reveal**: show the sketch in steps (outline, midtones, details).
6. **Auto paper detection** and stabilization.
7. **Lens/perspective guidance**: tilt and distance warnings, "hold steady" hint when tracking is lost.
8. **Progress timelapse**: periodic camera frames compiled locally (opt-in).
9. **Compare mode**: swipe between the overlay and your current drawing to see progress.
10. **Low-light assist**: auto flashlight prompt, contrast boost for overlay.
11. **ML line-art model** (TFLite/ONNX) for better photo to sketch quality.
12. **Accessibility:** large touch targets, screen reader labels, high contrast theme.
13. **Localization** (English, Amharic, others) via Flutter `intl`.
14. **Haptics** when corners snap, subtle sound on lock.
15. **Battery saver** mode: lower preview frame rate, dim UI.

---

## 8. Telemetry and Observability (App Side)

All telemetry code lives in `app/lib/telemetry/`. It must be usable with one call site: `Telemetry.instance.track(...)`.

### 8.1 Consent and privacy rules (MUST)
- First launch shows a clear consent screen. Defaults to **off for analytics, on for crash reports** only if the owner decides, and always user-changeable in Settings. If consent is off, nothing is sent and the queue is cleared.
- Never send: images, sketches, file paths, names, emails, phone numbers, precise location, advertising IDs, free text beyond the feedback form.
- Scrub PII from error messages and stack traces (emails, tokens, paths containing the username) before queueing.
- Use a random `install_id` (UUIDv4) generated on first run. Rotate/reset option in Settings ("Reset analytics ID").
- Provide "Delete my data" that asks the server to delete rows for `install_id`.

### 8.2 What to capture

**A. Errors and crashes**
- Hooks in `main.dart`: `FlutterError.onError`, `PlatformDispatcher.instance.onError`, `runZonedGuarded`. Also catch isolate errors (`Isolate.current.addErrorListener`) and native crashes via a native crash handler or Firebase Crashlytics/Sentry if added.
- Fields: `type`, `message`, `stack_trace`, `fatal`, `screen`, `app_state` (small enums only), `session_id`, `app_version`, `build`, `os`, `os_version`, `device_model`, `locale`, `free_ram_mb` (if available), `timestamp`.

**B. Performance**
- Camera overlay FPS (sampled), frame build time over budget (jank) counts, sketch processing duration (ms, by image size bucket), cold start time, memory sample, battery level/state (coarse), network failure rate for uploads, DB query time for slow queries.
- Use `WidgetsBinding.instance.addTimingsCallback` for frame timings.

**C. Usage events** (names are `snake_case`; props are small and typed)
`app_opened`, `screen_viewed{screen}`, `image_imported{source: gallery|camera}`, `sketch_created{style, duration_ms, size_bucket}`, `sketch_settings_changed{setting}`, `paper_size_selected{preset}`, `camera_overlay_opened`, `corners_adjusted{count}`, `overlay_locked`, `overlay_session_ended{duration_s}`, `project_saved`, `project_opened`, `export_pdf`, `permission_denied{permission}`, `feature_flag_seen{flag}`, `onboarding_completed`, `consent_changed{scope, value}`.
Funnel to measure: import, sketch, paper setup, camera overlay, lock, session over 5 min.

**D. In-app feedback**
- Modal: type (bug / idea / praise), message (max 1000 chars), optional "attach logs" toggle (last N non-PII log lines), optional screenshot **only if the user explicitly picks one** (never auto-capture the camera or sketch), optional 1-5 rating, occasional NPS prompt (0-10) after 3 successful sessions.

### 8.3 Local queue and delivery
- Store events in a drift table `telemetry_queue(id, kind, payload_json, created_at, attempts)`.
- Flush when: queue has 20+ items, every 15 minutes via `workmanager`, on app background, and for fatal errors attempt an immediate send then queue as fallback.
- Prefer Wi-Fi for large batches; allow small error batches on mobile data.
- Batch up to 100 items per request, gzip, `POST https://<server>/api/v1/telemetry`.
- Retry with exponential backoff and jitter; drop items after 7 days or 10 failed attempts; cap queue at 5000 items (drop oldest non-fatal).
- Each item has a client-generated `event_id` (UUID) so the server can dedupe.

### 8.4 Payload format
```json
{
  "install_id": "uuid",
  "session_id": "uuid",
  "app": {"version": "0.1.0", "build": 12, "platform": "android", "os_version": "14", "device_model": "Pixel 7", "locale": "en-US"},
  "sent_at": "2026-10-30T08:30:00Z",
  "items": [
    {"event_id": "uuid", "kind": "event", "name": "sketch_created", "ts": "2026-10-30T08:29:10Z", "props": {"style": "pencil", "duration_ms": 210}},
    {"event_id": "uuid", "kind": "error", "ts": "...", "fatal": true, "type": "RangeError", "message": "...", "stack": "...", "screen": "camera_overlay"},
    {"event_id": "uuid", "kind": "perf", "ts": "...", "metric": "overlay_fps", "value": 28.4, "unit": "fps"}
  ]
}
```
Feedback goes to `POST /api/v1/feedback` with `{install_id, type, message, rating, logs?, screenshot? (multipart)}`.

---

## 9. Server Spec (`server/`)

### 9.1 Endpoints
| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/register` | App registers `install_id`, receives a signed install token |
| POST | `/api/v1/telemetry` | Batched events, errors, perf (gzip accepted) |
| POST | `/api/v1/feedback` | User feedback (JSON or multipart with optional screenshot) |
| DELETE | `/api/v1/data` | Delete all data for the caller's `install_id` |
| GET | `/healthz` | Liveness/readiness |
| GET | `/admin/*` | Optional admin UI/API, protected by a separate admin token |

### 9.2 Security
- HTTPS only (Caddy). HSTS.
- Auth: per-install token (HMAC-signed, issued by `/register`) sent as `Authorization: Bearer ...`. Treat the embedded app key as **public**, so rely on rate limiting and validation too.
- Rate limit per IP and per install (e.g. 60 req/min), body size limit (e.g. 1 MB telemetry, 5 MB feedback).
- Pydantic strict validation, reject unknown kinds, truncate oversized strings, cap items per batch (100).
- Dedupe on `event_id`.
- Sanitize everything before putting it in Telegram messages.
- Secrets only in environment variables.

### 9.3 Database (PostgreSQL)
```
installs(install_id PK, first_seen, last_seen, platform, app_version, os_version, device_model, locale, consent_analytics bool)
events(event_id PK, install_id FK, session_id, name, ts, props jsonb, app_version)
errors(event_id PK, install_id FK, session_id, ts, fatal bool, type, message, stack, screen, fingerprint, app_version, os_version, device_model)
error_groups(fingerprint PK, first_seen, last_seen, count, affected_installs, title, last_notified_at, status)
perf_metrics(id PK, install_id, ts, metric, value, unit, app_version, device_model)
feedback(id PK, install_id, ts, type, message, rating, logs text, has_screenshot bool, screenshot_path, status)
```
Index on `(ts)`, `(fingerprint)`, `(install_id, ts)`. Retention job: delete events/perf older than 90 days, errors older than 180 days (configurable).

### 9.4 Error fingerprinting
`fingerprint = sha1(type + top 3 stack frames normalized (no line numbers of generated code, no memory addresses) + app_major_version)`. Group errors by fingerprint into `error_groups`.

---

## 10. Telegram Bot Integration (server-side only)

The bot token **never** goes in the app. The app talks only to your server; the server forwards to Telegram.

### 10.1 Setup
1. In Telegram, talk to `@BotFather`, use `/newbot` (or reuse your existing bot) and copy the token.
2. Send any message to your bot (or add it to a private group), then read your chat ID: `https://api.telegram.org/bot<TOKEN>/getUpdates`.
3. Put these in `deploy/.env` (never commit):
```
TELEGRAM_BOT_TOKEN=...
TELEGRAM_CHAT_ID=...
INSTALL_TOKEN_SECRET=<long random>
ADMIN_TOKEN=<long random>
DATABASE_URL=postgresql+psycopg://user:pass@db:5432/sketchlens
```
Create `deploy/.env.example` with the same keys and empty values.

### 10.2 What gets sent to Telegram
| Trigger | Message |
|---------|---------|
| New error group (first occurrence) | Title, count 1, app version, device, screen, short stack, fingerprint |
| Fatal crash | Immediate message (deduped, max 1 per fingerprint per 10 min) |
| Error spike | When a group exceeds N occurrences in 10 min |
| New feedback | Type, rating, message (truncated 500 chars), app version |
| Daily digest (e.g. 09:00) | New installs, DAU, sessions, crash-free rate, top 5 errors, top events, avg overlay FPS, funnel conversion |
| Server problems | Ingestion failures, DB errors, disk usage warning |

### 10.3 Implementation rules
- `services/telegram.py` with `send_message(text, *, parse_mode="HTML")` using `httpx.AsyncClient`, timeout 10 s.
- Use **HTML** parse mode and escape with `html.escape` (simpler than MarkdownV2 escaping). Truncate to 4096 chars.
- Respect Telegram limits (about 1 msg/s per chat, 20 msg/min in groups): put messages in an in-memory/DB queue with a rate limiter, merge bursts into one message, and handle HTTP 429 `retry_after`.
- Never block the ingest request on Telegram. Use background tasks/worker.
- Optional bot commands (`/stats`, `/errors`, `/feedback`) handled by a webhook or long-polling worker, restricted to your `chat_id` only.
- Optionally `sendDocument` for a screenshot attached to feedback.

---

## 11. Dashboards and Alerts
- Phase 1: Telegram digests and `/stats` command.
- Phase 2: Grafana connected to PostgreSQL with panels: DAU, sessions, funnel, crash-free sessions %, top errors, perf percentiles (p50/p95 FPS and processing time), feedback list, version adoption.
- Alert rules: crash-free rate under 98 percent, error spike, no telemetry received for 30 min (server or ingest down).

---

## 12. Testing Strategy
- **App unit tests:** geometry (corner ordering, homography on known points, fit contain/fill), sketch pipeline output properties (size, range, determinism), telemetry queue (enqueue, batch, retry, drop policy), PII scrubber.
- **App widget tests:** paper setup, corner handles, consent screen, feedback modal.
- **Integration tests:** import, sketch, camera overlay, save project (use mock camera where possible).
- **Server tests:** schema validation, auth, rate limit, dedupe, fingerprinting, Telegram notifier (mock `httpx`), retention job.
- **Manual device matrix:** low-end, mid, flagship Android; dim/bright light; phone on stand; paper partially covered by hand.
- **Accuracy test:** print sketch at A4, compare overlay to print, record error in mm.

---

## 13. Coding Conventions and Agent Rules

**General**
- Small, focused commits with clear messages (`feat:`, `fix:`, `chore:`, `test:`, `docs:`).
- No dead code, no TODOs without an issue entry in the Task Board.
- Do not add dependencies without a reason noted in the PR/commit message.
- Never hardcode secrets, tokens, URLs for production. Use config/env (`--dart-define` for the app's server URL).

**Dart/Flutter**
- Follow `flutter_lints`; run `flutter analyze` with zero warnings.
- Feature-first folders; UI has no business logic; heavy work in isolates.
- Immutable models; null-safety; no `dynamic` unless unavoidable.

**Python**
- Type hints everywhere, `ruff` clean, Pydantic models for all I/O.
- Async endpoints; DB access through repository/service layer.

**Agents specifically**
- Always read this file and existing code before editing.
- Plan first for tasks touching more than 3 files, then implement in small steps.
- After each task: run analyze, tests, and update the Task Board checkboxes and docs.
- If a requirement is ambiguous, ask or choose the simplest option and write the decision into `docs/decisions.md`.
- Do not delete or rewrite files unrelated to the task.
- Never log or transmit user images, sketches or file paths.
- Never place the Telegram token or install-token secret in the app or in git.

---

## 14. Task Board

Legend: [ ] todo, [x] done. Work top to bottom. Each task is done only when its acceptance check passes.

### Phase 0: Setup
- [ ] T0.1 Create repo structure from section 3, `.gitignore`, `README.md`, `CLAUDE.md` (`@AGENTS.md`).
- [ ] T0.2 `flutter create`, add dependencies from 4.2, `flutter analyze` clean.
- [ ] T0.3 Android permissions (camera, optional storage/media) and runtime permission flow.
- [ ] T0.4 Server skeleton: FastAPI app, `/healthz`, config via env, Dockerfile, `pytest` passing.
- [ ] T0.5 `deploy/docker-compose.yml` (api, postgres, caddy) and `.env.example`.

### Phase 1: Sketch converter
- [ ] T1.1 Python prototype in `prototypes/sketch.py` (pencil, Canny, XDoG) with 10 sample images.
- [ ] T1.2 Port pencil pipeline to `processing/` with `opencv_dart`, run in an isolate.
- [ ] T1.3 Import screen (gallery + camera) and crop.
- [ ] T1.4 Sketch editor UI: style chips, sliders, before/after.
- [ ] T1.5 Unit tests for pipeline, performance check (under 300 ms preview).

### Phase 2: Camera overlay
- [ ] T2.1 Camera preview screen with lifecycle and permission handling.
- [ ] T2.2 Overlay image with opacity, move, pinch-scale, rotate, flip.
- [ ] T2.3 Blend mode (multiply), lock button, flashlight, wakelock.

### Phase 3: Paper selection
- [ ] T3.1 `geometry/`: corner ordering, aspect fit (contain/fill), homography to `Matrix4`, unit tests.
- [ ] T3.2 Paper setup screen (presets, custom, units, orientation).
- [ ] T3.3 4-corner handles with loupe; apply homography to overlay.
- [ ] T3.4 Tilt indicator using accelerometer.
- [ ] T3.5 Accuracy test on a printed A4 (record result in `docs/accuracy.md`).

### Phase 4: Projects and polish
- [ ] T4.1 drift DB schema + repositories for projects.
- [ ] T4.2 Projects list, open, rename, delete, thumbnails.
- [ ] T4.3 Settings (units, theme, telemetry consent, reset analytics ID, delete my data).
- [ ] T4.4 Onboarding tutorial.

### Phase 5: Telemetry (app + server + Telegram)
- [ ] T5.1 App: consent screen + settings toggles; gating in the telemetry SDK.
- [ ] T5.2 App: error hooks (Flutter, platform dispatcher, zone, isolates) + PII scrubber + tests.
- [ ] T5.3 App: event tracker with typed event names; add tracking calls across features (section 8.2C).
- [ ] T5.4 App: perf collectors (FPS, jank, processing time, startup, memory, battery).
- [ ] T5.5 App: drift queue + batching + gzip + backoff + workmanager flush.
- [ ] T5.6 App: feedback modal + NPS prompt.
- [ ] T5.7 Server: models, migrations, `/register`, `/telemetry`, `/feedback`, `/data` delete, validation, auth, rate limit, dedupe.
- [ ] T5.8 Server: error fingerprinting + `error_groups`.
- [ ] T5.9 Server: Telegram notifier with queue, rate limiting, HTML escaping; new-error, fatal, spike, feedback alerts.
- [ ] T5.10 Server: daily digest job and `/stats`, `/errors`, `/feedback` bot commands (restricted to your chat ID).
- [ ] T5.11 Server: retention job; docs for privacy policy text.
- [ ] T5.12 End-to-end test: force a crash in a debug build and confirm it reaches the DB and Telegram.

### Phase 6: Release hardening
- [ ] T6.1 Device matrix testing, fix top issues.
- [ ] T6.2 App signing, release build, Play Store listing assets, privacy policy URL.
- [ ] T6.3 Closed beta with at least 5 users, review Telegram digests for a week.

### Phase 7: v2 (after MVP)
- [ ] T7.1 Auto paper detection + smoothing.
- [ ] T7.2 Grid overlay.
- [ ] T7.3 Export at real size (PDF).
- [ ] T7.4 Tracking (feature-based or ARCore).
- [ ] T7.5 iOS build.
- [ ] T7.6 Grafana dashboards and alert rules.

---

## 15. Definition of Done (every task)
1. Code compiles, `flutter analyze` and `ruff check` are clean.
2. Relevant tests added and passing.
3. No secrets, no PII or images in logs or telemetry.
4. Task Board updated and any decisions recorded in `docs/decisions.md`.
5. Manual smoke test of the touched flow on a real device or emulator.

---

## 16. Useful Starter Prompts for Agents
- "Read AGENTS.md. Complete tasks T0.1 to T0.5, then stop and summarize."
- "Implement T1.2: port the pencil sketch pipeline to Dart with opencv_dart in an isolate, add unit tests, run analyze and tests."
- "Implement T3.1 geometry utilities with tests before touching any UI."
- "Implement T5.7 to T5.9 on the server, with tests that mock Telegram."
- "Review the whole telemetry flow against sections 8 to 10 and list privacy risks."
