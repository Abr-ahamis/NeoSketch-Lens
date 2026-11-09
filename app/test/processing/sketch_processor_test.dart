import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:sketchlens/models/sketch_project.dart';
import 'package:sketchlens/processing/sketch_processor.dart';
import 'package:sketchlens/features/editor/sketch_editor_screen.dart';

void main() {
  test(
    'pencil processing is deterministic and returns transparent PNG',
    () async {
      final source = img.Image(width: 8, height: 8);
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          final value = x < 4 ? 30 : 220;
          source.setPixelRgb(x, y, value, value, value);
        }
      }
      final bytes = Uint8List.fromList(img.encodePng(source));

      final first = await processSketch(
        bytes,
        const SketchOptions(),
        maxDimension: 0,
      );
      final second = await processSketch(
        bytes,
        const SketchOptions(),
        maxDimension: 0,
      );

      expect(first, orderedEquals(second));
      final result = img.decodePng(first)!;
      expect(result.width, 8);
      expect(result.height, 8);
      expect(result.numChannels, 4);
      expect(result.getPixel(0, 0).a, greaterThan(0));
      expect(result.getPixel(7, 0).a, lessThan(result.getPixel(0, 0).a));
    },
  );

  test('all styles produce a decodable local result', () async {
    final source = img.Image(width: 12, height: 10);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgb(x, y, x * 18, y * 20, (x + y) * 9);
      }
    }
    final bytes = Uint8List.fromList(img.encodePng(source));
    for (final style in SketchStyle.values) {
      late Uint8List output;
      try {
        output = await processSketch(
          bytes,
          SketchOptions(style: style),
          maxDimension: 0,
        );
      } on FormatException catch (error) {
        fail('${style.name} produced no visible sketch: ${error.message}');
      }
      expect(img.decodePng(output), isNotNull, reason: style.name);
    }
  });

  test('basic, advanced, and professional levels render differently', () async {
    final source = img.Image(width: 64, height: 56);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final wave = (x * 7 + y * 5 + ((x * y) % 43)) % 256;
        source.setPixelRgb(x, y, wave, (wave * 4) % 256, 255 - wave);
      }
    }
    final bytes = Uint8List.fromList(img.encodePng(source));
    final basic = await processSketch(
      bytes,
      const SketchOptions(level: SketchLevel.basic),
    );
    final basicWithoutHatching = await processSketch(
      bytes,
      const SketchOptions(level: SketchLevel.basic, crosshatchStrength: 0),
    );
    final advanced = await processSketch(
      bytes,
      const SketchOptions(level: SketchLevel.advanced),
    );
    final professional = await processSketch(
      bytes,
      const SketchOptions(level: SketchLevel.professional),
    );

    expect(basic, isNot(orderedEquals(advanced)));
    expect(basic, isNot(orderedEquals(basicWithoutHatching)));
    expect(advanced, isNot(orderedEquals(professional)));
  });

  test('adjustment options serialize without losing hidden mode values', () {
    const options = SketchOptions(
      level: SketchLevel.professional,
      pencilDarkness: 0.91,
      intensity: 0.37,
      darkness: 0.82,
      highlights: 0.23,
      shadows: 0.71,
      detailStrength: 0.91,
      smoothness: 0.62,
      sketchOpacity: 0.48,
      edgeSensitivity: 0.76,
      strokeDensity: 0.68,
      graphiteGrain: 0.31,
      crosshatchStrength: 0.57,
      facialVolume: 0.84,
      skinTonalVariation: 0.73,
      contourSoftness: 0.42,
      skinHatching: 0.38,
    );
    final restored = SketchOptions.fromJson(options.toJson());

    expect(restored.level, options.level);
    expect(restored.intensity, options.intensity);
    expect(restored.darkness, options.darkness);
    expect(restored.pencilDarkness, options.pencilDarkness);
    expect(restored.highlights, options.highlights);
    expect(restored.shadows, options.shadows);
    expect(restored.detailStrength, options.detailStrength);
    expect(restored.smoothness, options.smoothness);
    expect(restored.sketchOpacity, options.sketchOpacity);
    expect(restored.edgeSensitivity, options.edgeSensitivity);
    expect(restored.strokeDensity, options.strokeDensity);
    expect(restored.graphiteGrain, options.graphiteGrain);
    expect(restored.crosshatchStrength, options.crosshatchStrength);
    expect(restored.facialVolume, options.facialVolume);
    expect(restored.skinTonalVariation, options.skinTonalVariation);
    expect(restored.contourSoftness, options.contourSoftness);
    expect(restored.skinHatching, options.skinHatching);
  });

  test('opacity and detail adjustments change rendered alpha layers', () async {
    final source = img.Image(width: 36, height: 28);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final value = (x * 7 + y * 11) % 256;
        source.setPixelRgb(x, y, value, (value * 3) % 256, 255 - value);
      }
    }
    final bytes = Uint8List.fromList(img.encodePng(source));
    final full = await processSketch(bytes, const SketchOptions());
    final faded = await processSketch(
      bytes,
      const SketchOptions(sketchOpacity: 0.25),
    );
    final detailed = await processSketch(
      bytes,
      const SketchOptions(detailStrength: 0.05, darkness: 0.2),
    );
    final lightPencil = await processSketch(
      bytes,
      const SketchOptions(pencilDarkness: 0.15),
    );
    final darkPencil = await processSketch(
      bytes,
      const SketchOptions(pencilDarkness: 0.95),
    );
    final lowVolume = await processSketch(
      bytes,
      const SketchOptions(facialVolume: 0.1, skinTonalVariation: 0.1),
    );
    final highVolume = await processSketch(
      bytes,
      const SketchOptions(facialVolume: 0.95, skinTonalVariation: 0.9),
    );

    expect(full, isNot(orderedEquals(faded)));
    expect(full, isNot(orderedEquals(detailed)));
    expect(lightPencil, isNot(orderedEquals(darkPencil)));
    expect(_alphaSum(darkPencil), greaterThan(_alphaSum(lightPencil)));
    expect(lowVolume, isNot(orderedEquals(highVolume)));
  });

  test(
    'supported encodings, dimensions, and color modes produce visible PNGs',
    () async {
      final rgb = img.Image(width: 48, height: 32);
      for (var y = 0; y < rgb.height; y++) {
        for (var x = 0; x < rgb.width; x++) {
          final stripe = ((x ~/ 6 + y ~/ 5) % 2) == 0;
          rgb.setPixelRgb(
            x,
            y,
            stripe ? 235 : 24,
            (x * 5 + y * 3) % 256,
            stripe ? 35 : 220,
          );
        }
      }
      final grayscale = img.Image(width: 24, height: 24);
      for (var y = 0; y < grayscale.height; y++) {
        for (var x = 0; x < grayscale.width; x++) {
          final value = (x * 9 + y * 7) % 256;
          grayscale.setPixelRgb(x, y, value, value, value);
        }
      }
      final rgba = img.Image(width: 24, height: 24, numChannels: 4);
      for (var y = 0; y < rgba.height; y++) {
        for (var x = 0; x < rgba.width; x++) {
          rgba.setPixelRgba(x, y, x * 10, y * 10, (x + y) * 5, (x * 11) % 256);
        }
      }

      final samples = <String, Uint8List>{
        'jpeg': Uint8List.fromList(img.encodeJpg(rgb, quality: 90)),
        'png': Uint8List.fromList(img.encodePng(rgba)),
        'gif': Uint8List.fromList(img.encodeGif(rgb)),
        'bmp': Uint8List.fromList(img.encodeBmp(grayscale)),
        'webp': Uint8List.fromList(img.encodeWebP(rgb)),
      };
      for (final sample in samples.entries) {
        final output = await processSketch(sample.value, const SketchOptions());
        final decoded = img.decodePng(output);
        expect(decoded, isNotNull, reason: sample.key);
        expect(decoded!.width, greaterThan(0), reason: sample.key);
        expect(decoded.height, greaterThan(0), reason: sample.key);
        final rgbaBytes = decoded.getBytes(order: img.ChannelOrder.rgba);
        expect(
          Iterable<int>.generate(
            rgbaBytes.length ~/ 4,
            (i) => rgbaBytes[i * 4 + 3],
          ).any((alpha) => alpha > 24),
          isTrue,
          reason: '${sample.key} should contain visible sketch marks',
        );
      }
    },
  );

  test(
    'invalid and detail-free images fail instead of reporting success',
    () async {
      await expectLater(
        processSketch(Uint8List.fromList([1, 2, 3, 4]), const SketchOptions()),
        throwsA(isA<FormatException>()),
      );

      final blank = img.Image(width: 16, height: 16);
      for (var y = 0; y < blank.height; y++) {
        for (var x = 0; x < blank.width; x++) {
          blank.setPixelRgb(x, y, 255, 255, 255);
        }
      }
      await expectLater(
        processSketch(
          Uint8List.fromList(img.encodePng(blank)),
          const SketchOptions(),
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );

  testWidgets(
    'editor levels update live without overflowing the compact dock',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final source = img.Image(width: 20, height: 20);
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          final tone = (x * 13 + y * 9) % 256;
          source.setPixelRgb(x, y, tone, tone, tone);
        }
      }
      final bytes = Uint8List.fromList(img.encodePng(source));
      final now = DateTime.now();
      final project = SketchProject(
        id: 'test',
        title: 'Portrait',
        originalBytes: bytes,
        sketchBytes: bytes,
        options: const SketchOptions(),
        paper: const PaperSpec(),
        corners: const [
          Offset(0.1, 0.1),
          Offset(0.9, 0.1),
          Offset(0.9, 0.9),
          Offset(0.1, 0.9),
        ],
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: SketchEditorScreen(project: project)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsOneWidget);

      await tester.tap(find.text('L1 Basic'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('L3 Pro'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  test('project thumbnails are downscaled for home-screen cards', () async {
    final source = img.Image(width: 800, height: 600);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgb(x, y, 240, 240, 240);
      }
    }
    final bytes = Uint8List.fromList(img.encodePng(source));

    final thumbnail = await createSketchThumbnail(bytes, maxDimension: 120);
    final decoded = img.decodePng(thumbnail)!;

    expect(decoded.width, 120);
    expect(decoded.height, 90);
  });
}

int _alphaSum(Uint8List pngBytes) {
  final image = img.decodePng(pngBytes)!;
  final rgba = image.getBytes(order: img.ChannelOrder.rgba);
  var sum = 0;
  for (var i = 3; i < rgba.length; i += 4) {
    sum += rgba[i];
  }
  return sum;
}
