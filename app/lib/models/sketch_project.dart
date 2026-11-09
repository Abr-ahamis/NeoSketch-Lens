import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum SketchStyle { pencil, outline, charcoal, crosshatch, soft }

enum SketchLevel { basic, advanced, professional }

@immutable
class SketchOptions {
  const SketchOptions({
    this.style = SketchStyle.pencil,
    this.level = SketchLevel.advanced,
    this.blurRadius = 10,
    this.contrast = 1.15,
    this.brightness = 0,
    this.edgeStrength = 0.35,
    this.intensity = 0.95,
    this.darkness = 0.82,
    this.pencilDarkness = 0.72,
    this.highlights = 0.65,
    this.shadows = 0.85,
    this.detailStrength = 0.8,
    this.smoothness = 0.25,
    this.sketchOpacity = 1,
    this.edgeSensitivity = 0.55,
    this.strokeDensity = 0.58,
    this.graphiteGrain = 0.08,
    this.crosshatchStrength = 0.55,
    this.facialVolume = 0.62,
    this.skinTonalVariation = 0.58,
    this.contourSoftness = 0.28,
    this.skinHatching = 0.22,
    this.invert = false,
  });

  final SketchStyle style;
  final SketchLevel level;
  final int blurRadius;
  final double contrast;
  final double brightness;
  final double edgeStrength;
  final double intensity;
  final double darkness;
  final double pencilDarkness;
  final double highlights;
  final double shadows;
  final double detailStrength;
  final double smoothness;
  final double sketchOpacity;
  final double edgeSensitivity;
  final double strokeDensity;
  final double graphiteGrain;
  final double crosshatchStrength;
  final double facialVolume;
  final double skinTonalVariation;
  final double contourSoftness;
  final double skinHatching;
  final bool invert;

  SketchOptions copyWith({
    SketchStyle? style,
    SketchLevel? level,
    int? blurRadius,
    double? contrast,
    double? brightness,
    double? edgeStrength,
    double? intensity,
    double? darkness,
    double? pencilDarkness,
    double? highlights,
    double? shadows,
    double? detailStrength,
    double? smoothness,
    double? sketchOpacity,
    double? edgeSensitivity,
    double? strokeDensity,
    double? graphiteGrain,
    double? crosshatchStrength,
    double? facialVolume,
    double? skinTonalVariation,
    double? contourSoftness,
    double? skinHatching,
    bool? invert,
  }) => SketchOptions(
    style: style ?? this.style,
    level: level ?? this.level,
    blurRadius: blurRadius ?? this.blurRadius,
    contrast: contrast ?? this.contrast,
    brightness: brightness ?? this.brightness,
    edgeStrength: edgeStrength ?? this.edgeStrength,
    intensity: intensity ?? this.intensity,
    darkness: darkness ?? this.darkness,
    pencilDarkness: pencilDarkness ?? this.pencilDarkness,
    highlights: highlights ?? this.highlights,
    shadows: shadows ?? this.shadows,
    detailStrength: detailStrength ?? this.detailStrength,
    smoothness: smoothness ?? this.smoothness,
    sketchOpacity: sketchOpacity ?? this.sketchOpacity,
    edgeSensitivity: edgeSensitivity ?? this.edgeSensitivity,
    strokeDensity: strokeDensity ?? this.strokeDensity,
    graphiteGrain: graphiteGrain ?? this.graphiteGrain,
    crosshatchStrength: crosshatchStrength ?? this.crosshatchStrength,
    facialVolume: facialVolume ?? this.facialVolume,
    skinTonalVariation: skinTonalVariation ?? this.skinTonalVariation,
    contourSoftness: contourSoftness ?? this.contourSoftness,
    skinHatching: skinHatching ?? this.skinHatching,
    invert: invert ?? this.invert,
  );

  Map<String, Object?> toJson() => {
    'style': style.name,
    'level': level.name,
    'blurRadius': blurRadius,
    'contrast': contrast,
    'brightness': brightness,
    'edgeStrength': edgeStrength,
    'intensity': intensity,
    'darkness': darkness,
    'pencilDarkness': pencilDarkness,
    'highlights': highlights,
    'shadows': shadows,
    'detailStrength': detailStrength,
    'smoothness': smoothness,
    'sketchOpacity': sketchOpacity,
    'edgeSensitivity': edgeSensitivity,
    'strokeDensity': strokeDensity,
    'graphiteGrain': graphiteGrain,
    'crosshatchStrength': crosshatchStrength,
    'facialVolume': facialVolume,
    'skinTonalVariation': skinTonalVariation,
    'contourSoftness': contourSoftness,
    'skinHatching': skinHatching,
    'invert': invert,
  };

