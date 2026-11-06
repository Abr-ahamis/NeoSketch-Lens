# Decision Log

Format: `ID | Date | Decision | Reason | Alternatives`. Agents append new rows when they make a non-obvious choice.

| ID | Date | Decision | Reason | Alternatives |
|----|------|----------|--------|--------------|
| D1 | 2026-10-30 | Flutter, Android first | One codebase, iOS later | Native Kotlin, React Native |
| D2 | 2026-10-30 | Pure Dart pixel processing for the first Android build | Runs locally without native OpenCV packaging or any model | OpenCV FFI, ML model |
| D3 | 2026-10-30 | MVP uses fixed overlay (phone on stand) | Tracking is the hardest part; ship value first | Per-frame detection, ARCore |
| D4 | 2026-10-30 | Do not include telemetry, server, or Telegram integration in the Android MVP | User explicitly requires a local-only app with no network use | Opt-in remote diagnostics |
| D5 | 2026-10-30 | Android APK is the only deliverable platform for this project | User requested an Android-only application | Browser, iOS, desktop |
| D6 | 2026-10-30 | Camera-based alignment MVP uses user-adjustable four-corner perspective mapping | Gives users direct control over paper alignment without cloud or ML | Auto paper detection, AR tracking |
| D7 | 2026-10-30 | Keep source reference materials under `references/`, outside the app bundle | Conversation exports and screenshots are design/reference inputs | Bundle reference material in production |
| D8 | 2026-10-30 | Replace the old React/Vite app with a Flutter Android app | User explicitly asked to remove the old app code and recreate it from AGENTS.md | Preserve a browser version |
| D9 | 2026-10-30 | Release APK includes only the camera permission needed for capture/alignment | Photo Picker needs no broad storage permission on current Android, audio and network-state access are not required | Keep permissions contributed by plugins |
| D10 | 2026-10-30 | Store 360-pixel project thumbnails and read only card fields in the project list | Avoid loading full-resolution originals/sketches for every home-screen card | Load all BLOB columns for each row |
| D11 | 2026-10-30 | Cache at most two downscaled preview inputs in memory and serialize live slider preview jobs | Avoid repeated full-size image decode/resize and CPU/memory spikes while preserving local-only processing | Reprocess/queue each slider update independently |
| D12 | 2026-11-06 | Keep the repository focused on the Flutter Android app and its project documentation; remove the superseded web prototype, exported webpage, and generated build caches | The mobile app is the documented product and the web implementation had already been marked as replaced | Maintain separate web and mobile products |
