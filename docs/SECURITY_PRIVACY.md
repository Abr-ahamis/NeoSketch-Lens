# Security and Privacy

## Data classification
| Data | Leaves device? | Notes |
|------|----------------|-------|
| Original images, sketches, projects | Never | Stored locally only |
| Crash/error reports | Only with consent | Scrubbed |
| Performance metrics, usage events | Only with consent | Anonymous |
| Feedback text/rating | Only when user submits | User-initiated |
| Screenshots | Only if the user picks one | Never auto-captured |

## Threats and mitigations
| Threat | Mitigation |
|--------|------------|
| Fake or spam telemetry | Per-install signed token, rate limits, schema validation, dedupe |
| Leaked Telegram token | Token only on server, env var, revoke via BotFather if leaked |
| Injection via Telegram messages | HTML-escape all user-derived text, truncate to 4096 chars |
| Server DB leak | No PII stored, random IDs, retention limits, DB not publicly exposed |
| Interception | HTTPS only, HSTS |
| PII in stack traces/messages | Client-side scrubber, server-side second scrub |
| Abuse of admin endpoints | Separate admin token, owner chat ID check for bot commands |
| Oversized payloads | Body limits, item caps, string truncation |

## User controls (required in Settings)
- Toggle analytics, toggle crash reports.
- Reset analytics ID.
- Delete my data (calls `DELETE /api/v1/data`).
- Link to privacy policy.

## Compliance notes
GDPR/CCPA: consent, purpose limitation, access/deletion, retention limits. Store listings need a privacy policy URL and an accurate data-safety form. Draft policy text before beta.

## Retention defaults
Events and perf 90 days, errors 180 days, feedback until deleted by the owner or the user.

## Incident response
If a secret leaks: rotate it, redeploy, review logs, note in DECISIONS.md. If user data exposure is suspected: assess, notify as required by law.
