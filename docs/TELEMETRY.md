# Telemetry Spec

## Principles
- Consent first. Nothing is queued or sent without it (crash reports may be a separate opt-in).
- Data minimization: no images, sketches, file paths, names, emails, phone numbers, precise location, ad IDs.
- Random `install_id`, resettable. Delete-my-data supported.

## Error capture
Hooks: `FlutterError.onError`, `PlatformDispatcher.instance.onError`, `runZonedGuarded`, isolate error listener; native crashes via Crashlytics/Sentry if added later.
Fields: type, message, stack, fatal, screen, session_id, app version/build, OS, OS version, device model, locale, timestamp.
Scrubber removes: emails, bearer tokens, long hex/base64 strings, home directory paths, URLs with query strings.

## Performance metrics
| Metric | Unit | How |
|--------|------|-----|
| overlay_fps | fps | sampled every 10 s in overlay mode |
| jank_frames | count | `addTimingsCallback`, frames over 16 ms (60Hz) |
| sketch_duration_ms | ms | per conversion, with size bucket |
| cold_start_ms | ms | process start to first frame |
| memory_mb | MB | sample on overlay start/end |
| battery_level, battery_state | coarse | at session start/end |
| upload_failure_rate | ratio | per flush |

## Event catalog
`app_opened`, `screen_viewed{screen}`, `image_imported{source}`, `sketch_created{style,duration_ms,size_bucket}`, `sketch_settings_changed{setting}`, `paper_size_selected{preset}`, `camera_overlay_opened`, `corners_adjusted{count}`, `overlay_locked`, `overlay_session_ended{duration_s}`, `project_saved`, `project_opened`, `export_pdf`, `permission_denied{permission}`, `onboarding_completed`, `consent_changed{scope,value}`, `feedback_submitted{type}`.
Rules: snake_case names, props small and typed, no free text.

## Feedback
Type (bug/idea/praise), message up to 1000 chars, optional rating 1-5, optional logs (scrubbed), optional screenshot only if the user explicitly picks it. NPS (0-10) after 3 successful sessions, asked at most once per 90 days.

## Queue and delivery
- drift table `telemetry_queue`.
- Flush: 20+ items, every 15 min (workmanager), on background; fatal errors attempt immediate send.
- Batch up to 100 items, gzip, retry with exponential backoff + jitter.
- Drop after 7 days or 10 attempts; cap 5000 items (drop oldest non-fatal first).
- `event_id` UUID per item for server dedupe.

## Server alert rules (Telegram)
- New error group: immediate.
- Fatal crash: immediate, max 1 per fingerprint per 10 min.
- Spike: group count over N in 10 min.
- New feedback: immediate.
- Daily digest 09:00 owner time.
- Ingest/server failure: immediate.
