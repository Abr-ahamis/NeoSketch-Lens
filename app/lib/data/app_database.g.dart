// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SketchProjectsTable extends SketchProjects
    with TableInfo<$SketchProjectsTable, SketchProjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SketchProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalBytesMeta = const VerificationMeta(
    'originalBytes',
  );
  @override
  late final GeneratedColumn<Uint8List> originalBytes =
      GeneratedColumn<Uint8List>(
        'original_bytes',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sketchBytesMeta = const VerificationMeta(
    'sketchBytes',
  );
  @override
  late final GeneratedColumn<Uint8List> sketchBytes =
      GeneratedColumn<Uint8List>(
        'sketch_bytes',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _thumbnailBytesMeta = const VerificationMeta(
    'thumbnailBytes',
  );
  @override
  late final GeneratedColumn<Uint8List> thumbnailBytes =
      GeneratedColumn<Uint8List>(
        'thumbnail_bytes',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paperJsonMeta = const VerificationMeta(
    'paperJson',
  );
  @override
  late final GeneratedColumn<String> paperJson = GeneratedColumn<String>(
    'paper_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cornersJsonMeta = const VerificationMeta(
    'cornersJson',
  );
  @override
  late final GeneratedColumn<String> cornersJson = GeneratedColumn<String>(
    'corners_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    originalBytes,
    sketchBytes,
    thumbnailBytes,
    optionsJson,
    paperJson,
    cornersJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sketch_projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<SketchProjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_bytes')) {
      context.handle(
        _originalBytesMeta,
        originalBytes.isAcceptableOrUnknown(
          data['original_bytes']!,
          _originalBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalBytesMeta);
    }
    if (data.containsKey('sketch_bytes')) {
      context.handle(
        _sketchBytesMeta,
        sketchBytes.isAcceptableOrUnknown(
          data['sketch_bytes']!,
          _sketchBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sketchBytesMeta);
    }
    if (data.containsKey('thumbnail_bytes')) {
      context.handle(
        _thumbnailBytesMeta,
        thumbnailBytes.isAcceptableOrUnknown(
          data['thumbnail_bytes']!,
          _thumbnailBytesMeta,
        ),
      );
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_optionsJsonMeta);
    }
    if (data.containsKey('paper_json')) {
      context.handle(
        _paperJsonMeta,
        paperJson.isAcceptableOrUnknown(data['paper_json']!, _paperJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_paperJsonMeta);
    }
    if (data.containsKey('corners_json')) {
      context.handle(
        _cornersJsonMeta,
        cornersJson.isAcceptableOrUnknown(
          data['corners_json']!,
          _cornersJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cornersJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SketchProjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SketchProjectRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      originalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}original_bytes'],
      )!,
      sketchBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}sketch_bytes'],
      )!,
      thumbnailBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}thumbnail_bytes'],
      ),
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
      paperJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paper_json'],
      )!,
      cornersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corners_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SketchProjectsTable createAlias(String alias) {
    return $SketchProjectsTable(attachedDatabase, alias);
  }
}

