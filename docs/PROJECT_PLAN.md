# Sketch Overlay App: Full Project Plan

**Working name:** SketchLens (rename freely)
**One-line pitch:** Pick a photo, turn it into a clean sketch, then see that sketch projected over your real paper through the phone camera so you can trace and draw it by hand.

---

## 1. Vision

Learning to draw from a reference is hard because you have to look back and forth between the screen and the paper. This app removes that problem:

1. Convert any image (gallery or camera) into a sketch / line drawing.
2. Open the camera and place the sketch as an overlay on the live view.
3. Mark your real paper in the camera view, so the app knows its exact size and position.
4. The sketch is scaled and aligned to the paper, so you draw directly over the guide.

### Target users
- Beginners learning to draw
- Hobby artists and portrait or hyperrealism artists who use grids and tracing
- Students (art classes), tattoo and mural sketchers

---

## 2. Core Features (MVP)

| # | Feature | Description |
|---|---------|-------------|
| 1 | Image import | Pick from gallery or take a photo |
| 2 | Image to sketch | Convert to a pencil-style or line sketch, with adjustable strength |
| 3 | Camera view | Live camera with sketch overlay |
| 4 | Overlay controls | Opacity slider, move, pinch to scale, rotate, flip |
| 5 | Paper selection | Draw or adjust a rectangle on the camera view marking the paper |
| 6 | Paper size setting | Choose A4 / A3 / A5 / Letter / custom (cm or inches) |
| 7 | Auto fit | Sketch is resized to fit the paper size and aspect ratio |
| 8 | Save session | Save the project (original, sketch, paper settings) to continue later |

### Nice-to-have (v2)
- Automatic paper detection (find the sheet edges without manual selection)
- Overlay stays locked to the paper while the phone moves (tracking)
- Grid overlay (for grid-method drawing)
- Lock screen / keep screen awake / flashlight toggle
- Export sketch as PNG/PDF at real print size (for printing and tracing on a light box)
- Multiple sketch styles (pencil, ink outline, charcoal, cartoon)
- Detail slider and "simplify" mode for beginners
- Progress timelapse (record drawing progress)
- Dark mode, multi-language

---

## 3. User Flow

```
Home
 ├─ New project
 │    ├─ Choose image (Gallery / Camera)
 │    ├─ Sketch editor (style, strength, detail, crop)
 │    ├─ Paper setup (choose size preset or custom)
 │    ├─ Camera: select paper (4 corners) → app adjusts
 │    ├─ Overlay mode (opacity, move, scale, lock)
 │    └─ Save / Export
 └─ My projects (list, reopen, delete)
```

### Paper selection flow (the key part of your idea)
1. Camera opens and the user points it at the blank paper.
2. The app shows a rectangle with 4 draggable corner handles.
3. User drags the corners to match the paper (or taps "Auto detect" in v2).
4. User confirms the paper size (A4, etc.).
5. The app computes a **perspective transform** (homography) from the paper's 4 corners to a flat rectangle of the real size.
6. The sketch is warped into that rectangle, so it appears printed on the paper in the camera view.
7. User locks the overlay and starts drawing.

---

## 4. Technical Design

### 4.1 Platform and stack (recommended)

| Option | Pros | Cons |
|--------|------|------|
| **Flutter + OpenCV (FFI/plugin)**: recommended | One codebase for Android and iOS, fast UI | Camera and AR tracking need plugins or native code |
| Native Android (Kotlin + CameraX + OpenCV) | Best camera control and performance | Android only |
| React Native + Vision Camera | Familiar to JS developers | Heavy image processing needs native modules |

**Assumption:** start with **Android first** (easier to test, no Apple developer fee), using Flutter so iOS stays possible later. If you prefer Kotlin or another stack, the architecture below stays the same.

Core libraries:
- **OpenCV** for image processing and geometry (`cvtColor`, `GaussianBlur`, `Canny`, `findContours`, `getPerspectiveTransform`, `warpPerspective`)
- **CameraX** (Android) / `camera` or `camerax` plugin (Flutter) for the live preview
- **ARCore / ARKit** (optional, v2) for stable world tracking
- **SQLite / Hive / Isar** for local project storage
- **Riverpod / Bloc** for state management (Flutter)

### 4.2 Image to Sketch pipeline

Classic "pencil sketch" algorithm (fast, works offline, no ML needed):

1. Convert to grayscale.
2. Invert the grayscale image.
3. Apply Gaussian blur to the inverted image (kernel size controls the pencil look).
4. Blend using **color dodge**: `result = gray / (255 - blurredInverted) * 256`.
5. Optional: increase contrast, apply paper texture, threshold for clean line art.

