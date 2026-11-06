# Skills, Tools and Agent Setup

## Knowledge areas needed
Flutter/Dart (Riverpod, FFI, CustomPainter, Matrix4), OpenCV (blur, dodge blend, Canny, XDoG, contours, homography), Android camera lifecycle, drift/SQLite, FastAPI + Pydantic + SQLAlchemy + Alembic, Telegram Bot API, Docker + Caddy, privacy/security basics.

## Tools to install
Flutter SDK, Android Studio or command-line SDK, Python 3.12, PostgreSQL or Docker, `ruff`, `pytest`, Git, optional `mitmproxy` for traffic audits, optional Grafana.

## Claude Code
- Reads `CLAUDE.md` which imports `AGENTS.md`.
- Suggested subagents in `.claude/agents/`:
  - `flutter-dev`: UI, state, camera, drift.
  - `cv-engineer`: OpenCV pipeline and geometry.
  - `backend-dev`: FastAPI, DB, Telegram notifier.
  - `reviewer`: reviews diffs against AGENTS.md rules and the privacy checklist.
- Suggested slash command `/verify`: run `flutter analyze`, `flutter test`, `ruff check`, `pytest` and report.
- Use plan mode for tasks touching more than 3 files.

## Codex
- Reads `AGENTS.md` from the repo root automatically. Optional nested `AGENTS.md` in `app/` and `server/` for stack-specific rules.
- Give tasks by ID: "Complete T3.1 from docs/TASKS.md."

## Working agreement for any agent
1. Read AGENTS.md and the relevant docs first.
2. Plan, then implement in small commits.
3. Run analyze + tests, update TASKS.md, log decisions in DECISIONS.md.
4. Never commit secrets; never log or send images or PII.
