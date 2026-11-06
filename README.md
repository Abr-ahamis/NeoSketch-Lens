# SketchLens

SketchLens is an Android drawing aid. Import a photo, convert it to line art on-device, choose a paper size, and align the sketch over the live camera preview while you draw. Images and sketches stay on the device.

## Requirements

- Flutter stable
- Android SDK and a connected device or emulator

## Setup and run

```sh
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

Build an Android APK with `flutter build apk --release`. The output is written under `app/build/app/outputs/flutter-apk/`.

## Project layout

- `app/lib/` — Flutter application source
- `app/test/` — Dart unit tests
- `docs/` — architecture, privacy, API, and planning documents
- `AGENTS.md` — project requirements and task board
