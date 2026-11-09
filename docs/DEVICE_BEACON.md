# Automatic one-time device beacon

Sketch conversion remains local and offline. The one-time beacon is queued
automatically on first app launch. It queues only
the app name/version/build, platform, device manufacturer/brand/model, Android
release/API level (or iOS model/system version), and a random event ID. It never
includes photos, sketches, device identifiers, phone numbers, contacts, or
location. A beacon already delivered to Telegram cannot be recalled from
Telegram.

The beacon is stored in the existing SQLite database until the relay responds
successfully. While the app is running, delivery is attempted on launch, network
restoration, and timed retry. If the process is stopped when connectivity
returns, the pending beacon is sent the next time the app opens; this MVP does not
run a background worker while the app is force-stopped.

## Run the relay

Use Python 3.12+ and install `server/requirements.txt`. Add the rotated Telegram
token and destination chat ID to the private, git-ignored `server/.env` file:

```dotenv
TELEGRAM_BOT_TOKEN=put-the-rotated-token-here
TELEGRAM_CHAT_ID=your-chat-id
```

In this checkout, add them on **line 1** and **line 2** of
`server/.env`. The file is excluded from git. Never put the bot token in Flutter,
`--dart-define`, the APK, or source control. Then run:

```sh
cd server
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Put the relay behind HTTPS before using it outside a trusted local network. The
relay accepts only the documented fields, escapes Telegram HTML, rate-limits by
source IP, and deduplicates successfully delivered event IDs in SQLite. Keep the
SQLite file on persistent storage. Do not paste the bot token into this chat or
pass it as a Flutter build define.

Build the Android app with the HTTPS endpoint:

```sh
cd app
flutter build apk --release \
  --dart-define=SKETCHLENS_BEACON_URL=https://your-domain.example/api/v1/beacon
```

Check `https://your-domain.example/healthz`; it reports whether the Telegram
environment is configured without exposing the credentials. If the app has no
endpoint configured, its one-time beacon remains queued locally until the app is
rebuilt with the relay URL.
