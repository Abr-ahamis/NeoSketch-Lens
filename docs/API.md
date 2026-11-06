# Server API (v1)

Base URL: `https://<your-domain>/api/v1`. JSON, UTF-8. Gzip request bodies accepted.

## POST /register
Request: `{"install_id":"uuid","platform":"android","app_version":"0.1.0"}`
Response 200: `{"install_token":"<signed token>","expires_in":2592000}`
Notes: token is HMAC-signed with `INSTALL_TOKEN_SECRET`; rate limited per IP.

## POST /telemetry
Header: `Authorization: Bearer <install_token>`, optional `Content-Encoding: gzip`.
Body:
```json
{
  "install_id": "uuid",
  "session_id": "uuid",
  "app": {"version":"0.1.0","build":12,"platform":"android","os_version":"14","device_model":"Pixel 7","locale":"en-US"},
  "sent_at": "2026-10-30T08:30:00Z",
  "items": [
    {"event_id":"uuid","kind":"event","name":"sketch_created","ts":"...","props":{"style":"pencil","duration_ms":210}},
    {"event_id":"uuid","kind":"error","ts":"...","fatal":true,"type":"RangeError","message":"...","stack":"...","screen":"camera_overlay"},
    {"event_id":"uuid","kind":"perf","ts":"...","metric":"overlay_fps","value":28.4,"unit":"fps"}
  ]
}
```
Response 202: `{"accepted":N,"duplicates":M,"rejected":K}`
Limits: max 100 items, 1 MB body, unknown `kind` rejected, strings truncated (message 2000, stack 8000).

## POST /feedback
JSON or multipart. Fields: `install_id`, `type` (bug|idea|praise), `message` (max 1000), `rating` (1-5, optional), `logs` (optional), `screenshot` (optional file, 5 MB max, png/jpg).
Response 201: `{"id":123}`

## DELETE /data
Auth as above. Deletes all rows for the caller's `install_id`. Response 204.

## GET /healthz
Response 200: `{"status":"ok"}` (no auth).

## Errors
400 invalid schema, 401 bad/expired token, 413 too large, 429 rate limited (`Retry-After` header), 5xx server error. Clients retry 429/5xx with backoff, never 4xx.

## Admin (optional)
Separate `X-Admin-Token`; read-only endpoints for stats, errors, feedback.
