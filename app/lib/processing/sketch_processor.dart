import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/sketch_project.dart';

const _maxCachedPreviews = 2;
final _previewInputs = LinkedHashMap<Uint8List, Uint8List>(
  equals: identical,
  hashCode: identityHashCode,
);

void clearSketchPreviewCache(Uint8List sourceBytes) {
  _previewInputs.remove(sourceBytes);
}

Future<Uint8List> createSketchThumbnail(
  Uint8List sketchBytes, {
  int maxDimension = 360,
}) => compute(_createThumbnailWorker, {
  'source': sketchBytes,
  'maxDimension': maxDimension,
});

Uint8List _createThumbnailWorker(Map<String, Object?> input) {
  final bytes = input['source']! as Uint8List;
  final maxDimension = input['maxDimension']! as int;
  var decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Sketch thumbnail could not be decoded.');
  }
  decoded = img.bakeOrientation(decoded);
  if (decoded.width > maxDimension || decoded.height > maxDimension) {
    final ratio = maxDimension / math.max(decoded.width, decoded.height);
    decoded = img.copyResize(
      decoded,
      width: (decoded.width * ratio).round().clamp(1, maxDimension),
      height: (decoded.height * ratio).round().clamp(1, maxDimension),
      interpolation: img.Interpolation.linear,
    );
  }
  return Uint8List.fromList(img.encodePng(decoded, level: 1));
}

Future<Uint8List> processSketch(
  Uint8List sourceBytes,
  SketchOptions options, {
  int maxDimension = 1024,
}) {
  return _processSketchWithCachedInput(sourceBytes, options, maxDimension);
}

Future<Uint8List> _processSketchWithCachedInput(
  Uint8List sourceBytes,
  SketchOptions options,
  int maxDimension,
) async {
  final previewInput = maxDimension > 0
      ? _previewInputs.remove(sourceBytes)
      : null;
  if (previewInput != null) _previewInputs[sourceBytes] = previewInput;

  final result = await compute(_processSketchWorker, {
    'source': previewInput ?? sourceBytes,
    'options': options.toJson(),
    'maxDimension': previewInput == null ? maxDimension : 0,
    'cachePreview': maxDimension > 0 && previewInput == null,
  });

  final preparedInput = result['preview'];
  if (preparedInput != null) {
    _previewInputs[sourceBytes] = preparedInput;
    if (_previewInputs.length > _maxCachedPreviews) {
      _previewInputs.remove(_previewInputs.keys.first);
    }
  }
  return result['sketch']!;
}

Map<String, Uint8List> _processSketchWorker(Map<String, Object?> input) {
  final sourceBytes = input['source']! as Uint8List;
  final optionsJson = Map<String, Object?>.from(input['options']! as Map);
  final options = SketchOptions.fromJson(optionsJson);
  final maxDimension = input['maxDimension']! as int;

  var source = img.decodeImage(sourceBytes);
  if (source == null) {
    throw const FormatException('This image format could not be decoded.');
  }
  source = img.bakeOrientation(source);
  final wasResized =
      maxDimension > 0 &&
      (source.width > maxDimension || source.height > maxDimension);
  if (wasResized) {
    final ratio = maxDimension / math.max(source.width, source.height);
    source = img.copyResize(
      source,
      width: (source.width * ratio).round().clamp(1, maxDimension),
      height: (source.height * ratio).round().clamp(1, maxDimension),
      interpolation: img.Interpolation.linear,
    );
  }

  final cachePreview = input['cachePreview']! as bool;
  final preparedInput = cachePreview && wasResized
      ? Uint8List.fromList(img.encodePng(source, level: 1))
      : null;
  final width = source.width;
  final height = source.height;
  final length = width * height;
  final rgba = source.getBytes(order: img.ChannelOrder.rgba);
  final gray = Uint8List(length);

  for (var pixel = 0; pixel < length; pixel++) {
    final offset = pixel * 4;
    final red = rgba[offset];
    final green = rgba[offset + 1];
    final blue = rgba[offset + 2];
    gray[pixel] = (0.299 * red + 0.587 * green + 0.114 * blue).round();
  }

  final inverted = Uint8List(length);
  for (var i = 0; i < length; i++) {
    inverted[i] = 255 - gray[i];
  }

  final blurRadius = math.max(1, (options.blurRadius / 2).round());
  var blurred = inverted;
  for (var pass = 0; pass < 3; pass++) {
    blurred = _boxBlur(blurred, width, height, blurRadius);
  }

  final pencil = Uint8List(length);
  for (var i = 0; i < length; i++) {
    final invertedBlur = 255 - blurred[i];
    final denominator = math.max(1, invertedBlur);
    pencil[i] = (gray[i] * 256 / denominator).round().clamp(0, 255);
  }

  final edgeMap = _sobelEdgeMap(gray, width, height);
  final values = Uint8List(length);
  switch (options.style) {
    case SketchStyle.pencil:
      _blendEdges(values, pencil, edgeMap, options.edgeStrength);
    case SketchStyle.outline:
      values.setAll(0, edgeMap);
    case SketchStyle.charcoal:
      for (var i = 0; i < length; i++) {
        final enhanced = ((pencil[i] - 128) * 1.65 + 118).round();
        values[i] = enhanced.clamp(0, 255);
      }
      _blendEdges(values, values, edgeMap, options.edgeStrength * 0.5);
    case SketchStyle.crosshatch:
      _crosshatch(values, gray, width, height);
    case SketchStyle.soft:
      final soft = _boxBlur(pencil, width, height, 2);
      _blendEdges(values, soft, edgeMap, options.edgeStrength * 0.25);
  }

  final outputBytes = Uint8List(length * 4);
  for (var i = 0; i < length; i++) {
    final adjusted =
        (((values[i] - 128) * options.contrast) + 128 + options.brightness)
            .round()
            .clamp(0, 255);
    final finalValue = options.invert ? 255 - adjusted : adjusted;
    final lineAlpha = options.invert ? finalValue : 255 - finalValue;
    final color = options.invert ? 255 : 0;
    final offset = i * 4;
    outputBytes[offset] = color;
    outputBytes[offset + 1] = color;
    outputBytes[offset + 2] = color;
    outputBytes[offset + 3] = lineAlpha;
  }
  final output = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: outputBytes.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );

  final result = <String, Uint8List>{
    'sketch': Uint8List.fromList(img.encodePng(output, level: 1)),
  };
  if (preparedInput != null) result['preview'] = preparedInput;
  return result;
}

