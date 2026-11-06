import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/project_repository.dart';
import '../../data/app_database.dart';
import '../../models/sketch_project.dart';
import '../../processing/sketch_processor.dart';
import '../editor/sketch_editor_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _importing = false;

  Future<void> _importImage(ImageSource source) async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 100,
      );
      if (file == null) return;
      final original = await file.readAsBytes();
      final options = const SketchOptions();
      final sketch = await processSketch(original, options);
      if (!mounted) return;
      final title = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '').trim();
      final project = ref
          .read(projectRepositoryProvider)
          .newDraft(
            title: title.isEmpty ? 'New sketch' : title,
            originalBytes: original,
            sketchBytes: sketch,
            options: options,
          );
      await _openEditor(project);
    } catch (error) {
      if (error is PlatformException) {
        debugPrint('[SketchLens] Image import failed (${error.code}).');
      } else {
        debugPrint('[SketchLens] Image import failed (${error.runtimeType}).');
      }
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _openSavedProject(String id) async {
    try {
      final repository = ref.read(projectRepositoryProvider);
      final row = await repository.get(id);
      if (row == null) {
        if (mounted) _showMessage('This saved project is no longer available.');
        return;
      }
      final project = repository.decode(row);
      await _openEditor(project);
    } catch (error) {
      debugPrint(
        '[SketchLens] Saved project open failed (${error.runtimeType}).',
      );
      if (mounted) _showMessage('This saved project could not be opened.');
    }
  }

  Future<void> _openEditor(SketchProject project) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SketchEditorScreen(project: project),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('denied') || text.contains('permission')) {
      return 'Camera or photo access was denied. You can allow it in Android settings.';
    }
    return 'Could not open that image. Try a JPEG or PNG photo.';
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SketchLens',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'About offline processing',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'SketchLens',
              applicationVersion: '1.0.0',
              applicationLegalese:
                  'Images are processed and saved only on this device.',
              children: const [
                Text(
                  'Sketch conversion uses traditional pixel filters. No AI or network connection is used.',
                ),
              ],
            ),
            icon: const Icon(Icons.info_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              sliver: SliverToBoxAdapter(
                child: _ImportCard(
                  busy: _importing,
                  onGallery: () => _importImage(ImageSource.gallery),
                  onCamera: () => _importImage(ImageSource.camera),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'My projects',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    projects.when(
                      data: (items) => Text(
                        '${items.length}',
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            projects.when(
              data: (items) => items.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyProjects(),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverGrid.builder(
                        itemCount: items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                        itemBuilder: (context, index) => _ProjectCard(
                          project: items[index],
                          onTap: () => _openSavedProject(items[index].id),
                          onDelete: () async {
                            await ref
                                .read(projectRepositoryProvider)
                                .delete(items[index].id);
                          },
                        ),
                      ),
                    ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Could not load projects: $error')),
              ),
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  const _ImportCard({
    required this.busy,
    required this.onGallery,
    required this.onCamera,
  });

  final bool busy;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF292722), Color(0xFF1A1C20)],
        ),
        border: Border.all(color: colors.outline.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.draw_outlined, color: colors.primary, size: 26),
          ),
          const SizedBox(height: 16),
          const Text(
            'Turn a photo into a drawing guide',
            style: TextStyle(
              fontSize: 21,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose an image, adjust its pencil look, then line it up with your paper.',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.66),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          if (busy) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Making a local sketch preview…',
              style: TextStyle(color: colors.primary),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose a photo'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take a photo'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.lock_outline, size: 15, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                'Offline · No AI · Your images stay on this phone',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 36,
            color: colors.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          Text(
            'Your saved sketches will appear here',
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onTap,
    required this.onDelete,
  });

  final SketchProjectSummary project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: const Color(0xFFEBE8E0),
                padding: const EdgeInsets.all(10),
                child: project.thumbnailBytes == null
                    ? const Center(
                        child: Icon(
                          Icons.draw_outlined,
                          color: Color(0xFF807C74),
                        ),
                      )
                    : Image.memory(
                        project.thumbnailBytes!,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete project'),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert, size: 19),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
