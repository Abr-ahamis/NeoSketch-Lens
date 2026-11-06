import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sketchlens/models/sketch_project.dart';
import 'package:sketchlens/processing/sketch_processor.dart';

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
      final output = await processSketch(
        bytes,
        SketchOptions(style: style),
        maxDimension: 0,
      );
      expect(img.decodePng(output), isNotNull, reason: style.name);
    }
  });

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