void _blendEdges(
  Uint8List destination,
  Uint8List sketch,
  Uint8List edges,
  double strength,
) {
  final mix = strength.clamp(0, 1);
  for (var i = 0; i < destination.length; i++) {
    destination[i] = (sketch[i] * (1 - mix) + edges[i] * mix).round();
  }
}

Uint8List _boxBlur(Uint8List input, int width, int height, int radius) {
  if (radius <= 0 || width < 2 || height < 2) return Uint8List.fromList(input);
  final horizontal = Uint8List(input.length);
  final output = Uint8List(input.length);
  final diameter = radius * 2 + 1;

  for (var y = 0; y < height; y++) {
    final row = y * width;
    var sum = 0;
    for (var dx = -radius; dx <= radius; dx++) {
      sum += input[row + dx.clamp(0, width - 1)];
    }
    for (var x = 0; x < width; x++) {
      horizontal[row + x] = (sum / diameter).round();
      final removeX = (x - radius).clamp(0, width - 1);
      final addX = (x + radius + 1).clamp(0, width - 1);
      sum += input[row + addX] - input[row + removeX];
    }
  }

  for (var x = 0; x < width; x++) {
    var sum = 0;
    for (var dy = -radius; dy <= radius; dy++) {
      sum += horizontal[dy.clamp(0, height - 1) * width + x];
    }
    for (var y = 0; y < height; y++) {
      output[y * width + x] = (sum / diameter).round();
      final removeY = (y - radius).clamp(0, height - 1);
      final addY = (y + radius + 1).clamp(0, height - 1);
      sum += horizontal[addY * width + x] - horizontal[removeY * width + x];
    }
  }

  return output;
}

Uint8List _sobelEdgeMap(Uint8List gray, int width, int height) {
  final edges = Uint8List(width * height)..fillRange(0, width * height, 255);
  for (var y = 1; y < height - 1; y++) {
    for (var x = 1; x < width - 1; x++) {
      final top = (y - 1) * width;
      final middle = y * width;
      final bottom = (y + 1) * width;
      final gx =
          -gray[top + x - 1] +
          gray[top + x + 1] -
          2 * gray[middle + x - 1] +
          2 * gray[middle + x + 1] -
          gray[bottom + x - 1] +
          gray[bottom + x + 1];
      final gy =
          -gray[top + x - 1] -
          2 * gray[top + x] -
          gray[top + x + 1] +
          gray[bottom + x - 1] +
          2 * gray[bottom + x] +
          gray[bottom + x + 1];
      // Compare squared magnitude to avoid a costly square root per pixel.
      if (gx * gx + gy * gy >= 32400) edges[middle + x] = 0;
    }
  }
  return edges;
}

void _crosshatch(Uint8List output, Uint8List gray, int width, int height) {
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = y * width + x;
      final value = gray[index];
      final step = value < 55
          ? 5
          : value < 95
          ? 7
          : value < 140
          ? 10
          : value < 185
          ? 15
          : 0;
      if (step == 0) {
        output[index] = 255;
      } else {
        final lineWidth = value < 95 ? 2 : 1;
        final hatch =
            x % step < lineWidth ||
            (value < 140 && y % step < lineWidth) ||
            (value < 95 && (x + y) % step < lineWidth);
        output[index] = hatch ? 0 : 255;
      }
    }
  }
}
