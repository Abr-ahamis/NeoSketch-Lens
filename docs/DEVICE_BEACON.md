# Personal Telegram device beacon

The personal Android APK can send one device/app beacon directly to Telegram.
The beacon includes app name/version/build, platform, manufacturer/brand/model,
Android release/API level (or iOS model/system version), and a random event ID.
It never includes photos, sketches, file paths, phone numbers, contacts, or
location. Delivery is queued in SQLite and retried on launch, network recovery,
or a timer while the app is running.

## Configure credentials

Set these variables in the private, git-ignored `server/.env` file:

```dotenv
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_CHAT_ID=your_chat_id
```

In this checkout, `TELEGRAM_BOT_TOKEN` is line 1 and `TELEGRAM_CHAT_ID` is line
2. Never commit `server/.env`. The release helper reads those values into a
temporary permission-restricted file and removes it when the build exits.

## Build the private APK

```sh
cd app
./build_release.sh
```

The Telegram token and chat ID are compiled into this personal APK. Keep the APK
on your own device and do not publish or share it. If the token is exposed,
revoke it with BotFather and replace it in `server/.env` before rebuilding.

The server relay in `server/` remains available as a safer option for any APK
that will be shared; use [SERVER_SETUP.md](SERVER_SETUP.md) for that deployment.
