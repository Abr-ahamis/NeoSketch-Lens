# Architecture

## System overview
```
[Flutter app] --(HTTPS, batched, gzip)--> [FastAPI server] --> [PostgreSQL]
      |                                         |
 on-device only:                                +--> [Telegram Bot API] --> owner's chat
 images, sketches, projects                     +--> [Grafana] (optional)
```

## App layers
- **ui**: screens and widgets only, no business logic.
- **state**: Riverpod providers/notifiers.
- **domain**: entities (`Project`, `PaperSize`, `SketchSettings`, `OverlayTransform`).
- **data**: drift DB, file storage, repositories.
- **processing**: OpenCV wrappers; heavy work in isolates.
- **geometry**: corner ordering, aspect fit, homography to `Matrix4`, paper detection.
- **telemetry**: SDK (consent, scrubber, queue, uploader, hooks).

## Key data models
- `PaperSize { name, widthMm, heightMm }`
- `SketchSettings { style, blur, contrast, lineThickness, detail, invert }`
- `Project { id, title, originalPath, sketchPath, settings, paperSize, corners[4], overlayTransform, createdAt, updatedAt, thumbnailPath }`
- `TelemetryItem { eventId, kind, payloadJson, createdAt, attempts }`

## Sketch pipeline
gray, invert, Gaussian blur, color dodge (`gray*256/(255-blur)`), contrast, optional invert. Alternatives: Canny, XDoG, adaptive threshold. Preview at max 1024 px; full resolution on save/export. Cached by (image hash, settings).

## Paper fit geometry
1. Paper rect in mm: `W x H`. Target `dst = [(0,0),(W,0),(W,H),(0,H)]`.
2. Sketch fitted into `dst` (contain or fill) plus user pan/zoom.
3. Corners in preview space `src = [TL,TR,BR,BL]`.
4. `M = getPerspectiveTransform(dst, src)`, converted to a Flutter `Matrix4` (3x3 to 4x4 with perspective in the last row).
5. Overlay drawn with `Transform(transform: M)` and multiply blend.

## Tracking levels
0 fixed on stand (MVP), 1 per-frame corner re-detection with smoothing, 2 feature tracking (ORB/optical flow), 3 ARCore/ARKit anchor.

## Server layers
`api` (routers) calls `services` (fingerprint, telegram, digest) calls `models`/DB. `workers` run notifier queue, digest, retention. Config only via environment.

## Error flow
App error, scrub PII, queue (drift), batch upload, server validates + dedupes, fingerprint, `error_groups` update, Telegram notifier queue (rate limited, merged), message to owner.
