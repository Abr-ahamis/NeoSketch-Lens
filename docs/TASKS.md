# Android MVP task status

The parent `AGENTS.md` defines the full SketchLens roadmap. This project is currently scoped to a local-only Android APK as the user requested. This means the server, Telegram, telemetry, and all non-Android deliverables are intentionally excluded from this MVP.

## Android MVP

- [x] Replace the old web app with an Android-only Flutter project.
- [x] Keep reference screenshots and conversation exports outside the APK.
- [x] Import an image from Android gallery or camera.
- [x] Generate local pencil, outline, charcoal, soft, and crosshatch previews using pixel algorithms.
- [x] Provide editable blur, contrast, brightness, edge strength, and invert controls.
- [x] Pick A5, A4, A3, Letter, Legal, Square, or custom paper dimensions.
- [x] Preview local camera with draggable paper corners, tilt hint, grid, opacity, flashlight, lock, and keep-awake control.
- [x] Save and reopen projects in a local Drift database.
- [x] Confirm analyzer and unit tests pass.
- [x] Build an arm64 release APK and inspect permissions; APK requests camera only and has no Internet permission.
- [x] Install and run a real-device smoke test on a TECNO KI5k (Android 12): app startup, gallery import, sketch processing, editor controls, paper setup, camera preview, four corner handles, and local alignment save. Filtered AndroidRuntime/Flutter error logs were empty.
- [x] Reduce image/project loading work: project cards use a thumbnail column and list-only fields; editor slider previews reuse a bounded downscaled input and coalesce stale work.
- [x] Make the editor image-first with a horizontal bottom tool strip, per-tool adjustment control, and lower-cost sketch output/edge loops.
- [ ] Rebuild/install the updated APK and measure responsiveness on the TECNO KI5k after user confirmation.

## Explicitly deferred by local-only scope

- Telemetry consent, uploads, feedback endpoint, FastAPI, PostgreSQL, Telegram, Docker/Caddy, and dashboards.
- Telegram diagnostics remain deferred; do not embed chat-provided credentials in the app. Revoke the exposed token before considering an opt-in, server-side integration. Installed-app inventory is out of scope.
- iOS, web, desktop, automated paper detection, and AR tracking.
