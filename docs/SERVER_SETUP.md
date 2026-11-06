# Server and Telegram Setup

## 1. Create or reuse your Telegram bot
1. Open Telegram, message `@BotFather`, send `/newbot` (skip if you already have a bot), copy the token.
2. Send any message to your bot (or add it to a private group).
3. Get your chat ID: open `https://api.telegram.org/bot<TOKEN>/getUpdates` in a browser and read `message.chat.id`.
4. Keep the token secret. If it leaks, revoke it with `/revoke` in BotFather.

## 2. Environment
Copy `deploy/.env.example` to `deploy/.env` and fill it. Generate secrets:
```bash
openssl rand -hex 32   # for INSTALL_TOKEN_SECRET and ADMIN_TOKEN
```

## 3. Local development
```bash
cd server
python3 -m venv .venv && source .venv/bin/activate
pip install -e .
alembic upgrade head
uvicorn app.main:app --reload
```
Test the Telegram link:
```bash
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
  -d chat_id="$TELEGRAM_CHAT_ID" -d text="SketchLens server test"
```

## 4. Production (VPS with Docker)
1. Point a domain/subdomain DNS A record to the VPS.
2. Put the domain in `deploy/Caddyfile` (Caddy gets HTTPS certificates automatically).
3. `cd deploy && docker compose up -d --build`
4. Run migrations: `docker compose exec api alembic upgrade head`
5. Check `https://<domain>/healthz`.
6. Back up PostgreSQL daily (`pg_dump` cron) and test a restore.

## 5. Hardening checklist
- [ ] Firewall: only 80/443 (and SSH with keys) open.
- [ ] `.env` not in git, file permissions 600.
- [ ] Rate limits and body size limits enabled.
- [ ] Telegram bot commands restricted to your chat ID.
- [ ] Log rotation, disk usage alert.
- [ ] Unattended security updates.

## 6. App configuration
Pass the server URL at build time: `flutter run --dart-define=API_BASE_URL=https://<domain>/api/v1`. Never put the Telegram token in the app.