  factory SketchOptions.fromJson(Map<String, Object?> json) => SketchOptions(
    style: SketchStyle.values.firstWhere(
      (value) => value.name == json['style'],
      orElse: () => SketchStyle.pencil,
    ),
    level: SketchLevel.values.firstWhere(
      (value) => value.name == json['level'],
      orElse: () => SketchLevel.advanced,
    ),
    blurRadius: (json['blurRadius'] as num?)?.round() ?? 10,
    contrast: (json['contrast'] as num?)?.toDouble() ?? 1.15,
    brightness: (json['brightness'] as num?)?.toDouble() ?? 0,
    edgeStrength: (json['edgeStrength'] as num?)?.toDouble() ?? 0.35,
    intensity: (json['intensity'] as num?)?.toDouble() ?? 0.95,
    darkness: (json['darkness'] as num?)?.toDouble() ?? 0.82,
    pencilDarkness: (json['pencilDarkness'] as num?)?.toDouble() ?? 0.72,
    highlights: (json['highlights'] as num?)?.toDouble() ?? 0.65,
    shadows: (json['shadows'] as num?)?.toDouble() ?? 0.85,
    detailStrength: (json['detailStrength'] as num?)?.toDouble() ?? 0.8,
    smoothness: (json['smoothness'] as num?)?.toDouble() ?? 0.25,
    sketchOpacity: (json['sketchOpacity'] as num?)?.toDouble() ?? 1,
    edgeSensitivity: (json['edgeSensitivity'] as num?)?.toDouble() ?? 0.55,
    strokeDensity: (json['strokeDensity'] as num?)?.toDouble() ?? 0.58,
    graphiteGrain: (json['graphiteGrain'] as num?)?.toDouble() ?? 0.08,
    crosshatchStrength:
        (json['crosshatchStrength'] as num?)?.toDouble() ?? 0.55,
    facialVolume: (json['facialVolume'] as num?)?.toDouble() ?? 0.62,
    skinTonalVariation:
        (json['skinTonalVariation'] as num?)?.toDouble() ?? 0.58,
    contourSoftness: (json['contourSoftness'] as num?)?.toDouble() ?? 0.28,
    skinHatching: (json['skinHatching'] as num?)?.toDouble() ?? 0.22,
    invert: json['invert'] as bool? ?? false,
  );
}

@immutable
class PaperSpec {
  const PaperSpec({
    this.preset = 'A4',
    this.customWidthMm = 210,
    this.customHeightMm = 297,
    this.landscape = false,
  });

  final String preset;
  final int customWidthMm;
  final int customHeightMm;
  final bool landscape;

  static const Map<String, Size> presets = {
    'A5': Size(148, 210),
    'A4': Size(210, 297),
    'A3': Size(297, 420),
    'Letter': Size(216, 279),
    'Legal': Size(216, 356),
    'Square': Size(210, 210),
  };

  int get widthMm {
    final size = preset == 'Custom'
        ? Size(customWidthMm.toDouble(), customHeightMm.toDouble())
        : presets[preset] ?? presets['A4']!;
    return (landscape ? size.height : size.width).round();
  }

  int get heightMm {
    final size = preset == 'Custom'
        ? Size(customWidthMm.toDouble(), customHeightMm.toDouble())
        : presets[preset] ?? presets['A4']!;
    return (landscape ? size.width : size.height).round();
  }

  PaperSpec copyWith({
    String? preset,
    int? customWidthMm,
    int? customHeightMm,
    bool? landscape,
  }) => PaperSpec(
    preset: preset ?? this.preset,
    customWidthMm: customWidthMm ?? this.customWidthMm,
    customHeightMm: customHeightMm ?? this.customHeightMm,
    landscape: landscape ?? this.landscape,
  );

  Map<String, Object?> toJson() => {
    'preset': preset,
    'customWidthMm': customWidthMm,
    'customHeightMm': customHeightMm,
    'landscape': landscape,
  };

  factory PaperSpec.fromJson(Map<String, Object?> json) => PaperSpec(
    preset: json['preset'] as String? ?? 'A4',
    customWidthMm: (json['customWidthMm'] as num?)?.round() ?? 210,
    customHeightMm: (json['customHeightMm'] as num?)?.round() ?? 297,
    landscape: json['landscape'] as bool? ?? false,
  );
}

@immutable
class SketchProject {
  const SketchProject({
    required this.id,
    required this.title,
    required this.originalBytes,
    required this.sketchBytes,
    required this.options,
    required this.paper,
    required this.corners,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final Uint8List originalBytes;
  final Uint8List sketchBytes;
  final SketchOptions options;
  final PaperSpec paper;
  final List<Offset> corners;
  final DateTime createdAt;
  final DateTime updatedAt;

  SketchProject copyWith({
    String? title,
    Uint8List? sketchBytes,
    SketchOptions? options,
    PaperSpec? paper,
    List<Offset>? corners,
    DateTime? updatedAt,
  }) => SketchProject(
    id: id,
    title: title ?? this.title,
    originalBytes: originalBytes,
    sketchBytes: sketchBytes ?? this.sketchBytes,
    options: options ?? this.options,
    paper: paper ?? this.paper,
    corners: corners ?? this.corners,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );
}
