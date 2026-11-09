import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/sketch_project.dart';

const _maxCachedPreviews = 2;
const _maxSourcePixels = 50 * 1000 * 1000;
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
    throw const FormatException(
      'This image is invalid or uses an unsupported format. Choose a JPEG, PNG, WebP, GIF, BMP, TIFF, or TGA image.',
    );
  }
  if (source.width <= 0 || source.height <= 0) {
    throw const FormatException('The selected image has invalid dimensions.');
  }
  if (source.width > _maxSourcePixels ~/ source.height) {
    throw const FormatException(
      'This image is too large to process safely. Choose an image under 50 megapixels.',
    );
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
    final luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
    gray[pixel] =
        (((luminance - 128) * options.contrast) + 128 + options.brightness)
            .round()
            .clamp(0, 255);
  }

  final localRadius = math.max(1, (options.blurRadius / 3).round());
  final formRadius = localRadius + 2 + (options.smoothness * 8).round();
  final localTone = _boxBlur(gray, width, height, localRadius);
  final broadTone = _boxBlur(gray, width, height, formRadius);
  final edgeAnalysis = _sobelAnalysis(
    gray,
    width,
    height,
    options.edgeSensitivity,
    calculateOrientation: options.level == SketchLevel.advanced,
  );
  final edgeMap = edgeAnalysis.strength;
  var orientation = edgeAnalysis.orientation;
  var orientationConfidence = Float32List(length);
  if (options.level == SketchLevel.professional) {
    final tensor = _structureTensor(gray, width, height);
    orientation = tensor.orientation;
    orientationConfidence = tensor.coherence;
  } else {
    for (var i = 0; i < length; i++) {
      orientationConfidence[i] = edgeMap[i] / 255;
    }
  }
  final density = Float32List(length);
  for (var i = 0; i < length; i++) {
    final sourceTone = gray[i] / 255;
    final smoothTone =
        (sourceTone * (1 - options.smoothness)) +
        (broadTone[i] / 255 * options.smoothness);
    final tonalDarkness = 1 - smoothTone;
    final broadDarkness = 1 - broadTone[i] / 255;
    final localDarkDetail = math.max(0, (localTone[i] - gray[i]) / 255);
    final edge = edgeMap[i] / 255;
    final highlightProtection =
        (((gray[i] - 150) / 105).clamp(0, 1)) * options.highlights;

    final mediumScale = (localTone[i] - broadTone[i]).abs() / 255;
    final softenedEdge =
        edge * options.edgeStrength * (1 - options.contourSoftness * 0.72);
    var graphite = (switch (options.level) {
      SketchLevel.basic =>
        localDarkDetail * options.detailStrength * 0.95 +
            softenedEdge * 0.72 +
            tonalDarkness * options.shadows * 0.18,
      SketchLevel.advanced =>
        math.pow(broadDarkness, 1.28) * options.facialVolume * 0.82 +
            math.pow(tonalDarkness, 1.45) * options.shadows * 0.44 +
            localDarkDetail * options.detailStrength * 0.9 +
            mediumScale * options.skinTonalVariation * 0.24 +
            softenedEdge * 0.7 +
            tonalDarkness * options.darkness * 0.12,
      SketchLevel.professional =>
        math.pow(broadDarkness, 1.18) * options.facialVolume * 0.9 +
            math.pow(tonalDarkness, 1.25) * options.shadows * 0.45 +
            localDarkDetail * options.detailStrength * 0.9 +
            mediumScale * options.skinTonalVariation * 0.48 +
            softenedEdge * 0.8 +
            tonalDarkness * options.darkness * 0.18,
    }).toDouble();

    if (options.level != SketchLevel.basic &&
        (options.style == SketchStyle.pencil ||
            options.style == SketchStyle.charcoal) &&
        tonalDarkness > 0.2 &&
        (orientationConfidence[i] > 0.15 || tonalDarkness > 0.62) &&
        _isDirectionalHatch(i % width, i ~/ width, orientation[i], options)) {
      graphite +=
          (options.level == SketchLevel.professional ? 0.4 : 0.3) *
          options.strokeDensity;
    }

    if (options.style == SketchStyle.pencil &&
        options.level == SketchLevel.basic) {
      final x = i % width;
      final y = i ~/ width;
      final scale = math.max(1, math.max(width, height) ~/ 800);
      final firstFamily = _basicHatchLine(
        x + y,
        x - y,
        tonalDarkness,
        options.strokeDensity,
        scale,
      );
      final secondFamily =
          tonalDarkness > 0.52 &&
          _basicHatchLine(
            (x - y).abs(),
            x + y,
            tonalDarkness,
            options.strokeDensity,
            scale,
          );
      if (firstFamily) graphite += options.crosshatchStrength * 0.5;
      if (secondFamily) graphite += options.crosshatchStrength * 0.48;
    }

    if (options.level != SketchLevel.basic &&
        (options.style == SketchStyle.pencil ||
            options.style == SketchStyle.charcoal) &&
        tonalDarkness > 0.5 &&
        _isDirectionalHatch(
          i % width,
          i ~/ width,
          (orientation[i] + 2) & 7,
          options,
        )) {
      graphite +=
          options.crosshatchStrength *
          (options.level == SketchLevel.professional ? 0.5 : 0.34);
    }

    if (options.level == SketchLevel.professional &&
        broadDarkness > 0.22 &&
        orientationConfidence[i] > 0.1 &&
        _isDirectionalHatch(i % width, i ~/ width, orientation[i], options)) {
      graphite += options.skinHatching * orientationConfidence[i] * 0.3;
    }

    switch (options.style) {
      case SketchStyle.pencil:
        break;
      case SketchStyle.outline:
        graphite = edge * (0.45 + options.edgeStrength * 0.55);
      case SketchStyle.charcoal:
        graphite = graphite * 1.2 + edge * 0.12;
      case SketchStyle.crosshatch:
        if (_isHatchMark(i % width, i ~/ width, tonalDarkness, options)) {
          graphite += options.crosshatchStrength * 0.38;
        }
      case SketchStyle.soft:
        graphite =
            tonalDarkness * options.shadows * 0.72 +
            localDarkDetail * options.detailStrength * 0.3 +
            edge * options.edgeStrength * 0.15;
    }

    final grain = _grainAt(i);
    final grainStrength = switch (options.level) {
      SketchLevel.basic => 0.0,
      SketchLevel.advanced => math.max(0.12, options.graphiteGrain),
      SketchLevel.professional => math.max(0.2, options.graphiteGrain),
    };
    graphite =
        (graphite * (1 - highlightProtection)) +
        (grain * grainStrength * tonalDarkness);
    graphite =
        math.pow(graphite.clamp(0, 1), 1.4 - options.pencilDarkness * 0.8) *
        (0.25 + options.pencilDarkness * 1.25);
    density[i] = (graphite * options.intensity).clamp(0, 1);
  }

  if (options.style == SketchStyle.soft && options.smoothness > 0) {
    final densityBytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      densityBytes[i] = (density[i] * 255).round();
    }
    final softened = _boxBlur(
      densityBytes,
      width,
      height,
      1 + (options.smoothness * 3).round(),
    );
    for (var i = 0; i < length; i++) {
      density[i] = softened[i] / 255;
    }
  }

  final hasRenderableMarks = density.any((value) => value * 255 > 16);
  if (!hasRenderableMarks && options.intensity > 0) {
    throw const FormatException(
      'The image did not produce a visible sketch. Try a photo with more detail or contrast.',
    );
  }

  final outputBytes = Uint8List(length * 4);
  for (var i = 0; i < length; i++) {
    final color = options.invert ? 255 : 0;
    final offset = i * 4;
    outputBytes[offset] = color;
    outputBytes[offset + 1] = color;
    outputBytes[offset + 2] = color;
    outputBytes[offset + 3] = (density[i] * options.sketchOpacity * 255)
        .round()
        .clamp(0, 255);
  }
  final output = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: outputBytes.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );

  final encodedSketch = Uint8List.fromList(img.encodePng(output, level: 1));
  final verified = img.decodePng(encodedSketch);
  if (verified == null ||
      verified.width != width ||
      verified.height != height) {
    throw const FormatException(
      'The generated sketch could not be verified. Try processing the image again.',
    );
  }

  final result = <String, Uint8List>{'sketch': encodedSketch};
  if (preparedInput != null) result['preview'] = preparedInput;
  return result;
}

