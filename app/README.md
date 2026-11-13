# SketchLens Android app

The Flutter application for SketchLens. It imports photos, creates line art locally, and provides a camera overlay for paper drawing. No user images or sketches are uploaded.

From this directory, run `flutter pub get`, then `flutter run`. For the private
personal APK with Telegram diagnostics enabled, set `TELEGRAM_BOT_TOKEN` and
`TELEGRAM_CHAT_ID` in `../server/.env` and run `./build_release.sh`. The token is
embedded in that APK, so keep it private. See the repository [README](../README.md)
for more details.
