// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_items_database.dart';

// ignore_for_file: type=lint
class $SharedItemsTable extends SharedItems
    with TableInfo<$SharedItemsTable, SharedItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SharedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceAppMeta = const VerificationMeta(
    'sourceApp',
  );
  @override
  late final GeneratedColumn<String> sourceApp = GeneratedColumn<String>(
    'source_app',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    content,
    url,
    imagePath,
    sourceApp,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shared_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SharedItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('source_app')) {
      context.handle(
        _sourceAppMeta,
        sourceApp.isAcceptableOrUnknown(data['source_app']!, _sourceAppMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceAppMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SharedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SharedItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      sourceApp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_app'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $SharedItemsTable createAlias(String alias) {
    return $SharedItemsTable(attachedDatabase, alias);
  }
}

class SharedItem extends DataClass implements Insertable<SharedItem> {
  final int id;
  final String type;
  final String? content;
  final String? url;
  final String? imagePath;
  final String sourceApp;
  final int timestamp;
  const SharedItem({
    required this.id,
    required this.type,
    this.content,
    this.url,
    this.imagePath,
    required this.sourceApp,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['source_app'] = Variable<String>(sourceApp);
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  SharedItemsCompanion toCompanion(bool nullToAbsent) {
    return SharedItemsCompanion(
      id: Value(id),
      type: Value(type),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      sourceApp: Value(sourceApp),
      timestamp: Value(timestamp),
    );
  }

  factory SharedItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SharedItem(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      content: serializer.fromJson<String?>(json['content']),
      url: serializer.fromJson<String?>(json['url']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      sourceApp: serializer.fromJson<String>(json['sourceApp']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'content': serializer.toJson<String?>(content),
      'url': serializer.toJson<String?>(url),
      'imagePath': serializer.toJson<String?>(imagePath),
      'sourceApp': serializer.toJson<String>(sourceApp),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  SharedItem copyWith({
    int? id,
    String? type,
    Value<String?> content = const Value.absent(),
    Value<String?> url = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    String? sourceApp,
    int? timestamp,
  }) => SharedItem(
    id: id ?? this.id,
    type: type ?? this.type,
    content: content.present ? content.value : this.content,
    url: url.present ? url.value : this.url,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    sourceApp: sourceApp ?? this.sourceApp,
    timestamp: timestamp ?? this.timestamp,
  );
  SharedItem copyWithCompanion(SharedItemsCompanion data) {
    return SharedItem(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      url: data.url.present ? data.url.value : this.url,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      sourceApp: data.sourceApp.present ? data.sourceApp.value : this.sourceApp,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SharedItem(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('url: $url, ')
          ..write('imagePath: $imagePath, ')
          ..write('sourceApp: $sourceApp, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, content, url, imagePath, sourceApp, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SharedItem &&
          other.id == this.id &&
          other.type == this.type &&
          other.content == this.content &&
          other.url == this.url &&
          other.imagePath == this.imagePath &&
          other.sourceApp == this.sourceApp &&
          other.timestamp == this.timestamp);
}

class SharedItemsCompanion extends UpdateCompanion<SharedItem> {
  final Value<int> id;
  final Value<String> type;
  final Value<String?> content;
  final Value<String?> url;
  final Value<String?> imagePath;
  final Value<String> sourceApp;
  final Value<int> timestamp;
  const SharedItemsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.url = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.sourceApp = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  SharedItemsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    this.content = const Value.absent(),
    this.url = const Value.absent(),
    this.imagePath = const Value.absent(),
    required String sourceApp,
    required int timestamp,
  }) : type = Value(type),
       sourceApp = Value(sourceApp),
       timestamp = Value(timestamp);
  static Insertable<SharedItem> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? content,
    Expression<String>? url,
    Expression<String>? imagePath,
    Expression<String>? sourceApp,
    Expression<int>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (url != null) 'url': url,
      if (imagePath != null) 'image_path': imagePath,
      if (sourceApp != null) 'source_app': sourceApp,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  SharedItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String?>? content,
    Value<String?>? url,
    Value<String?>? imagePath,
    Value<String>? sourceApp,
    Value<int>? timestamp,
  }) {
    return SharedItemsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      url: url ?? this.url,
      imagePath: imagePath ?? this.imagePath,
      sourceApp: sourceApp ?? this.sourceApp,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (sourceApp.present) {
      map['source_app'] = Variable<String>(sourceApp.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SharedItemsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('url: $url, ')
          ..write('imagePath: $imagePath, ')
          ..write('sourceApp: $sourceApp, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SharedItemsTable sharedItems = $SharedItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sharedItems];
}

typedef $$SharedItemsTableCreateCompanionBuilder =
    SharedItemsCompanion Function({
      Value<int> id,
      required String type,
      Value<String?> content,
      Value<String?> url,
      Value<String?> imagePath,
      required String sourceApp,
      required int timestamp,
    });
typedef $$SharedItemsTableUpdateCompanionBuilder =
    SharedItemsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String?> content,
      Value<String?> url,
      Value<String?> imagePath,
      Value<String> sourceApp,
      Value<int> timestamp,
    });

class $$SharedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SharedItemsTable> {
  $$SharedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceApp => $composableBuilder(
    column: $table.sourceApp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SharedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SharedItemsTable> {
  $$SharedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceApp => $composableBuilder(
    column: $table.sourceApp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SharedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SharedItemsTable> {
  $$SharedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get sourceApp =>
      $composableBuilder(column: $table.sourceApp, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$SharedItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SharedItemsTable,
          SharedItem,
          $$SharedItemsTableFilterComposer,
          $$SharedItemsTableOrderingComposer,
          $$SharedItemsTableAnnotationComposer,
          $$SharedItemsTableCreateCompanionBuilder,
          $$SharedItemsTableUpdateCompanionBuilder,
          (
            SharedItem,
            BaseReferences<_$AppDatabase, $SharedItemsTable, SharedItem>,
          ),
          SharedItem,
          PrefetchHooks Function()
        > {
  $$SharedItemsTableTableManager(_$AppDatabase db, $SharedItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SharedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SharedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SharedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String> sourceApp = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
              }) => SharedItemsCompanion(
                id: id,
                type: type,
                content: content,
                url: url,
                imagePath: imagePath,
                sourceApp: sourceApp,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                Value<String?> content = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                required String sourceApp,
                required int timestamp,
              }) => SharedItemsCompanion.insert(
                id: id,
                type: type,
                content: content,
                url: url,
                imagePath: imagePath,
                sourceApp: sourceApp,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SharedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SharedItemsTable,
      SharedItem,
      $$SharedItemsTableFilterComposer,
      $$SharedItemsTableOrderingComposer,
      $$SharedItemsTableAnnotationComposer,
      $$SharedItemsTableCreateCompanionBuilder,
      $$SharedItemsTableUpdateCompanionBuilder,
      (
        SharedItem,
        BaseReferences<_$AppDatabase, $SharedItemsTable, SharedItem>,
      ),
      SharedItem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SharedItemsTableTableManager get sharedItems =>
      $$SharedItemsTableTableManager(_db, _db.sharedItems);
}
