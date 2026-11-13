# SketchLens

SketchLens is an Android drawing aid. Import a photo, convert it to line art on-device, choose a paper size, and align the sketch over the live camera preview while you draw. Images and sketches stay on the device.

## Requirements

- Flutter stable
- Android SDK and a connected device or emulator

## Setup and run

See [BUILDING.md](BUILDING.md) for Android SDK prerequisites, the private
release build, installation, and logcat commands.

```sh
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

For the private personal APK, set `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`
in `server/.env`, then build from `app/` with:

```sh
./build_release.sh
```

The helper reads credentials from `server/.env` through a temporary,
permission-restricted build file. The token is embedded in the APK; keep the APK
private and never commit it. User images and sketches are never sent.

## Project layout

- `app/lib/` — Flutter application source
- `app/test/` — Dart unit tests
- `docs/` — architecture, privacy, API, and planning documents
- `AGENTS.md` — project requirements and task board
