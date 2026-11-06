# Ready-to-paste Agent Prompts

## Kickoff
```
Read AGENTS.md, docs/TASKS.md and docs/ARCHITECTURE.md. Complete Phase 0 (T0.1 to T0.5). Run analyze and tests. Update TASKS.md and stop with a short summary.
```

## Sketch pipeline
```
Implement T1.1 then T1.2. First a Python OpenCV prototype in prototypes/ for pencil, Canny and XDoG on 10 sample images. Then port the pencil style to Dart with opencv_dart in an isolate. Add tests. Do not touch UI yet.
```

## Geometry first
```
Implement T3.1 in app/lib/geometry with unit tests only: corner ordering, aspect fit (contain/fill), homography to Matrix4. No UI changes.
```

## Camera overlay
```
Implement T2.1 to T2.3. Camera preview with lifecycle handling, overlay image with opacity/move/scale/rotate/flip, multiply blend, lock, flashlight, wakelock. Keep logic out of widgets.
```

## Telemetry client
```
Implement T5.1 to T5.6 following docs/TELEMETRY.md and docs/SECURITY_PRIVACY.md. Consent gating first. Add tests for the scrubber and queue. Never include images or file paths in payloads.
```

## Server
```
Implement T5.7 to T5.9 following docs/API.md. FastAPI, Pydantic strict models, SQLAlchemy + Alembic, HMAC install tokens, rate limiting, dedupe, fingerprinting, Telegram notifier with queue and HTML escaping. Mock Telegram in tests.
```

## Review
```
Review the whole repo against AGENTS.md section 13 and docs/SECURITY_PRIVACY.md. List privacy risks, missing tests and unfinished tasks. Do not change code.
```

## Debug
```
Reproduce the bug first with a failing test, then fix it, then run analyze and the full test suite. Log any design decision in docs/DECISIONS.md.
```
