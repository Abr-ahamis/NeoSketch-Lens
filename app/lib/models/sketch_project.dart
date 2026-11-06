import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum SketchStyle { pencil, outline, charcoal, crosshatch, soft }

@immutable
class SketchOptions {
  const SketchOptions({
    this.style = SketchStyle.pencil,
    this.blurRadius = 10,
    this.contrast = 1.15,
    this.brightness = 0,
    this.edgeStrength = 0.2,
    this.invert = false,
  });

  final SketchStyle style;
  final int blurRadius;
  final double contrast;
  final double brightness;
  final double edgeStrength;
  final bool invert;

  SketchOptions copyWith({
    SketchStyle? style,
    int? blurRadius,
    double? contrast,
    double? brightness,
    double? edgeStrength,
    bool? invert,
  }) =>
      SketchOptions(
        style: style ?? this.style,
        blurRadius: blurRadius ?? this.blurRadius,
        contrast: contrast ?? this.contrast,
        brightness: brightness ?? this.brightness,
        edgeStrength: edgeStrength ?? this.edgeStrength,
        invert: invert ?? this.invert,
      );

  Map<String, Object?> toJson() => {
        'style': style.name,
        'blurRadius': blurRadius,
        'contrast': contrast,
        'brightness': brightness,
        'edgeStrength': edgeStrength,
        'invert': invert,
      };

  factory SketchOptions.fromJson(Map<String, Object?> json) => SketchOptions(
        style: SketchStyle.values.firstWhere(
          (value) => value.name == json['style'],
          orElse: () => SketchStyle.pencil,
        ),
        blurRadius: (json['blurRadius'] as num?)?.round() ?? 10,
        contrast: (json['contrast'] as num?)?.toDouble() ?? 1.15,
        brightness: (json['brightness'] as num?)?.toDouble() ?? 0,
        edgeStrength: (json['edgeStrength'] as num?)?.toDouble() ?? 0.2,
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
  }) =>
      PaperSpec(
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
  }) =>
      SketchProject(
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