class SketchProjectRow extends DataClass
    implements Insertable<SketchProjectRow> {
  final String id;
  final String title;
  final Uint8List originalBytes;
  final Uint8List sketchBytes;
  final Uint8List? thumbnailBytes;
  final String optionsJson;
  final String paperJson;
  final String cornersJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SketchProjectRow({
    required this.id,
    required this.title,
    required this.originalBytes,
    required this.sketchBytes,
    this.thumbnailBytes,
    required this.optionsJson,
    required this.paperJson,
    required this.cornersJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['original_bytes'] = Variable<Uint8List>(originalBytes);
    map['sketch_bytes'] = Variable<Uint8List>(sketchBytes);
    if (!nullToAbsent || thumbnailBytes != null) {
      map['thumbnail_bytes'] = Variable<Uint8List>(thumbnailBytes);
    }
    map['options_json'] = Variable<String>(optionsJson);
    map['paper_json'] = Variable<String>(paperJson);
    map['corners_json'] = Variable<String>(cornersJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SketchProjectsCompanion toCompanion(bool nullToAbsent) {
    return SketchProjectsCompanion(
      id: Value(id),
      title: Value(title),
      originalBytes: Value(originalBytes),
      sketchBytes: Value(sketchBytes),
      thumbnailBytes: thumbnailBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailBytes),
      optionsJson: Value(optionsJson),
      paperJson: Value(paperJson),
      cornersJson: Value(cornersJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SketchProjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SketchProjectRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      originalBytes: serializer.fromJson<Uint8List>(json['originalBytes']),
      sketchBytes: serializer.fromJson<Uint8List>(json['sketchBytes']),
      thumbnailBytes: serializer.fromJson<Uint8List?>(json['thumbnailBytes']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
      paperJson: serializer.fromJson<String>(json['paperJson']),
      cornersJson: serializer.fromJson<String>(json['cornersJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'originalBytes': serializer.toJson<Uint8List>(originalBytes),
      'sketchBytes': serializer.toJson<Uint8List>(sketchBytes),
      'thumbnailBytes': serializer.toJson<Uint8List?>(thumbnailBytes),
      'optionsJson': serializer.toJson<String>(optionsJson),
      'paperJson': serializer.toJson<String>(paperJson),
      'cornersJson': serializer.toJson<String>(cornersJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SketchProjectRow copyWith({
    String? id,
    String? title,
    Uint8List? originalBytes,
    Uint8List? sketchBytes,
    Value<Uint8List?> thumbnailBytes = const Value.absent(),
    String? optionsJson,
    String? paperJson,
    String? cornersJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SketchProjectRow(
    id: id ?? this.id,
    title: title ?? this.title,
    originalBytes: originalBytes ?? this.originalBytes,
    sketchBytes: sketchBytes ?? this.sketchBytes,
    thumbnailBytes: thumbnailBytes.present
        ? thumbnailBytes.value
        : this.thumbnailBytes,
    optionsJson: optionsJson ?? this.optionsJson,
    paperJson: paperJson ?? this.paperJson,
    cornersJson: cornersJson ?? this.cornersJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SketchProjectRow copyWithCompanion(SketchProjectsCompanion data) {
    return SketchProjectRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      originalBytes: data.originalBytes.present
          ? data.originalBytes.value
          : this.originalBytes,
      sketchBytes: data.sketchBytes.present
          ? data.sketchBytes.value
          : this.sketchBytes,
      thumbnailBytes: data.thumbnailBytes.present
          ? data.thumbnailBytes.value
          : this.thumbnailBytes,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      paperJson: data.paperJson.present ? data.paperJson.value : this.paperJson,
      cornersJson: data.cornersJson.present
          ? data.cornersJson.value
          : this.cornersJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SketchProjectRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('originalBytes: $originalBytes, ')
          ..write('sketchBytes: $sketchBytes, ')
          ..write('thumbnailBytes: $thumbnailBytes, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('paperJson: $paperJson, ')
          ..write('cornersJson: $cornersJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    $driftBlobEquality.hash(originalBytes),
    $driftBlobEquality.hash(sketchBytes),
    $driftBlobEquality.hash(thumbnailBytes),
    optionsJson,
    paperJson,
    cornersJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SketchProjectRow &&
          other.id == this.id &&
          other.title == this.title &&
          $driftBlobEquality.equals(other.originalBytes, this.originalBytes) &&
          $driftBlobEquality.equals(other.sketchBytes, this.sketchBytes) &&
          $driftBlobEquality.equals(
            other.thumbnailBytes,
            this.thumbnailBytes,
          ) &&
          other.optionsJson == this.optionsJson &&
          other.paperJson == this.paperJson &&
          other.cornersJson == this.cornersJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SketchProjectsCompanion extends UpdateCompanion<SketchProjectRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<Uint8List> originalBytes;
  final Value<Uint8List> sketchBytes;
  final Value<Uint8List?> thumbnailBytes;
  final Value<String> optionsJson;
  final Value<String> paperJson;
  final Value<String> cornersJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SketchProjectsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.originalBytes = const Value.absent(),
    this.sketchBytes = const Value.absent(),
    this.thumbnailBytes = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.paperJson = const Value.absent(),
    this.cornersJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SketchProjectsCompanion.insert({
    required String id,
    required String title,
    required Uint8List originalBytes,
    required Uint8List sketchBytes,
    this.thumbnailBytes = const Value.absent(),
    required String optionsJson,
    required String paperJson,
    required String cornersJson,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       originalBytes = Value(originalBytes),
       sketchBytes = Value(sketchBytes),
       optionsJson = Value(optionsJson),
       paperJson = Value(paperJson),
       cornersJson = Value(cornersJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SketchProjectRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<Uint8List>? originalBytes,
    Expression<Uint8List>? sketchBytes,
    Expression<Uint8List>? thumbnailBytes,
    Expression<String>? optionsJson,
    Expression<String>? paperJson,
    Expression<String>? cornersJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (originalBytes != null) 'original_bytes': originalBytes,
      if (sketchBytes != null) 'sketch_bytes': sketchBytes,
      if (thumbnailBytes != null) 'thumbnail_bytes': thumbnailBytes,
      if (optionsJson != null) 'options_json': optionsJson,
      if (paperJson != null) 'paper_json': paperJson,
      if (cornersJson != null) 'corners_json': cornersJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SketchProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<Uint8List>? originalBytes,
    Value<Uint8List>? sketchBytes,
    Value<Uint8List?>? thumbnailBytes,
    Value<String>? optionsJson,
    Value<String>? paperJson,
    Value<String>? cornersJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SketchProjectsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      originalBytes: originalBytes ?? this.originalBytes,
      sketchBytes: sketchBytes ?? this.sketchBytes,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      optionsJson: optionsJson ?? this.optionsJson,
      paperJson: paperJson ?? this.paperJson,
      cornersJson: cornersJson ?? this.cornersJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalBytes.present) {
      map['original_bytes'] = Variable<Uint8List>(originalBytes.value);
    }
    if (sketchBytes.present) {
      map['sketch_bytes'] = Variable<Uint8List>(sketchBytes.value);
    }
    if (thumbnailBytes.present) {
      map['thumbnail_bytes'] = Variable<Uint8List>(thumbnailBytes.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (paperJson.present) {
      map['paper_json'] = Variable<String>(paperJson.value);
    }
    if (cornersJson.present) {
      map['corners_json'] = Variable<String>(cornersJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SketchProjectsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('originalBytes: $originalBytes, ')
          ..write('sketchBytes: $sketchBytes, ')
          ..write('thumbnailBytes: $thumbnailBytes, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('paperJson: $paperJson, ')
          ..write('cornersJson: $cornersJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BeaconQueueTable extends BeaconQueue
    with TableInfo<$BeaconQueueTable, BeaconQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BeaconQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, payloadJson, createdAt, attempts];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'beacon_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<BeaconQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BeaconQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BeaconQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  $BeaconQueueTable createAlias(String alias) {
    return $BeaconQueueTable(attachedDatabase, alias);
  }
}

class BeaconQueueData extends DataClass implements Insertable<BeaconQueueData> {
  final String id;
  final String payloadJson;
  final DateTime createdAt;
  final int attempts;
  const BeaconQueueData({
    required this.id,
    required this.payloadJson,
    required this.createdAt,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  BeaconQueueCompanion toCompanion(bool nullToAbsent) {
    return BeaconQueueCompanion(
      id: Value(id),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
    );
  }

  factory BeaconQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BeaconQueueData(
      id: serializer.fromJson<String>(json['id']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  BeaconQueueData copyWith({
    String? id,
    String? payloadJson,
    DateTime? createdAt,
    int? attempts,
  }) => BeaconQueueData(
    id: id ?? this.id,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
  );
  BeaconQueueData copyWithCompanion(BeaconQueueCompanion data) {
    return BeaconQueueData(
      id: data.id.present ? data.id.value : this.id,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BeaconQueueData(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payloadJson, createdAt, attempts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BeaconQueueData &&
          other.id == this.id &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts);
}

class BeaconQueueCompanion extends UpdateCompanion<BeaconQueueData> {
  final Value<String> id;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<int> rowid;
  const BeaconQueueCompanion({
    this.id = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BeaconQueueCompanion.insert({
    required String id,
    required String payloadJson,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<BeaconQueueData> custom({
    Expression<String>? id,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BeaconQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<int>? rowid,
  }) {
    return BeaconQueueCompanion(
      id: id ?? this.id,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BeaconQueueCompanion(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SketchProjectsTable sketchProjects = $SketchProjectsTable(this);
  late final $BeaconQueueTable beaconQueue = $BeaconQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sketchProjects,
    beaconQueue,
  ];
}

typedef $$SketchProjectsTableCreateCompanionBuilder =
    SketchProjectsCompanion Function({
      required String id,
      required String title,
      required Uint8List originalBytes,
      required Uint8List sketchBytes,
      Value<Uint8List?> thumbnailBytes,
      required String optionsJson,
      required String paperJson,
      required String cornersJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SketchProjectsTableUpdateCompanionBuilder =
    SketchProjectsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<Uint8List> originalBytes,
      Value<Uint8List> sketchBytes,
      Value<Uint8List?> thumbnailBytes,
      Value<String> optionsJson,
      Value<String> paperJson,
      Value<String> cornersJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SketchProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SketchProjectsTable> {
  $$SketchProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get originalBytes => $composableBuilder(
    column: $table.originalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get sketchBytes => $composableBuilder(
    column: $table.sketchBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get thumbnailBytes => $composableBuilder(
    column: $table.thumbnailBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paperJson => $composableBuilder(
    column: $table.paperJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cornersJson => $composableBuilder(
    column: $table.cornersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SketchProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SketchProjectsTable> {
  $$SketchProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get originalBytes => $composableBuilder(
    column: $table.originalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get sketchBytes => $composableBuilder(
    column: $table.sketchBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get thumbnailBytes => $composableBuilder(
    column: $table.thumbnailBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paperJson => $composableBuilder(
    column: $table.paperJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cornersJson => $composableBuilder(
    column: $table.cornersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SketchProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SketchProjectsTable> {
  $$SketchProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<Uint8List> get originalBytes => $composableBuilder(
    column: $table.originalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get sketchBytes => $composableBuilder(
    column: $table.sketchBytes,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get thumbnailBytes => $composableBuilder(
    column: $table.thumbnailBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paperJson =>
      $composableBuilder(column: $table.paperJson, builder: (column) => column);

  GeneratedColumn<String> get cornersJson => $composableBuilder(
    column: $table.cornersJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SketchProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SketchProjectsTable,
          SketchProjectRow,
          $$SketchProjectsTableFilterComposer,
          $$SketchProjectsTableOrderingComposer,
          $$SketchProjectsTableAnnotationComposer,
          $$SketchProjectsTableCreateCompanionBuilder,
          $$SketchProjectsTableUpdateCompanionBuilder,
          (
            SketchProjectRow,
            BaseReferences<
              _$AppDatabase,
              $SketchProjectsTable,
              SketchProjectRow
            >,
          ),
          SketchProjectRow,
          PrefetchHooks Function()
        > {
  $$SketchProjectsTableTableManager(
    _$AppDatabase db,
    $SketchProjectsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SketchProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SketchProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SketchProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<Uint8List> originalBytes = const Value.absent(),
                Value<Uint8List> sketchBytes = const Value.absent(),
                Value<Uint8List?> thumbnailBytes = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<String> paperJson = const Value.absent(),
                Value<String> cornersJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SketchProjectsCompanion(
                id: id,
                title: title,
                originalBytes: originalBytes,
                sketchBytes: sketchBytes,
                thumbnailBytes: thumbnailBytes,
                optionsJson: optionsJson,
                paperJson: paperJson,
                cornersJson: cornersJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required Uint8List originalBytes,
                required Uint8List sketchBytes,
                Value<Uint8List?> thumbnailBytes = const Value.absent(),
                required String optionsJson,
                required String paperJson,
                required String cornersJson,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SketchProjectsCompanion.insert(
                id: id,
                title: title,
                originalBytes: originalBytes,
                sketchBytes: sketchBytes,
                thumbnailBytes: thumbnailBytes,
                optionsJson: optionsJson,
                paperJson: paperJson,
                cornersJson: cornersJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SketchProjectsTable, SketchProjectRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SketchProjectsTable,
                    SketchProjectRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SketchProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SketchProjectsTable,
      SketchProjectRow,
      $$SketchProjectsTableFilterComposer,
      $$SketchProjectsTableOrderingComposer,
      $$SketchProjectsTableAnnotationComposer,
      $$SketchProjectsTableCreateCompanionBuilder,
      $$SketchProjectsTableUpdateCompanionBuilder,
      (
        SketchProjectRow,
        BaseReferences<_$AppDatabase, $SketchProjectsTable, SketchProjectRow>,
      ),
      SketchProjectRow,
      PrefetchHooks Function()
    >;
typedef $$BeaconQueueTableCreateCompanionBuilder =
    BeaconQueueCompanion Function({
      required String id,
      required String payloadJson,
      required DateTime createdAt,
      Value<int> attempts,
      Value<int> rowid,
    });
typedef $$BeaconQueueTableUpdateCompanionBuilder =
    BeaconQueueCompanion Function({
      Value<String> id,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<int> rowid,
    });

class $$BeaconQueueTableFilterComposer
    extends Composer<_$AppDatabase, $BeaconQueueTable> {
  $$BeaconQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BeaconQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $BeaconQueueTable> {
  $$BeaconQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BeaconQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $BeaconQueueTable> {
  $$BeaconQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$BeaconQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BeaconQueueTable,
          BeaconQueueData,
          $$BeaconQueueTableFilterComposer,
          $$BeaconQueueTableOrderingComposer,
          $$BeaconQueueTableAnnotationComposer,
          $$BeaconQueueTableCreateCompanionBuilder,
          $$BeaconQueueTableUpdateCompanionBuilder,
          (
            BeaconQueueData,
            BaseReferences<_$AppDatabase, $BeaconQueueTable, BeaconQueueData>,
          ),
          BeaconQueueData,
          PrefetchHooks Function()
        > {
  $$BeaconQueueTableTableManager(_$AppDatabase db, $BeaconQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BeaconQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BeaconQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BeaconQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BeaconQueueCompanion(
                id: id,
                payloadJson: payloadJson,
                createdAt: createdAt,
                attempts: attempts,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payloadJson,
                required DateTime createdAt,
                Value<int> attempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BeaconQueueCompanion.insert(
                id: id,
                payloadJson: payloadJson,
                createdAt: createdAt,
                attempts: attempts,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BeaconQueueTable, BeaconQueueData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BeaconQueueTable,
                    BeaconQueueData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BeaconQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BeaconQueueTable,
      BeaconQueueData,
      $$BeaconQueueTableFilterComposer,
      $$BeaconQueueTableOrderingComposer,
      $$BeaconQueueTableAnnotationComposer,
      $$BeaconQueueTableCreateCompanionBuilder,
      $$BeaconQueueTableUpdateCompanionBuilder,
      (
        BeaconQueueData,
        BaseReferences<_$AppDatabase, $BeaconQueueTable, BeaconQueueData>,
      ),
      BeaconQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SketchProjectsTableTableManager get sketchProjects =>
      $$SketchProjectsTableTableManager(_db, _db.sketchProjects);
  $$BeaconQueueTableTableManager get beaconQueue =>
      $$BeaconQueueTableTableManager(_db, _db.beaconQueue);
}
