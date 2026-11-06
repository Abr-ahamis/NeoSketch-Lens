# Goals

## Vision
Remove the screen-to-paper back-and-forth when learning to draw: the reference appears right on the paper, in the camera view.

## Product goals
| ID | Goal | Measure of success |
|----|------|--------------------|
| G1 | High-quality photo to sketch, offline | 8 of 10 test photos rated "good" by 5 testers |
| G2 | Accurate paper alignment | Overlay vs printed A4 within 3 mm |
| G3 | Smooth live overlay | 30 fps median on a mid-range Android phone |
| G4 | Full observability | Crash, perf, events and feedback reach server; critical ones reach Telegram within 1 min |
| G5 | Privacy-first | No images or PII ever leave the device; consent toggle works; data deletion works |
| G6 | Real usage | 5+ beta users complete a drawing session of 5+ minutes |

## Engineering goals
- Zero analyzer warnings; core logic (geometry, pipeline, telemetry queue, server) covered by tests.
- Cold start under 2 s; sketch preview under 300 ms at 1024 px.
- Crash-free sessions at least 99 percent in beta.
- Telemetry battery/data impact negligible (batched uploads, gzip).

## Success metrics to watch (from telemetry)
- Funnel: import, sketch, paper setup, overlay, lock, session over 5 min.
- Crash-free session rate, top error groups.
- Overlay FPS p50/p95, sketch processing time p95.
- Feedback sentiment and NPS.

## Non-goals (for now)
User accounts, cloud storage of drawings, social sharing, server-side image processing, ads.

## Open questions
- Stand-only or hand-held tracking first? (default: stand-only MVP)
- Free, paid, or ads? (decide after beta)
- Analytics default on or off? (default: off, crash reports opt-in)
