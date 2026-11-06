import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../processing/sketch_processor.dart';

part 'app_database.g.dart';

class SketchProjectSummary {
  const SketchProjectSummary({
    required this.id,
    required this.title,
    required this.thumbnailBytes,
  });

  final String id;
  final String title;
  final Uint8List? thumbnailBytes;
}

@DataClassName('SketchProjectRow')
class SketchProjects extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BlobColumn get originalBytes => blob()();
  BlobColumn get sketchBytes => blob()();
  BlobColumn get thumbnailBytes => blob().nullable()();
  TextColumn get optionsJson => text()();
  TextColumn get paperJson => text()();
  TextColumn get cornersJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [SketchProjects])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'sketchlens'));

  var _thumbnailBackfillRunning = false;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(sketchProjects, sketchProjects.thumbnailBytes);
      }
    },
  );

  Stream<List<SketchProjectSummary>> watchProjectSummaries() {
    final query = selectOnly(sketchProjects)
      ..addColumns([
        sketchProjects.id,
        sketchProjects.title,
        sketchProjects.thumbnailBytes,
        sketchProjects.updatedAt,
      ])
      ..orderBy([OrderingTerm.desc(sketchProjects.updatedAt)]);
    return query.watch().map((rows) {
      if (!_thumbnailBackfillRunning &&
          rows.any((row) => row.read(sketchProjects.thumbnailBytes) == null)) {
        unawaited(_backfillMissingThumbnails());
      }
      return rows
          .map(
            (row) => SketchProjectSummary(
              id: row.read(sketchProjects.id)!,
              title: row.read(sketchProjects.title)!,
              thumbnailBytes: row.read(sketchProjects.thumbnailBytes),
            ),
          )
          .toList(growable: false);
    });
  }

  Future<void> _backfillMissingThumbnails() async {
    if (_thumbnailBackfillRunning) return;
    _thumbnailBackfillRunning = true;
    try {
      final ids =
          await (selectOnly(sketchProjects)
                ..addColumns([sketchProjects.id])
                ..where(sketchProjects.thumbnailBytes.isNull()))
              .map((row) => row.read(sketchProjects.id)!)
              .get();
      for (final id in ids) {
        final project = await getProject(id);
        if (project == null || project.thumbnailBytes != null) continue;
        final thumbnail = await createSketchThumbnail(project.sketchBytes);
        await (update(sketchProjects)..where((table) => table.id.equals(id)))
            .write(SketchProjectsCompanion(thumbnailBytes: Value(thumbnail)));
      }
    } catch (error) {
      debugPrint(
        '[SketchLens] Existing thumbnail rebuild failed (${error.runtimeType}).',
      );
      // Existing project cards remain usable even if a thumbnail cannot be rebuilt.
    } finally {
      _thumbnailBackfillRunning = false;
    }
  }

  Future<SketchProjectRow?> getProject(String id) => (select(
    sketchProjects,
  )..where((table) => table.id.equals(id))).getSingleOrNull();

  Future<void> saveProject(SketchProjectsCompanion project) =>
      into(sketchProjects).insertOnConflictUpdate(project);

  Future<void> deleteProject(String id) =>
      (delete(sketchProjects)..where((table) => table.id.equals(id))).go();
}
