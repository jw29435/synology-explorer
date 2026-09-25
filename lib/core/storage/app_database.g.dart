// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ServersTable extends Servers with TableInfo<$ServersTable, Server> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lanUrlMeta = const VerificationMeta('lanUrl');
  @override
  late final GeneratedColumn<String> lanUrl = GeneratedColumn<String>(
    'lan_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalUrlMeta = const VerificationMeta(
    'externalUrl',
  );
  @override
  late final GeneratedColumn<String> externalUrl = GeneratedColumn<String>(
    'external_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userMeta = const VerificationMeta('user');
  @override
  late final GeneratedColumn<String> user = GeneratedColumn<String>(
    'user',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, lanUrl, externalUrl, user];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'servers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Server> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('lan_url')) {
      context.handle(
        _lanUrlMeta,
        lanUrl.isAcceptableOrUnknown(data['lan_url']!, _lanUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_lanUrlMeta);
    }
    if (data.containsKey('external_url')) {
      context.handle(
        _externalUrlMeta,
        externalUrl.isAcceptableOrUnknown(
          data['external_url']!,
          _externalUrlMeta,
        ),
      );
    }
    if (data.containsKey('user')) {
      context.handle(
        _userMeta,
        user.isAcceptableOrUnknown(data['user']!, _userMeta),
      );
    } else if (isInserting) {
      context.missing(_userMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Server map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Server(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      lanUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lan_url'],
      )!,
      externalUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_url'],
      ),
      user: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user'],
      )!,
    );
  }

  @override
  $ServersTable createAlias(String alias) {
    return $ServersTable(attachedDatabase, alias);
  }
}

class Server extends DataClass implements Insertable<Server> {
  final int id;
  final String name;
  final String lanUrl;
  final String? externalUrl;
  final String user;
  const Server({
    required this.id,
    required this.name,
    required this.lanUrl,
    this.externalUrl,
    required this.user,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['lan_url'] = Variable<String>(lanUrl);
    if (!nullToAbsent || externalUrl != null) {
      map['external_url'] = Variable<String>(externalUrl);
    }
    map['user'] = Variable<String>(user);
    return map;
  }

  ServersCompanion toCompanion(bool nullToAbsent) {
    return ServersCompanion(
      id: Value(id),
      name: Value(name),
      lanUrl: Value(lanUrl),
      externalUrl: externalUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(externalUrl),
      user: Value(user),
    );
  }

  factory Server.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Server(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      lanUrl: serializer.fromJson<String>(json['lanUrl']),
      externalUrl: serializer.fromJson<String?>(json['externalUrl']),
      user: serializer.fromJson<String>(json['user']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'lanUrl': serializer.toJson<String>(lanUrl),
      'externalUrl': serializer.toJson<String?>(externalUrl),
      'user': serializer.toJson<String>(user),
    };
  }

  Server copyWith({
    int? id,
    String? name,
    String? lanUrl,
    Value<String?> externalUrl = const Value.absent(),
    String? user,
  }) => Server(
    id: id ?? this.id,
    name: name ?? this.name,
    lanUrl: lanUrl ?? this.lanUrl,
    externalUrl: externalUrl.present ? externalUrl.value : this.externalUrl,
    user: user ?? this.user,
  );
  Server copyWithCompanion(ServersCompanion data) {
    return Server(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      lanUrl: data.lanUrl.present ? data.lanUrl.value : this.lanUrl,
      externalUrl: data.externalUrl.present
          ? data.externalUrl.value
          : this.externalUrl,
      user: data.user.present ? data.user.value : this.user,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Server(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('lanUrl: $lanUrl, ')
          ..write('externalUrl: $externalUrl, ')
          ..write('user: $user')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, lanUrl, externalUrl, user);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Server &&
          other.id == this.id &&
          other.name == this.name &&
          other.lanUrl == this.lanUrl &&
          other.externalUrl == this.externalUrl &&
          other.user == this.user);
}

class ServersCompanion extends UpdateCompanion<Server> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> lanUrl;
  final Value<String?> externalUrl;
  final Value<String> user;
  const ServersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.lanUrl = const Value.absent(),
    this.externalUrl = const Value.absent(),
    this.user = const Value.absent(),
  });
  ServersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String lanUrl,
    this.externalUrl = const Value.absent(),
    required String user,
  }) : name = Value(name),
       lanUrl = Value(lanUrl),
       user = Value(user);
  static Insertable<Server> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? lanUrl,
    Expression<String>? externalUrl,
    Expression<String>? user,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (lanUrl != null) 'lan_url': lanUrl,
      if (externalUrl != null) 'external_url': externalUrl,
      if (user != null) 'user': user,
    });
  }

  ServersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? lanUrl,
    Value<String?>? externalUrl,
    Value<String>? user,
  }) {
    return ServersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      lanUrl: lanUrl ?? this.lanUrl,
      externalUrl: externalUrl ?? this.externalUrl,
      user: user ?? this.user,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lanUrl.present) {
      map['lan_url'] = Variable<String>(lanUrl.value);
    }
    if (externalUrl.present) {
      map['external_url'] = Variable<String>(externalUrl.value);
    }
    if (user.present) {
      map['user'] = Variable<String>(user.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('lanUrl: $lanUrl, ')
          ..write('externalUrl: $externalUrl, ')
          ..write('user: $user')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ServersTable servers = $ServersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [servers];
}

typedef $$ServersTableCreateCompanionBuilder = ServersCompanion Function({
  Value<int> id,
  required String name,
  required String lanUrl,
  Value<String?> externalUrl,
  required String user,
});
typedef $$ServersTableUpdateCompanionBuilder = ServersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> lanUrl,
  Value<String?> externalUrl,
  Value<String> user,
});

