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
  Timer? _debounce;
  var _generation = 0;
  var _renderInProgress = false;
  SketchOptions? _pendingOptions;
  var _processing = false;
  var _saving = false;
  var _showOriginal = false;
  _EditorTool _selectedTool = _EditorTool.shading;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    clearSketchPreviewCache(_project.originalBytes);
    super.dispose();
  }

  void _updateOptions(SketchOptions options) {
    _generation++;
    setState(() {
      _project = _project.copyWith(options: options);
      _processing = true;
    });
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 130),
      () => _render(options),
    );
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
        _message('Could not process this photo. Try a smaller image.');
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
        _message('Could not save this image. Try a smaller photo.');
      }
    }
  }

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
        title: const Text('Sketch editor'),
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _activeAdjustment(options),
                    SizedBox(
                      height: 76,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _EditorTool.values.map((tool) {
                          final selected = tool == _selectedTool;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ChoiceChip(
                              selected: selected,
                              avatar: Icon(tool.icon, size: 19),
                              label: Text(tool.label),
                              onSelected: (_) =>
                                  setState(() => _selectedTool = tool),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(
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
                        icon: const Icon(Icons.crop_free),
                        label: const Text('Continue to camera setup'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preview is processed locally on this device.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeAdjustment(SketchOptions options) {
    switch (_selectedTool) {
      case _EditorTool.shading:
        return _SliderSetting(
          title: 'Shading',
          valueLabel: '${options.blurRadius}',
          value: options.blurRadius.toDouble(),
          min: 0,
          max: 24,
          divisions: 24,
          onChanged: (v) =>
              _updateOptions(options.copyWith(blurRadius: v.round())),
        );
      case _EditorTool.contrast:
        return _SliderSetting(
          title: 'Contrast',
          valueLabel: options.contrast.toStringAsFixed(2),
          value: options.contrast,
          min: 0.6,
          max: 1.8,
          divisions: 24,
          onChanged: (v) => _updateOptions(options.copyWith(contrast: v)),
        );
      case _EditorTool.edges:
        return _SliderSetting(
          title: 'Edges',
          valueLabel: '${(options.edgeStrength * 100).round()}%',
          value: options.edgeStrength,
          min: 0,
          max: 0.7,
          divisions: 14,
          onChanged: (v) => _updateOptions(options.copyWith(edgeStrength: v)),
        );
      case _EditorTool.brightness:
        return _SliderSetting(
          title: 'Brightness',
          valueLabel: options.brightness.round().toString(),
          value: options.brightness,
          min: -50,
          max: 50,
          divisions: 20,
          onChanged: (v) => _updateOptions(options.copyWith(brightness: v)),
        );
      case _EditorTool.style:
        return SizedBox(
          height: 58,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: SketchStyle.values
                .map(
                  (style) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: options.style == style,
                      label: Text(_styleLabel(style)),
                      onSelected: (_) =>
                          _updateOptions(options.copyWith(style: style)),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      case _EditorTool.invert:
        return SizedBox(
          height: 58,
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('White lines on dark paper'),
            value: options.invert,
            onChanged: (value) =>
                _updateOptions(options.copyWith(invert: value)),
          ),
        );
    }
  }
}

enum _EditorTool {
  shading('Shading', Icons.blur_on),
  contrast('Contrast', Icons.tonality),
  edges('Edges', Icons.grain),
  brightness('Brightness', Icons.brightness_6_outlined),
  style('Style', Icons.palette_outlined),
  invert('Invert', Icons.invert_colors);

  const _EditorTool(this.label, this.icon);
  final String label;
  final IconData icon;
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
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: const Color(0xFFEAE7DF)),
                Padding(
                  padding: const EdgeInsets.all(14),
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
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
          onSelectionChanged: (selection) => onPreviewChanged(selection.first),
        ),
      ],
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