Alternative line-art styles:
- **Canny edge detection** gives thin outlines (good for tracing).
- **XDoG (Extended Difference of Gaussians)** gives a more artistic ink look.
- **Adaptive threshold** gives a clean black and white comic style.

User controls: blur radius, line thickness, contrast/brightness, detail level, invert (white lines on black).

Optional v3: ML style models (e.g. a small TFLite/ONNX "photo to line art" model) for higher quality.

### 4.3 Paper selection and fitting (geometry)

Inputs:
- 4 corner points of the paper in camera-image coordinates, `src = [TL, TR, BR, BL]`
- Real paper size, e.g. A4 = 210 x 297 mm, giving the aspect ratio

Steps:
1. Define the target rectangle `dst = [(0,0), (W,0), (W,H), (0,H)]`, where W and H follow the paper's aspect ratio.
2. Fit the sketch inside `dst` (**contain** by default, with a **fill** option that crops), keeping the sketch aspect ratio. Let the user shift and zoom within the paper.
3. Compute `M = getPerspectiveTransform(dst, src)` to map paper space into camera space.
4. Render the sketch through `M` on top of the camera preview using a GPU transform (a 3x3 matrix on a texture/shader or Android `Matrix.setPolyToPoly`). Don't use CPU `warpPerspective` per frame if you can avoid it.
5. Opacity and blend mode (multiply works well, so white areas disappear and only the lines remain).

Auto paper detection (v2): grayscale, blur, Canny, `findContours`, `approxPolyDP`, pick the largest 4-point convex contour, order the corners, and let the user confirm.

### 4.4 The hard problem: keeping the overlay locked while holding the phone

If the phone moves, the overlay must move with the paper. Options, from simplest to best:

| Level | Method | Notes |
|-------|--------|-------|
| 0 (MVP) | **Phone on a stand/tripod, static overlay** | Overlay is fixed on screen. Simple and reliable. Recommend this in onboarding. |
| 1 | **Re-detect paper corners each frame** | Works if the whole paper stays visible; can jitter. Smooth with a Kalman or low-pass filter. |
| 2 | **Feature tracking** (ORB/optical flow on the paper area), updating the homography each frame | Works with partial occlusion by hand and pencil. Needs drift correction. |
| 3 | **ARCore/ARKit** plane or image anchoring | Most stable. The anchor stays fixed in world space. Slightly more complex setup. |

**Decision:** ship Level 0 in the MVP, add Level 1 in v2, evaluate Level 3 after that. Hands and pencil will block the paper while drawing, which is why tracking must tolerate occlusion (Level 2 or 3).

### 4.5 Architecture

```
app/
 ├─ ui/            screens, widgets (home, editor, camera, projects)
 ├─ state/         view models / providers
 ├─ domain/        entities (Project, PaperSize, SketchSettings)
 ├─ data/          local DB, file storage, repositories
 ├─ processing/    sketch pipeline (OpenCV wrappers)
 ├─ camera/        camera controller, frame stream
 └─ geometry/      homography, paper detection, tracking
```

Data model:
- `Project { id, title, originalImagePath, sketchImagePath, sketchSettings, paperSize, paperCorners, overlayTransform, createdAt, updatedAt }`
- `PaperSize { name, widthMm, heightMm }`
- `SketchSettings { style, blur, contrast, lineThickness, invert }`

Performance rules:
- Run sketch conversion on a background isolate/thread, and downscale the preview for sliders (full resolution only on save).
- Keep the camera preview and overlay on the GPU.
- Cache the sketch bitmap; recompute only when settings change.

---

## 5. UI / UX Plan

### Screens
1. **Home**: "New sketch" button, recent projects grid
2. **Image picker**: gallery or camera, with crop
3. **Sketch editor**: before/after preview, style chips, sliders, "Next"
4. **Paper setup**: size presets, orientation (portrait/landscape), custom size
5. **Camera overlay**: live view, 4-corner handles, opacity slider, lock button, flashlight, grid toggle
6. **Projects**: saved list with thumbnails
7. **Settings**: units (cm/in), theme, language, privacy

### UX details
- First-time tutorial (3 cards): place the phone on a stand, mark the paper, start drawing.
- Show a "hold steady" hint if tracking is lost.
- Keep the screen awake in overlay mode.
- Big touch targets for corner handles, with a magnifier loupe while dragging a corner.
- Lock button prevents accidental moves while drawing.

---

## 6. Development Roadmap

