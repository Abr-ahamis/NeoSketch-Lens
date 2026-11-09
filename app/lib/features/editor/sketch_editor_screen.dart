import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/project_repository.dart';
import '../../models/sketch_project.dart';
import '../../processing/sketch_processor.dart';
import '../paper/paper_setup_screen.dart';

class SketchEditorScreen extends ConsumerStatefulWidget {
  const SketchEditorScreen({required this.project, super.key});

  final SketchProject project;

  @override
  ConsumerState<SketchEditorScreen> createState() => _SketchEditorScreenState();
}

class _SketchEditorScreenState extends ConsumerState<SketchEditorScreen> {
  late SketchProject _project;
  var _generation = 0;
  var _renderInProgress = false;
  SketchOptions? _pendingOptions;
  var _processing = false;
  var _saving = false;
  var _showOriginal = false;
  _AdjustmentMode _mode = _AdjustmentMode.advanced;
  _AdjustmentGroup _group = _AdjustmentGroup.tone;
  String _selectedAdjustment = 'Sketch intensity';

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _mode = _AdjustmentMode.fromLevel(_project.options.level);
  }

  @override
  void dispose() {
    clearSketchPreviewCache(_project.originalBytes);
    super.dispose();
  }

  void _updateOptions(SketchOptions options) {
    _generation++;
    setState(() {
      _project = _project.copyWith(options: options);
      _processing = true;
    });
    // Slider onChanged fires continuously. Start the newest render immediately;
    // _render coalesces later values while a worker is still running.
    unawaited(_render(options));
  }

  Future<void> _render(SketchOptions options) async {
    _pendingOptions = options;
    if (_renderInProgress) return;

    _renderInProgress = true;
    var activeGeneration = _generation;
    try {
      while (mounted && _pendingOptions != null) {
        final nextOptions = _pendingOptions!;
        _pendingOptions = null;
        activeGeneration = _generation;
        final image = await processSketch(_project.originalBytes, nextOptions);
        if (!mounted) return;
        if (activeGeneration == _generation) {
          setState(() {
            _project = _project.copyWith(
              sketchBytes: image,
              options: nextOptions,
            );
            _processing = false;
          });
        }
      }
    } catch (error) {
      debugPrint('[SketchLens] Sketch preview failed (${error.runtimeType}).');
      if (mounted && activeGeneration == _generation) {
        setState(() => _processing = false);
        _message(_processingError(error));
      }
    } finally {
      _renderInProgress = false;
      if (mounted && _pendingOptions != null) {
        unawaited(_render(_pendingOptions!));
      }
    }
  }

  Future<void> _saveProject() async {
    final controller = TextEditingController(text: _project.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Project name'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save on device'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty || !mounted) return;

    setState(() => _saving = true);
    try {
      final fullResolutionSketch = await processSketch(
        _project.originalBytes,
        _project.options,
        maxDimension: 0,
      );
      final saved = _project.copyWith(
        title: title,
        sketchBytes: fullResolutionSketch,
      );
      await ref.read(projectRepositoryProvider).save(saved);
      if (!mounted) return;
      setState(() {
        _project = saved;
        _saving = false;
      });
      _message('Saved only on this device.');
    } catch (error) {
      debugPrint('[SketchLens] Project save failed (${error.runtimeType}).');
      if (mounted) {
        setState(() => _saving = false);
        _message(_processingError(error));
      }
    }
  }

  String _processingError(Object error) => error is FormatException
      ? error.message
      : 'Could not finish processing this image. Try a smaller photo.';

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final options = _project.options;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('Sketch editor'),
        titleTextStyle: Theme.of(context).textTheme.titleMedium,
        actions: [
          IconButton(
            tooltip: 'Save project on device',
            onPressed: _saving || _processing ? null : _saveProject,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                child: _PreviewPanel(
                  project: _project,
                  showOriginal: _showOriginal,
                  processing: _processing,
                  onPreviewChanged: (value) =>
                      setState(() => _showOriginal = value),
                ),
              ),
            ),
            Material(
              elevation: 8,
              color: colors.surface,
              child: SizedBox(
                height: 218,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 3, 10, 7),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 34,
                        child: Row(
                          children: _AdjustmentMode.values
                              .map((mode) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: ChoiceChip(
                                      visualDensity: VisualDensity.compact,
                                      label: Center(
                                        child: Text(
                                          mode.label,
                                          maxLines: 1,
                                          softWrap: false,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      selected: mode == _mode,
                                      onSelected: (_) => _selectMode(mode),
                                    ),
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                      ),
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _groupsForMode(_mode).map((group) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: ChoiceChip(
                                visualDensity: VisualDensity.compact,
                                selected: group == _group,
                                label: Text(group.label),
                                onSelected: (_) => _selectGroup(group),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (_group == _AdjustmentGroup.style)
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: SketchStyle.values.map((style) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  visualDensity: VisualDensity.compact,
                                  selected: options.style == style,
                                  label: Text(_styleLabel(style)),
                                  onSelected: (_) => _updateOptions(
                                    options.copyWith(style: style),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      else ...[
                        SizedBox(
                          height: 32,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ..._specs(options, _group).map((spec) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    visualDensity: VisualDensity.compact,
                                    selected: spec.label == _selectedAdjustment,
                                    label: Text(spec.label),
                                    onSelected: (_) => setState(
                                      () => _selectedAdjustment = spec.label,
                                    ),
                                  ),
                                );
                              }),
                              if (_group == _AdjustmentGroup.pencil)
                                FilterChip(
                                  visualDensity: VisualDensity.compact,
                                  selected: options.invert,
                                  label: const Text('Invert'),
                                  onSelected: (value) => _updateOptions(
                                    options.copyWith(invert: value),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 68, child: _activeSlider(options)),
                      ],
                      const Spacer(),
                      SizedBox(
                        height: 38,
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _processing || _saving
                              ? null
                              : () => Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        PaperSetupScreen(project: _project),
                                  ),
                                ),
                          icon: const Icon(Icons.crop_free, size: 18),
                          label: const Text('Continue to camera setup'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_AdjustmentSpec> _specs(SketchOptions options, _AdjustmentGroup group) {
    _AdjustmentSpec slider(
      String label,
      double value,
      double min,
      double max,
      void Function(double) update, {
      int divisions = 40,
      bool percent = true,
    }) => _AdjustmentSpec(
      label: label,
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      percent: percent,
      update: update,
    );

    if (group == _AdjustmentGroup.tone) {
      return [
        slider('Intensity', options.intensity, 0, 1, (v) {
          _updateOptions(options.copyWith(intensity: v));
        }),
        slider(
          'Brightness',
          options.brightness,
          -50,
          50,
          (v) {
            _updateOptions(options.copyWith(brightness: v));
          },
          divisions: 100,
          percent: false,
        ),
        slider(
          'Contrast',
          options.contrast,
          0.6,
          1.8,
          (v) {
            _updateOptions(options.copyWith(contrast: v));
          },
          divisions: 48,
          percent: false,
        ),
        slider('Darkness', options.darkness, 0, 1, (v) {
          _updateOptions(options.copyWith(darkness: v));
        }),
        slider('Highlights', options.highlights, 0, 1, (v) {
          _updateOptions(options.copyWith(highlights: v));
        }),
        slider('Shadows', options.shadows, 0, 1, (v) {
          _updateOptions(options.copyWith(shadows: v));
        }),
      ];
    }
    if (group == _AdjustmentGroup.details) {
      return [
        slider('Fine detail', options.detailStrength, 0, 1, (v) {
          _updateOptions(options.copyWith(detailStrength: v));
        }),
        slider('Smoothness', options.smoothness, 0, 1, (v) {
          _updateOptions(options.copyWith(smoothness: v));
        }),
        if (_mode != _AdjustmentMode.basic)
          slider('Edge strength', options.edgeStrength, 0, 1, (v) {
            _updateOptions(options.copyWith(edgeStrength: v));
          }),
        if (_mode != _AdjustmentMode.basic)
          slider('Edge sensitivity', options.edgeSensitivity, 0, 1, (v) {
            _updateOptions(options.copyWith(edgeSensitivity: v));
          }),
        if (_mode != _AdjustmentMode.basic)
          slider(
            'Shading scale',
            options.blurRadius.toDouble(),
            0,
            24,
            (v) {
              _updateOptions(options.copyWith(blurRadius: v.round()));
            },
            divisions: 24,
            percent: false,
          ),
      ];
    }
    if (group == _AdjustmentGroup.pencil) {
      return [
        slider('Pencil darkness', options.pencilDarkness, 0, 1, (v) {
          _updateOptions(options.copyWith(pencilDarkness: v));
        }),
        slider('Opacity', options.sketchOpacity, 0, 1, (v) {
          _updateOptions(options.copyWith(sketchOpacity: v));
        }),
        slider('Stroke density', options.strokeDensity, 0, 1, (v) {
          _updateOptions(options.copyWith(strokeDensity: v));
        }),
        slider('Cross-hatching', options.crosshatchStrength, 0, 1, (v) {
          _updateOptions(options.copyWith(crosshatchStrength: v));
        }),
      ];
    }
    if (group == _AdjustmentGroup.face) {
      return [
        slider('Facial volume', options.facialVolume, 0, 1, (v) {
          _updateOptions(options.copyWith(facialVolume: v));
        }),
        slider('Surface smoothness', options.smoothness, 0, 1, (v) {
          _updateOptions(options.copyWith(smoothness: v));
        }),
        slider('Skin tonal variation', options.skinTonalVariation, 0, 1, (v) {
          _updateOptions(options.copyWith(skinTonalVariation: v));
        }),
        slider('Shadow transition softness', options.smoothness, 0, 1, (v) {
          _updateOptions(options.copyWith(smoothness: v));
        }),
        slider('Highlight preservation', options.highlights, 0, 1, (v) {
          _updateOptions(options.copyWith(highlights: v));
        }),
        slider('Skin graphite', options.pencilDarkness, 0, 1, (v) {
          _updateOptions(options.copyWith(pencilDarkness: v));
        }),
        slider('Skin grain', options.graphiteGrain, 0, 0.5, (v) {
          _updateOptions(options.copyWith(graphiteGrain: v));
        }),
        slider('Skin hatching', options.skinHatching, 0, 1, (v) {
          _updateOptions(options.copyWith(skinHatching: v));
        }),
        slider('Contour softness', options.contourSoftness, 0, 1, (v) {
          _updateOptions(options.copyWith(contourSoftness: v));
        }),
        slider(
          'Local contrast',
          options.contrast,
          0.6,
          1.8,
          (v) {
            _updateOptions(options.copyWith(contrast: v));
          },
          divisions: 48,
          percent: false,
        ),
        slider('Surface detail', options.detailStrength, 0, 1, (v) {
          _updateOptions(options.copyWith(detailStrength: v));
        }),
      ];
    }
    if (group == _AdjustmentGroup.texture) {
      return [
        slider('Graphite grain', options.graphiteGrain, 0, 0.5, (v) {
          _updateOptions(options.copyWith(graphiteGrain: v));
        }),
      ];
    }
    return const [];
  }

  Widget _activeSlider(SketchOptions options) {
    final specs = _specs(options, _group);
    if (specs.isEmpty) {
      return SwitchListTile.adaptive(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: const Text('White graphite on dark paper'),
        value: options.invert,
        onChanged: (value) => _updateOptions(options.copyWith(invert: value)),
      );
    }
    final selected = specs.firstWhere(
      (spec) => spec.label == _selectedAdjustment,
      orElse: () => specs.first,
    );
    return _SliderSetting(
      title: selected.label,
      valueLabel: selected.percent
          ? '${(selected.value * 100).round()}%'
          : selected.value.toStringAsFixed(2),
      value: selected.value,
      min: selected.min,
      max: selected.max,
      divisions: selected.divisions,
      onChanged: selected.update,
    );
  }

  void _selectMode(_AdjustmentMode mode) {
    setState(() {
      _mode = mode;
      if (!_groupsForMode(mode).contains(_group)) {
        _group = _groupsForMode(mode).first;
      }
      final specs = _specs(_project.options, _group);
      _selectedAdjustment = specs.isEmpty ? '' : specs.first.label;
    });
    _updateOptions(_project.options.copyWith(level: mode.level));
  }

  void _selectGroup(_AdjustmentGroup group) {
    setState(() {
      _group = group;
      final specs = _specs(_project.options, group);
      _selectedAdjustment = specs.isEmpty ? '' : specs.first.label;
    });
  }

  List<_AdjustmentGroup> _groupsForMode(_AdjustmentMode mode) => switch (mode) {
    _AdjustmentMode.basic => [
      _AdjustmentGroup.tone,
      _AdjustmentGroup.details,
      _AdjustmentGroup.pencil,
      _AdjustmentGroup.style,
    ],
    _AdjustmentMode.advanced => [
      _AdjustmentGroup.tone,
      _AdjustmentGroup.details,
      _AdjustmentGroup.pencil,
      _AdjustmentGroup.face,
      _AdjustmentGroup.style,
    ],
    _AdjustmentMode.professional => _AdjustmentGroup.values,
  };
}

enum _AdjustmentMode {
  basic('L1 Basic'),
  advanced('L2 Advanced'),
  professional('L3 Pro');

  const _AdjustmentMode(this.label);
  final String label;

  SketchLevel get level => switch (this) {
    _AdjustmentMode.basic => SketchLevel.basic,
    _AdjustmentMode.advanced => SketchLevel.advanced,
    _AdjustmentMode.professional => SketchLevel.professional,
  };

  static _AdjustmentMode fromLevel(SketchLevel level) => switch (level) {
    SketchLevel.basic => _AdjustmentMode.basic,
    SketchLevel.advanced => _AdjustmentMode.advanced,
    SketchLevel.professional => _AdjustmentMode.professional,
  };
}

enum _AdjustmentGroup {
  tone('Tone'),
  details('Details'),
  pencil('Pencil'),
  face('Face'),
  texture('Texture'),
  style('Style');

  const _AdjustmentGroup(this.label);
  final String label;
}

class _AdjustmentSpec {
  const _AdjustmentSpec({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.percent,
    required this.update,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool percent;
  final ValueChanged<double> update;
}

String _styleLabel(SketchStyle style) => switch (style) {
  SketchStyle.pencil => 'Pencil',
  SketchStyle.outline => 'Outline',
  SketchStyle.charcoal => 'Charcoal',
  SketchStyle.crosshatch => 'Crosshatch',
  SketchStyle.soft => 'Soft pencil',
};

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.project,
    required this.showOriginal,
    required this.processing,
    required this.onPreviewChanged,
  });

  final SketchProject project;
  final bool showOriginal;
  final bool processing;
  final ValueChanged<bool> onPreviewChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFFEAE7DF)),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Image.memory(
              showOriginal ? project.originalBytes : project.sketchBytes,
              fit: BoxFit.contain,
              cacheWidth: 1024,
              cacheHeight: 1024,
              gaplessPlayback: true,
            ),
          ),
          if (processing)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Sketch'),
                    icon: Icon(Icons.draw_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Original'),
                    icon: Icon(Icons.image_outlined),
                  ),
                ],
                selected: {showOriginal},
                onSelectionChanged: (selection) =>
                    onPreviewChanged(selection.first),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            valueLabel,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    ],
  );
}