class $$ServersTableFilterComposer
    extends Composer<_$AppDatabase, $ServersTable> {
  $$ServersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lanUrl => $composableBuilder(
    column: $table.lanUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalUrl => $composableBuilder(
    column: $table.externalUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get user => $composableBuilder(
    column: $table.user,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServersTableOrderingComposer
    extends Composer<_$AppDatabase, $ServersTable> {
  $$ServersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lanUrl => $composableBuilder(
    column: $table.lanUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalUrl => $composableBuilder(
    column: $table.externalUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get user => $composableBuilder(
    column: $table.user,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ServersTable> {
  $$ServersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get lanUrl =>
      $composableBuilder(column: $table.lanUrl, builder: (column) => column);

  GeneratedColumn<String> get externalUrl => $composableBuilder(
    column: $table.externalUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get user =>
      $composableBuilder(column: $table.user, builder: (column) => column);
}

class $$ServersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ServersTable,
          Server,
          $$ServersTableFilterComposer,
          $$ServersTableOrderingComposer,
          $$ServersTableAnnotationComposer,
          $$ServersTableCreateCompanionBuilder,
          $$ServersTableUpdateCompanionBuilder,
          (Server, BaseReferences<_$AppDatabase, $ServersTable, Server>),
          Server,
          PrefetchHooks Function()
        > {
  $$ServersTableTableManager(_$AppDatabase db, $ServersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> lanUrl = const Value.absent(),
                Value<String?> externalUrl = const Value.absent(),
                Value<String> user = const Value.absent(),
              }) => ServersCompanion(
                id: id,
                name: name,
                lanUrl: lanUrl,
                externalUrl: externalUrl,
                user: user,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String lanUrl,
                Value<String?> externalUrl = const Value.absent(),
                required String user,
              }) => ServersCompanion.insert(
                id: id,
                name: name,
                lanUrl: lanUrl,
                externalUrl: externalUrl,
                user: user,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ServersTable, Server>(table),
                  BaseReferences<_$AppDatabase, $ServersTable, Server>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ServersTable,
      Server,
      $$ServersTableFilterComposer,
      $$ServersTableOrderingComposer,
      $$ServersTableAnnotationComposer,
      $$ServersTableCreateCompanionBuilder,
      $$ServersTableUpdateCompanionBuilder,
      (Server, BaseReferences<_$AppDatabase, $ServersTable, Server>),
      Server,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ServersTableTableManager get servers =>
      $$ServersTableTableManager(_db, _db.servers);
}
