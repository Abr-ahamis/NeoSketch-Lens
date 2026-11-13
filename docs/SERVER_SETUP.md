# Optional server relay setup

For a private personal APK, the app can send the beacon directly to Telegram
using build-time credentials from `server/.env`; see `DEVICE_BEACON.md`. For any
APK that will be shared, use this HTTPS relay instead so the bot token stays on
the server.

## 1. Configure Telegram credentials

Create a bot with `@BotFather`, send it a message, and obtain the destination
chat ID. On the relay host, edit `server/.env` and set these entries:

```dotenv
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_CHAT_ID=your_chat_id
BEACON_DB_PATH=/data/beacons.sqlite3
```

The checked-in template is `server/.env.example`. Copy it to `server/.env`,
replace the first two values, and restrict the file to its owner (`chmod 600
server/.env`). Do not commit `server/.env` or paste the bot token into chat.

## 2. Deploy the HTTPS relay

Requirements: a Linux host with Docker Compose, a public DNS name pointed to that
host, and inbound TCP ports 80 and 443 available.

```sh
cp server/.env.example server/.env
chmod 600 server/.env
# Edit server/.env and set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID.
cp deploy/.env.example deploy/.env
# Edit deploy/.env and set BEACON_DOMAIN to the DNS name pointed at this host.
cd deploy
docker compose up -d --build
```

Caddy obtains and renews the HTTPS certificate. Check
`https://YOUR_DOMAIN/healthz`; the response should report `"telegram":"configured"`.
The relay stores delivered event IDs in a persistent Docker volume to prevent
duplicate Telegram messages.

## 3. Build an app that uses the relay

Build with the public relay URL:

```sh
cd app
flutter build apk --release \
  --dart-define=SKETCHLENS_BEACON_URL=https://YOUR_DOMAIN/api/v1/beacon
```

The app queues one beacon per installation and sends it on launch or when
connectivity returns. It sends only the allow-listed device/app fields
documented in `DEVICE_BEACON.md`; user images and sketches stay on the device.

## Local development

```sh
cd server
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Use a public HTTPS deployment for a release APK. A phone cannot reach the build
computer's loopback address, and the app intentionally rejects non-HTTPS relay
URLs.
