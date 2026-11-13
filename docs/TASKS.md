# Android MVP task status

The parent `AGENTS.md` defines the full SketchLens roadmap. The project ships an Android APK with local image processing. A private personal build can send one minimal device beacon directly to Telegram; shared builds should use the server relay.

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
- [x] Build an arm64 release APK and inspect permissions; APK requests camera and Internet permissions for the owner-authorized Telegram beacon.
- [x] Install and run a real-device smoke test on a TECNO KI5k (Android 12): app startup, gallery import, sketch processing, editor controls, paper setup, camera preview, four corner handles, and local alignment save. Filtered AndroidRuntime/Flutter error logs were empty.
- [x] Reduce image/project loading work: project cards use a thumbnail column and list-only fields; editor slider previews reuse a bounded downscaled input and coalesce stale work.
- [x] Make the editor image-first with a horizontal bottom tool strip, per-tool adjustment control, and lower-cost sketch output/edge loops.
- [ ] Rebuild/install the updated APK and measure responsiveness on the TECNO KI5k after user confirmation.

## Explicitly deferred by local-only scope

- Full analytics telemetry, crash uploads, feedback endpoint, PostgreSQL, and dashboards remain deferred.
- A private personal APK sends one minimal device beacon directly to Telegram using build-time credentials from ignored `server/.env`; the APK must not be published or shared. The server-side relay remains preferred for any distributed build. Installed-app inventory is out of scope.
- iOS, web, desktop, automated paper detection, and AR tracking.
