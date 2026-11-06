import 'package:flutter/material.dart';

import '../../models/sketch_project.dart';
import '../camera/camera_overlay_screen.dart';

class PaperSetupScreen extends StatefulWidget {
  const PaperSetupScreen({required this.project, super.key});
  final SketchProject project;

  @override
  State<PaperSetupScreen> createState() => _PaperSetupScreenState();
}

class _PaperSetupScreenState extends State<PaperSetupScreen> {
  late PaperSpec _paper;
  late final TextEditingController _width;
  late final TextEditingController _height;

  @override
  void initState() {
    super.initState();
    _paper = widget.project.paper;
    _width = TextEditingController(text: '${_paper.customWidthMm}');
    _height = TextEditingController(text: '${_paper.customHeightMm}');
  }

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  void _setPreset(String? value) {
    if (value == null) return;
    setState(() => _paper = _paper.copyWith(preset: value));
  }

  void _continue() {
    final width = int.tryParse(_width.text);
    final height = int.tryParse(_height.text);
    if (_paper.preset == 'Custom' &&
        (width == null || height == null || width < 20 || height < 20 || width > 2000 || height > 2000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a paper width and height between 20 and 2000 mm.')),
      );
      return;
    }
    final selected = _paper.copyWith(
      customWidthMm: width ?? _paper.customWidthMm,
      customHeightMm: height ?? _paper.customHeightMm,
    );
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CameraOverlayScreen(project: widget.project.copyWith(paper: selected)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = PaperSpec.presets[_paper.preset] ?? const Size(210, 297);
    final aspect = _paper.preset == 'Custom'
        ? (int.tryParse(_width.text) ?? 210) / (int.tryParse(_height.text) ?? 297)
        : ( _paper.landscape ? size.height / size.width : size.width / size.height );

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your paper')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fit the sketch to the sheet you will draw on.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _paper.preset,
                decoration: const InputDecoration(labelText: 'Paper size'),
                items: [
                  ...PaperSpec.presets.keys.map((preset) => DropdownMenuItem(value: preset, child: Text(preset))),
                  const DropdownMenuItem(value: 'Custom', child: Text('Custom size')),
                ],
                onChanged: _setPreset,
              ),
              if (_paper.preset == 'Custom') ...[
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: TextField(controller: _width, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Width (mm)'), onChanged: (_) => setState(() {}))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _height, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (mm)'), onChanged: (_) => setState(() {}))),
                ]),
              ],
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Landscape orientation'),
                value: _paper.landscape,
                onChanged: (value) => setState(() => _paper = _paper.copyWith(landscape: value)),
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: aspect.clamp(0.25, 4),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 380, maxWidth: 300),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAE7DF),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 10))],
                      ),
                      child: Center(child: Text('${_paper.widthMm} × ${_paper.heightMm} mm', style: const TextStyle(color: Color(0xFF414141)))),
                    ),
                  ),
                ),
              ),
              const Text('The camera step lets you drag four corners around the real sheet.', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _continue, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Open camera alignment'))),
            ],
          ),
        ),
      ),
    );
  }
}
