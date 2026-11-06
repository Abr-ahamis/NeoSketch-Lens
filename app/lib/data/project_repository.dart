import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/sketch_project.dart';
import '../processing/sketch_processor.dart';
import 'app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(ref.watch(databaseProvider)),
);

final projectsProvider = StreamProvider<List<SketchProjectSummary>>(
  (ref) => ref.watch(databaseProvider).watchProjectSummaries(),
);

class ProjectRepository {
  ProjectRepository(this._database);

  final AppDatabase _database;
  static final _uuid = Uuid();

  SketchProject newDraft({
    required String title,
    required Uint8List originalBytes,
    required Uint8List sketchBytes,
    SketchOptions options = const SketchOptions(),
  }) {
    final now = DateTime.now();
    return SketchProject(
      id: _uuid.v4(),
      title: title,
      originalBytes: originalBytes,
      sketchBytes: sketchBytes,
      options: options,
      paper: const PaperSpec(),
      corners: const [
        Offset(0.14, 0.16),
        Offset(0.86, 0.16),
        Offset(0.86, 0.68),
        Offset(0.14, 0.68),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> save(SketchProject project) async {
    final thumbnail = await createSketchThumbnail(project.sketchBytes);
    await _database.saveProject(
      SketchProjectsCompanion.insert(
        id: project.id,
        title: project.title,
        originalBytes: project.originalBytes,
        sketchBytes: project.sketchBytes,
        thumbnailBytes: Value(thumbnail),
        optionsJson: jsonEncode(project.options.toJson()),
        paperJson: jsonEncode(project.paper.toJson()),
        cornersJson: jsonEncode(
          project.corners.map((point) => [point.dx, point.dy]).toList(),
        ),
        createdAt: project.createdAt,
        updatedAt: project.updatedAt,
      ),
    );
  }

  Future<void> delete(String id) => _database.deleteProject(id);

  Future<SketchProjectRow?> get(String id) => _database.getProject(id);

  SketchProject decode(SketchProjectRow row) {
    final optionsJson = Map<String, Object?>.from(
      jsonDecode(row.optionsJson) as Map,
    );
    final paperJson = Map<String, Object?>.from(
      jsonDecode(row.paperJson) as Map,
    );
    final cornersJson = jsonDecode(row.cornersJson) as List<Object?>;
    final corners = cornersJson
        .map((value) {
          final point = value as List<Object?>;
          return Offset(
            (point[0] as num).toDouble(),
            (point[1] as num).toDouble(),
          );
        })
        .toList(growable: false);

    return SketchProject(
      id: row.id,
      title: row.title,
      originalBytes: row.originalBytes,
      sketchBytes: row.sketchBytes,
      options: SketchOptions.fromJson(optionsJson),
      paper: PaperSpec.fromJson(paperJson),
      corners: corners,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