| Phase | Duration (solo, part-time) | Deliverables |
|-------|---------------------------|--------------|
| 0. Setup | 2-3 days | Repo, project skeleton, CI, permissions (camera, storage) |
| 1. Sketch converter | 1-2 weeks | Gallery/camera import, pencil sketch pipeline, sliders, save |
| 2. Camera overlay | 1-2 weeks | Live preview, overlay image, opacity/move/scale/rotate |
| 3. Paper selection | 1-2 weeks | 4-corner handles, paper presets, perspective fit, lock mode |
| 4. Projects and polish | 1 week | Local storage, project list, settings, onboarding |
| 5. Testing and beta | 1-2 weeks | Device testing, bug fixes, performance tuning, friends beta |
| **MVP release** | **~6-9 weeks** | Android release (Play Store internal/closed testing) |
| 6. v2 | 4-8 weeks | Auto paper detection, tracking, grid mode, export at print size |
| 7. iOS | 2-4 weeks | iOS build, App Store submission |

### Milestone checklist
- [ ] M1: Photo in, sketch out (looks good on 10 sample images)
- [ ] M2: Overlay visible on the camera and adjustable
- [ ] M3: Paper rectangle fits and the sketch aligns with a real sheet of paper
- [ ] M4: Save and reopen projects
- [ ] M5: Closed beta with at least 5 real users drawing with it
- [ ] M6: Store release

---

## 7. Testing Plan

- **Unit tests:** geometry (homography, corner ordering, aspect-ratio fitting), settings serialization.
- **Visual tests:** a fixed set of sample images and expected sketch outputs.
- **Device tests:** low-end, mid-range and flagship Android phones, with different camera resolutions and aspect ratios.
- **Real-world tests:** A4 paper on a desk, in dim light, bright light, with the hand blocking part of the paper, and with a tilted phone.
- **Accuracy test:** print the sketch at A4, lay it on the paper, and measure the alignment error (target under 3 mm).
- **Performance targets:** camera overlay at 30 fps, sketch preview update under 300 ms, cold start under 2 s.

---

## 8. Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Overlay drifts when the phone moves | High | Start with a stand-based workflow, add tracking later |
| Hand/pencil occludes the paper | High | Occlusion-tolerant tracking (feature-based or AR anchor) |
| Perspective distortion and lens distortion | Medium | Encourage a top-down angle, show a tilt indicator using the gyroscope |
| Sketch quality varies by photo | Medium | Presets, auto-contrast, tips for good source photos |
| Battery drain and heat (camera + processing) | Medium | GPU rendering, limit processing to the setup stage, dim UI |
| Different phones have different camera behavior | Medium | Test on many devices, use CameraX which normalizes behavior |
| Copyright issues when users trace others' art | Low-Medium | Terms of use note: user is responsible for the images they import |

---

## 9. Privacy and Legal

- Process all images **on-device**. Do not upload photos anywhere by default.
- Request only the permissions needed (camera, image access).
- Add a short privacy policy (required by app stores).
- Terms of use: the user owns or has rights to the images they trace.

---

## 10. Monetization (optional, decide later)

- **Free tier:** basic sketch styles, 3 saved projects, small watermark on exports.
- **Pro (one-time or subscription):** all styles, unlimited projects, grid mode, auto paper detection, print-size export, no ads.
- Alternative: free with a single rewarded ad per export.

---

## 11. Immediate Next Steps (this week)

1. Choose the stack (recommended: Flutter + OpenCV, Android first).
2. Create the repo and project skeleton.
3. Write a quick prototype of the sketch pipeline in Python with OpenCV on 10 test images. Tune the settings you like best before porting to the app.
4. Prototype the paper geometry in Python too: given 4 points and a paper size, warp the sketch onto a photo of a real sheet of paper.
5. Build the Phase 1 screen: pick image, sketch, save.

---

## 12. Open Questions to Decide

- Android only first, or both platforms from the start?
- Will users mostly use a stand, or hold the phone? (This decides how much to invest in tracking.)
- Do you want a pencil look only, or several art styles at launch?
- Free, paid, or free with ads?
- Do you want a separate printable-export feature (so the sketch can be traced on a light box instead)?

---

## 13. Reference: Sketch Algorithm Starter (Python, for prototyping)

```python
import cv2

def to_sketch(path, blur=21):
    img = cv2.imread(path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    inv = 255 - gray
    blurred = cv2.GaussianBlur(inv, (blur | 1, blur | 1), 0)
    sketch = cv2.divide(gray, 255 - blurred, scale=256)
    return sketch

cv2.imwrite("sketch.png", to_sketch("photo.jpg"))
```

```python
import cv2, numpy as np

def warp_to_paper(sketch, corners, paper_mm=(210, 297), scale=3):
    # corners: [TL, TR, BR, BL] on the camera image
    w, h = paper_mm[0] * scale, paper_mm[1] * scale
    sk = cv2.resize(sketch, (w, h))
    dst = np.float32([[0, 0], [w, 0], [w, h], [0, h]])
    src = np.float32(corners)
    M = cv2.getPerspectiveTransform(dst, src)
    return M, sk  # use M to draw sk into the camera frame
```
