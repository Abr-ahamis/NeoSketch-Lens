# Test Plan

## Automated
| Area | Tests |
|------|-------|
| Geometry | corner ordering, aspect fit contain/fill, homography on known points, degenerate quads |
| Sketch pipeline | determinism, output size/range, no div-by-zero, style outputs differ |
| Telemetry client | consent gating, scrubber, queue enqueue/batch/retry/drop, size cap |
| Widgets | paper setup, corner handles, consent screen, feedback modal |
| Server | schema validation, auth, rate limit, dedupe, fingerprint stability, retention, Telegram mock |
| Integration | import to sketch to overlay to save; forced crash to server to Telegram |

Commands: `flutter analyze && flutter test`, `ruff check . && pytest`.

## Manual device matrix
Low-end (2-3 GB RAM), mid-range, flagship; different camera aspect ratios; portrait and landscape; dim and bright light; with and without flashlight.

## Alignment accuracy protocol
1. Fix phone on a stand above a desk, paper flat (A4).
2. Mark 4 corners in the app, lock overlay.
3. Print the same sketch at 100 percent on A4, place it on the paper position.
4. Measure the offset at 5 landmark points (corners + center) with a ruler.
5. Record the max error (mm) per device in `docs/accuracy.md`. Target: 3 mm or less.

## Performance protocol
Profile on a mid-range device in release mode (`flutter run --profile`), 2 minutes in overlay mode: median fps, jank count, memory growth (should be flat), battery drop per 10 min.

## Telemetry privacy audit
Capture traffic of a debug build (mitmproxy) and verify: no images, no paths, no PII, nothing sent when consent is off.

## Release gate
All automated tests pass, accuracy within target, crash-free beta sessions at least 99 percent, privacy audit passed.
