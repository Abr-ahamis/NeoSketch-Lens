import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/project_repository.dart';
import '../../geometry/homography.dart';
import '../../models/sketch_project.dart';

class CameraOverlayScreen extends ConsumerStatefulWidget {
  const CameraOverlayScreen({required this.project, super.key});
  final SketchProject project;

  @override
  ConsumerState<CameraOverlayScreen> createState() =>
      _CameraOverlayScreenState();
}

class _CameraOverlayScreenState extends ConsumerState<CameraOverlayScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Object? _cameraError;
  final _overlayKey = GlobalKey();
  StreamSubscription<AccelerometerEvent>? _tiltSubscription;
  List<Offset> _corners = [];
  var _opacity = 0.8;
  var _locked = false;
  var _grid = false;
  var _flashlight = false;
  var _keepAwake = true;
  var _tilt = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _corners = List.of(widget.project.corners);
    _startCamera();
    _tiltSubscription = accelerometerEventStream().listen((event) {
      if (!mounted) return;
      final horizontalGravity = math.sqrt(
        event.y * event.y + event.z * event.z,
      );
      final angle = math.atan2(event.x, horizontalGravity) * 180 / math.pi;
      setState(() => _tilt = angle);
    }, onError: (_) {});
    WakelockPlus.enable();
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera is available on this device.');
      }
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraError = null;
      });
    } catch (error) {
      debugPrint('[SketchLens] Camera startup failed (${error.runtimeType}).');
      if (mounted) setState(() => _cameraError = error);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
      WakelockPlus.disable();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
      if (_keepAwake) WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tiltSubscription?.cancel();
    _controller?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _toggleFlashlight() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final enabled = !_flashlight;
      await controller.setFlashMode(enabled ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flashlight = enabled);
    } catch (_) {
      _message('Flashlight is unavailable on this camera.');
    }
  }

  Future<void> _toggleAwake() async {
    final next = !_keepAwake;
    setState(() => _keepAwake = next);
    await WakelockPlus.toggle(enable: next);
  }

  void _moveCorner(int index, Offset globalPosition) {
    final renderObject = _overlayKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final local = renderObject.globalToLocal(globalPosition);
    final size = renderObject.size;
    final normalized = Offset(
      (local.dx / size.width).clamp(0.02, 0.98),
      (local.dy / size.height).clamp(0.02, 0.98),
    );
    setState(() => _corners[index] = normalized);
  }

  Future<void> _saveAlignment() async {
    try {
      final saved = widget.project.copyWith(corners: _corners);
      await ref.read(projectRepositoryProvider).save(saved);
      if (!mounted) return;
      _message('Project and paper alignment saved on this device.');
    } catch (error) {
      debugPrint('[SketchLens] Alignment save failed (${error.runtimeType}).');
      if (mounted) _message('Could not save the alignment. Try again.');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Align over paper'),
        backgroundColor: const Color(0xDD101114),
        actions: [
          IconButton(
            tooltip: _flashlight ? 'Turn flashlight off' : 'Turn flashlight on',
            onPressed: _toggleFlashlight,
            icon: Icon(_flashlight ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            tooltip: _grid ? 'Hide grid' : 'Show grid',
            onPressed: () => setState(() => _grid = !_grid),
            icon: Icon(_grid ? Icons.grid_off : Icons.grid_on),
          ),
          IconButton(
            tooltip: 'Keep screen awake',
            onPressed: _toggleAwake,
            icon: Icon(
              _keepAwake
                  ? Icons.screen_lock_portrait
                  : Icons.screen_lock_rotation,
            ),
          ),
          IconButton(
            tooltip: _locked ? 'Unlock corners' : 'Lock corners',
            onPressed: () => setState(() => _locked = !_locked),
            icon: Icon(_locked ? Icons.lock : Icons.lock_open),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final paper = fitPaperRect(
            size,
            widget.project.paper.widthMm / widget.project.paper.heightMm,
          );
          final destination = _corners
              .map(
                (point) =>
                    Offset(point.dx * size.width, point.dy * size.height),
              )
              .toList(growable: false);
          final source = [
            Offset.zero,
            Offset(paper.width, 0),
            Offset(paper.width, paper.height),
            Offset(0, paper.height),
          ];
          Widget? transformedSketch;
          if (isConvexQuad(destination)) {
            try {
              final localDestination = destination
                  .map((point) => point - paper.topLeft)
                  .toList(growable: false);
              transformedSketch = Transform(
                alignment: Alignment.topLeft,
                transform: homographyTransform(source, localDestination),
                child: SizedBox(
                  width: paper.width,
                  height: paper.height,
                  child: Image.memory(
                    widget.project.sketchBytes,
                    fit: BoxFit.contain,
                    opacity: AlwaysStoppedAnimation(_opacity),
                  ),
                ),
              );
            } on ArgumentError {
              transformedSketch = null;
            }
          }

          return Stack(
            key: _overlayKey,
            fit: StackFit.expand,
            children: [
              if (_controller?.value.isInitialized == true)
                CameraPreview(_controller!)
              else
                _CameraState(error: _cameraError, onRetry: _startCamera),
              if (transformedSketch != null)
                Positioned(
                  left: paper.left,
                  top: paper.top,
                  width: paper.width,
                  height: paper.height,
                  child: IgnorePointer(child: transformedSketch),
                ),
              if (_grid) CustomPaint(painter: _GridPainter()),
              if (!_locked)
                for (var index = 0; index < _corners.length; index++)
                  Positioned(
                    left: destination[index].dx - 23,
                    top: destination[index].dy - 23,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        _moveCorner(index, details.globalPosition);
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xCCF1C778),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xE6101114),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.screen_rotation_alt, size: 17),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _tilt.abs() > 2.5
                                    ? 'Try to hold your phone more parallel to the paper'
                                    : 'Camera is roughly level',
                              ),
                            ),
                            Text(
                              'Tilt ${_tilt.toStringAsFixed(1)}°',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Sketch opacity'),
                            Expanded(
                              child: Slider(
                                value: _opacity,
                                onChanged: (value) =>
                                    setState(() => _opacity = value),
                              ),
                            ),
                            Text('${(_opacity * 100).round()}%'),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saveAlignment,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save alignment'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CameraState extends StatelessWidget {
  const _CameraState({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF18191C),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              error == null ? 'Starting camera…' : 'Camera unavailable. Allow camera access in Android settings and retry.',
              textAlign: TextAlign.center,
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * i / 3, 0),
        Offset(size.width * i / 3, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height * i / 3),
        Offset(size.width, size.height * i / 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