double _grainAt(int index) {
  final value = (index * 1103515245 + 12345) & 0x7fffffff;
  return ((value % 1000) / 999) - 0.5;
}

bool _isHatchMark(int x, int y, double darkness, SketchOptions options) {
  final step = (22 - options.strokeDensity * 12).round().clamp(8, 22);
  final lineWidth = darkness > 0.62 ? 2 : 1;
  final jitter = ((x * 13 + y * 7) % 3) - 1;
  final diagonal = (x + y + jitter) % step;
  final cross = (x - y).abs() % step;
  return (diagonal < lineWidth && _grainAt(x + y * 17) > -0.2) ||
      (darkness > 0.72 && cross < lineWidth);
}

bool _basicHatchLine(
  int projection,
  int alongStroke,
  double darkness,
  double strokeDensity,
  int scale,
) {
  if (darkness < 0.22) return false;
  final baseSpacing = darkness > 0.68
      ? 7
      : darkness > 0.5
      ? 10
      : 16;
  final spacing =
      math.max(4, (baseSpacing - strokeDensity * 2).round()) * scale;
  final lineNumber = projection ~/ spacing;
  final segment = alongStroke ~/ (14 * scale);
  final variation =
      (lineNumber * 1103515245 + segment * 12345 + 1013904223) & 0x7fffffff;
  if (variation % 7 == 0) return false;
  final offset = ((lineNumber * 13 + 7) % 3) - 1;
  final phase = ((projection + offset) % spacing + spacing) % spacing;
  final lineWidth = (darkness > 0.72 && variation % 4 == 0 ? 2 : 1) * scale;
  return phase < lineWidth;
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

class _EdgeAnalysis {
  const _EdgeAnalysis(this.strength, this.orientation);

  final Uint8List strength;
  final Uint8List orientation;
}

class _StructureAnalysis {
  const _StructureAnalysis(this.orientation, this.coherence);

  final Uint8List orientation;
  final Float32List coherence;
}

_StructureAnalysis _structureTensor(Uint8List gray, int width, int height) {
  final length = width * height;
  final jxx = Float32List(length);
  final jxy = Float32List(length);
  final jyy = Float32List(length);

  for (var y = 1; y < height - 1; y++) {
    final top = (y - 1) * width;
    final middle = y * width;
    final bottom = (y + 1) * width;
    for (var x = 1; x < width - 1; x++) {
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
      final index = middle + x;
      jxx[index] = gx * gx.toDouble();
      jxy[index] = gx * gy.toDouble();
      jyy[index] = gy * gy.toDouble();
    }
  }

  final smoothXX = _boxBlurFloat(jxx, width, height, 2);
  final smoothXY = _boxBlurFloat(jxy, width, height, 2);
  final smoothYY = _boxBlurFloat(jyy, width, height, 2);
  final orientation = Uint8List(length);
  final coherence = Float32List(length);
  for (var i = 0; i < length; i++) {
    final xx = smoothXX[i];
    final xy = smoothXY[i];
    final yy = smoothYY[i];
    final anisotropy = math.sqrt((xx - yy) * (xx - yy) + 4 * xy * xy);
    coherence[i] = (anisotropy / (xx + yy + 1)).clamp(0, 1);
    final gradientAngle = 0.5 * math.atan2(2 * xy, xx - yy);
    final tangentAngle = gradientAngle + math.pi / 2;
    final bin = (tangentAngle % (2 * math.pi)) / (math.pi / 4);
    orientation[i] = bin.round() & 7;
  }
  return _StructureAnalysis(orientation, coherence);
}

Float32List _boxBlurFloat(
  Float32List input,
  int width,
  int height,
  int radius,
) {
  if (radius <= 0 || width < 2 || height < 2) {
    return Float32List.fromList(input);
  }
  final horizontal = Float32List(input.length);
  final output = Float32List(input.length);
  final diameter = radius * 2 + 1;
  for (var y = 0; y < height; y++) {
    final row = y * width;
    var sum = 0.0;
    for (var dx = -radius; dx <= radius; dx++) {
      sum += input[row + dx.clamp(0, width - 1)];
    }
    for (var x = 0; x < width; x++) {
      horizontal[row + x] = sum / diameter;
      final removeX = (x - radius).clamp(0, width - 1);
      final addX = (x + radius + 1).clamp(0, width - 1);
      sum += input[row + addX] - input[row + removeX];
    }
  }
  for (var x = 0; x < width; x++) {
    var sum = 0.0;
    for (var dy = -radius; dy <= radius; dy++) {
      sum += horizontal[dy.clamp(0, height - 1) * width + x];
    }
    for (var y = 0; y < height; y++) {
      output[y * width + x] = sum / diameter;
      final removeY = (y - radius).clamp(0, height - 1);
      final addY = (y + radius + 1).clamp(0, height - 1);
      sum += horizontal[addY * width + x] - horizontal[removeY * width + x];
    }
  }
  return output;
}

_EdgeAnalysis _sobelAnalysis(
  Uint8List gray,
  int width,
  int height,
  double sensitivity, {
  required bool calculateOrientation,
}) {
  final edges = Uint8List(width * height);
  final orientation = Uint8List(width * height);
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
      final magnitude = math.sqrt(gx * gx + gy * gy);
      final threshold = 130 * (1 - sensitivity) + 12;
      edges[middle + x] = ((magnitude - threshold) * (0.8 + sensitivity * 0.8))
          .round()
          .clamp(0, 255);
      if (calculateOrientation) {
        final tangentAngle = math.atan2(gy, gx) + math.pi / 2;
        final normalizedAngle = (tangentAngle % (2 * math.pi)) / (math.pi / 4);
        orientation[middle + x] = normalizedAngle.round() & 7;
      }
    }
  }
  return _EdgeAnalysis(edges, orientation);
}

bool _isDirectionalHatch(int x, int y, int orientation, SketchOptions options) {
  const normalX = [0.0, -0.707, -1.0, -0.707, 0.0, 0.707, 1.0, 0.707];
  const normalY = [1.0, 0.707, 0.0, -0.707, -1.0, -0.707, 0.0, 0.707];
  final step = (16 - options.strokeDensity * 10).round().clamp(5, 16);
  final projected = (x * normalX[orientation] + y * normalY[orientation])
      .round()
      .abs();
  return projected % step == 0;
}
