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

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDirMeta = const VerificationMeta('isDir');
  @override
  late final GeneratedColumn<bool> isDir = GeneratedColumn<bool>(
    'is_dir',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dir" IN (0, 1))',
    ),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [serverId, path, isDir, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('is_dir')) {
      context.handle(
        _isDirMeta,
        isDir.isAcceptableOrUnknown(data['is_dir']!, _isDirMeta),
      );
    } else if (isInserting) {
      context.missing(_isDirMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverId, path};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      isDir: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dir'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int serverId;
  final String path;
  final bool isDir;
  final DateTime addedAt;
  const Favorite({
    required this.serverId,
    required this.path,
    required this.isDir,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<int>(serverId);
    map['path'] = Variable<String>(path);
    map['is_dir'] = Variable<bool>(isDir);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      serverId: Value(serverId),
      path: Value(path),
      isDir: Value(isDir),
      addedAt: Value(addedAt),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      serverId: serializer.fromJson<int>(json['serverId']),
      path: serializer.fromJson<String>(json['path']),
      isDir: serializer.fromJson<bool>(json['isDir']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<int>(serverId),
      'path': serializer.toJson<String>(path),
      'isDir': serializer.toJson<bool>(isDir),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Favorite copyWith({
    int? serverId,
    String? path,
    bool? isDir,
    DateTime? addedAt,
  }) => Favorite(
    serverId: serverId ?? this.serverId,
    path: path ?? this.path,
    isDir: isDir ?? this.isDir,
    addedAt: addedAt ?? this.addedAt,
  );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      path: data.path.present ? data.path.value : this.path,
      isDir: data.isDir.present ? data.isDir.value : this.isDir,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('serverId: $serverId, ')
          ..write('path: $path, ')
          ..write('isDir: $isDir, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(serverId, path, isDir, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.serverId == this.serverId &&
          other.path == this.path &&
          other.isDir == this.isDir &&
          other.addedAt == this.addedAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> serverId;
  final Value<String> path;
  final Value<bool> isDir;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.serverId = const Value.absent(),
    this.path = const Value.absent(),
    this.isDir = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    required int serverId,
    required String path,
    required bool isDir,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : serverId = Value(serverId),
       path = Value(path),
       isDir = Value(isDir),
       addedAt = Value(addedAt);
  static Insertable<Favorite> custom({
    Expression<int>? serverId,
    Expression<String>? path,
    Expression<bool>? isDir,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (path != null) 'path': path,
      if (isDir != null) 'is_dir': isDir,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({
    Value<int>? serverId,
    Value<String>? path,
    Value<bool>? isDir,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return FavoritesCompanion(
      serverId: serverId ?? this.serverId,
      path: path ?? this.path,
      isDir: isDir ?? this.isDir,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (isDir.present) {
      map['is_dir'] = Variable<bool>(isDir.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('serverId: $serverId, ')
          ..write('path: $path, ')
          ..write('isDir: $isDir, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecentFilesTable extends RecentFiles
    with TableInfo<$RecentFilesTable, RecentFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [serverId, path, openedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recent_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecentFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverId, path};
  @override
  RecentFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentFile(
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
    );
  }

  @override
  $RecentFilesTable createAlias(String alias) {
    return $RecentFilesTable(attachedDatabase, alias);
  }
}

class RecentFile extends DataClass implements Insertable<RecentFile> {
  final int serverId;
  final String path;
  final DateTime openedAt;
  const RecentFile({
    required this.serverId,
    required this.path,
    required this.openedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<int>(serverId);
    map['path'] = Variable<String>(path);
    map['opened_at'] = Variable<DateTime>(openedAt);
    return map;
  }

  RecentFilesCompanion toCompanion(bool nullToAbsent) {
    return RecentFilesCompanion(
      serverId: Value(serverId),
      path: Value(path),
      openedAt: Value(openedAt),
    );
  }

  factory RecentFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentFile(
      serverId: serializer.fromJson<int>(json['serverId']),
      path: serializer.fromJson<String>(json['path']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<int>(serverId),
      'path': serializer.toJson<String>(path),
      'openedAt': serializer.toJson<DateTime>(openedAt),
    };
  }

  RecentFile copyWith({int? serverId, String? path, DateTime? openedAt}) =>
      RecentFile(
        serverId: serverId ?? this.serverId,
        path: path ?? this.path,
        openedAt: openedAt ?? this.openedAt,
      );
  RecentFile copyWithCompanion(RecentFilesCompanion data) {
    return RecentFile(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      path: data.path.present ? data.path.value : this.path,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentFile(')
          ..write('serverId: $serverId, ')
          ..write('path: $path, ')
          ..write('openedAt: $openedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(serverId, path, openedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentFile &&
          other.serverId == this.serverId &&
          other.path == this.path &&
          other.openedAt == this.openedAt);
}

class RecentFilesCompanion extends UpdateCompanion<RecentFile> {
  final Value<int> serverId;
  final Value<String> path;
  final Value<DateTime> openedAt;
  final Value<int> rowid;
  const RecentFilesCompanion({
    this.serverId = const Value.absent(),
    this.path = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecentFilesCompanion.insert({
    required int serverId,
    required String path,
    required DateTime openedAt,
    this.rowid = const Value.absent(),
  }) : serverId = Value(serverId),
       path = Value(path),
       openedAt = Value(openedAt);
  static Insertable<RecentFile> custom({
    Expression<int>? serverId,
    Expression<String>? path,
    Expression<DateTime>? openedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (path != null) 'path': path,
      if (openedAt != null) 'opened_at': openedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecentFilesCompanion copyWith({
    Value<int>? serverId,
    Value<String>? path,
    Value<DateTime>? openedAt,
    Value<int>? rowid,
  }) {
    return RecentFilesCompanion(
      serverId: serverId ?? this.serverId,
      path: path ?? this.path,
      openedAt: openedAt ?? this.openedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentFilesCompanion(')
          ..write('serverId: $serverId, ')
          ..write('path: $path, ')
          ..write('openedAt: $openedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransfersTable extends Transfers
    with TableInfo<$TransfersTable, Transfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransfersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransferKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransferKind>($TransfersTable.$converterkind);
  static const VerificationMeta _remotePathMeta = const VerificationMeta(
    'remotePath',
  );
  @override
  late final GeneratedColumn<String> remotePath = GeneratedColumn<String>(
    'remote_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesDoneMeta = const VerificationMeta(
    'bytesDone',
  );
  @override
  late final GeneratedColumn<int> bytesDone = GeneratedColumn<int>(
    'bytes_done',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bytesTotalMeta = const VerificationMeta(
    'bytesTotal',
  );
  @override
  late final GeneratedColumn<int> bytesTotal = GeneratedColumn<int>(
    'bytes_total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransferState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransferState>($TransfersTable.$converterstate);
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overwriteMeta = const VerificationMeta(
    'overwrite',
  );
  @override
  late final GeneratedColumn<bool> overwrite = GeneratedColumn<bool>(
    'overwrite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("overwrite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remoteMtimeMeta = const VerificationMeta(
    'remoteMtime',
  );
  @override
  late final GeneratedColumn<DateTime> remoteMtime = GeneratedColumn<DateTime>(
    'remote_mtime',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    kind,
    remotePath,
    localPath,
    bytesDone,
    bytesTotal,
    state,
    error,
    overwrite,
    remoteMtime,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transfer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('remote_path')) {
      context.handle(
        _remotePathMeta,
        remotePath.isAcceptableOrUnknown(data['remote_path']!, _remotePathMeta),
      );
    } else if (isInserting) {
      context.missing(_remotePathMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('bytes_done')) {
      context.handle(
        _bytesDoneMeta,
        bytesDone.isAcceptableOrUnknown(data['bytes_done']!, _bytesDoneMeta),
      );
    }
    if (data.containsKey('bytes_total')) {
      context.handle(
        _bytesTotalMeta,
        bytesTotal.isAcceptableOrUnknown(data['bytes_total']!, _bytesTotalMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('overwrite')) {
      context.handle(
        _overwriteMeta,
        overwrite.isAcceptableOrUnknown(data['overwrite']!, _overwriteMeta),
      );
    }
    if (data.containsKey('remote_mtime')) {
      context.handle(
        _remoteMtimeMeta,
        remoteMtime.isAcceptableOrUnknown(
          data['remote_mtime']!,
          _remoteMtimeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transfer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      kind: $TransfersTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      remotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_path'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      bytesDone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_done'],
      )!,
      bytesTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_total'],
      ),
      state: $TransfersTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      overwrite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}overwrite'],
      )!,
      remoteMtime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}remote_mtime'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TransfersTable createAlias(String alias) {
    return $TransfersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransferKind, String, String> $converterkind =
      const EnumNameConverter<TransferKind>(TransferKind.values);
  static JsonTypeConverter2<TransferState, String, String> $converterstate =
      const EnumNameConverter<TransferState>(TransferState.values);
}

class Transfer extends DataClass implements Insertable<Transfer> {
  final int id;
  final int serverId;
  final TransferKind kind;
  final String remotePath;
  final String localPath;
  final int bytesDone;
  final int? bytesTotal;
  final TransferState state;
  final String? error;

  /// Nur Upload: vorhandene Datei überschreiben statt „ (1)“ anhängen.
  final bool overwrite;

  /// Nur Download: Änderungszeit auf dem NAS, wandert nach [OfflineFiles].
  final DateTime? remoteMtime;
  final DateTime createdAt;
  const Transfer({
    required this.id,
    required this.serverId,
    required this.kind,
    required this.remotePath,
    required this.localPath,
    required this.bytesDone,
    this.bytesTotal,
    required this.state,
    this.error,
    required this.overwrite,
    this.remoteMtime,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<int>(serverId);
    {
      map['kind'] = Variable<String>(
        $TransfersTable.$converterkind.toSql(kind),
      );
    }
    map['remote_path'] = Variable<String>(remotePath);
    map['local_path'] = Variable<String>(localPath);
    map['bytes_done'] = Variable<int>(bytesDone);
    if (!nullToAbsent || bytesTotal != null) {
      map['bytes_total'] = Variable<int>(bytesTotal);
    }
    {
      map['state'] = Variable<String>(
        $TransfersTable.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['overwrite'] = Variable<bool>(overwrite);
    if (!nullToAbsent || remoteMtime != null) {
      map['remote_mtime'] = Variable<DateTime>(remoteMtime);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransfersCompanion toCompanion(bool nullToAbsent) {
    return TransfersCompanion(
      id: Value(id),
      serverId: Value(serverId),
      kind: Value(kind),
      remotePath: Value(remotePath),
      localPath: Value(localPath),
      bytesDone: Value(bytesDone),
      bytesTotal: bytesTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(bytesTotal),
      state: Value(state),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      overwrite: Value(overwrite),
      remoteMtime: remoteMtime == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteMtime),
      createdAt: Value(createdAt),
    );
  }

  factory Transfer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transfer(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int>(json['serverId']),
      kind: $TransfersTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      remotePath: serializer.fromJson<String>(json['remotePath']),
      localPath: serializer.fromJson<String>(json['localPath']),
      bytesDone: serializer.fromJson<int>(json['bytesDone']),
      bytesTotal: serializer.fromJson<int?>(json['bytesTotal']),
      state: $TransfersTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      error: serializer.fromJson<String?>(json['error']),
      overwrite: serializer.fromJson<bool>(json['overwrite']),
      remoteMtime: serializer.fromJson<DateTime?>(json['remoteMtime']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int>(serverId),
      'kind': serializer.toJson<String>(
        $TransfersTable.$converterkind.toJson(kind),
      ),
      'remotePath': serializer.toJson<String>(remotePath),
      'localPath': serializer.toJson<String>(localPath),
      'bytesDone': serializer.toJson<int>(bytesDone),
      'bytesTotal': serializer.toJson<int?>(bytesTotal),
      'state': serializer.toJson<String>(
        $TransfersTable.$converterstate.toJson(state),
      ),
      'error': serializer.toJson<String?>(error),
      'overwrite': serializer.toJson<bool>(overwrite),
      'remoteMtime': serializer.toJson<DateTime?>(remoteMtime),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Transfer copyWith({
    int? id,
    int? serverId,
    TransferKind? kind,
    String? remotePath,
    String? localPath,
    int? bytesDone,
    Value<int?> bytesTotal = const Value.absent(),
    TransferState? state,
    Value<String?> error = const Value.absent(),
    bool? overwrite,
    Value<DateTime?> remoteMtime = const Value.absent(),
    DateTime? createdAt,
  }) => Transfer(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    kind: kind ?? this.kind,
    remotePath: remotePath ?? this.remotePath,
    localPath: localPath ?? this.localPath,
    bytesDone: bytesDone ?? this.bytesDone,
    bytesTotal: bytesTotal.present ? bytesTotal.value : this.bytesTotal,
    state: state ?? this.state,
    error: error.present ? error.value : this.error,
    overwrite: overwrite ?? this.overwrite,
    remoteMtime: remoteMtime.present ? remoteMtime.value : this.remoteMtime,
    createdAt: createdAt ?? this.createdAt,
  );
  Transfer copyWithCompanion(TransfersCompanion data) {
    return Transfer(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      kind: data.kind.present ? data.kind.value : this.kind,
      remotePath: data.remotePath.present
          ? data.remotePath.value
          : this.remotePath,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      bytesDone: data.bytesDone.present ? data.bytesDone.value : this.bytesDone,
      bytesTotal: data.bytesTotal.present
          ? data.bytesTotal.value
          : this.bytesTotal,
      state: data.state.present ? data.state.value : this.state,
      error: data.error.present ? data.error.value : this.error,
      overwrite: data.overwrite.present ? data.overwrite.value : this.overwrite,
      remoteMtime: data.remoteMtime.present
          ? data.remoteMtime.value
          : this.remoteMtime,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transfer(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('kind: $kind, ')
          ..write('remotePath: $remotePath, ')
          ..write('localPath: $localPath, ')
          ..write('bytesDone: $bytesDone, ')
          ..write('bytesTotal: $bytesTotal, ')
          ..write('state: $state, ')
          ..write('error: $error, ')
          ..write('overwrite: $overwrite, ')
          ..write('remoteMtime: $remoteMtime, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    kind,
    remotePath,
    localPath,
    bytesDone,
    bytesTotal,
    state,
    error,
    overwrite,
    remoteMtime,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transfer &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.kind == this.kind &&
          other.remotePath == this.remotePath &&
          other.localPath == this.localPath &&
          other.bytesDone == this.bytesDone &&
          other.bytesTotal == this.bytesTotal &&
          other.state == this.state &&
          other.error == this.error &&
          other.overwrite == this.overwrite &&
          other.remoteMtime == this.remoteMtime &&
          other.createdAt == this.createdAt);
}

class TransfersCompanion extends UpdateCompanion<Transfer> {
  final Value<int> id;
  final Value<int> serverId;
  final Value<TransferKind> kind;
  final Value<String> remotePath;
  final Value<String> localPath;
  final Value<int> bytesDone;
  final Value<int?> bytesTotal;
  final Value<TransferState> state;
  final Value<String?> error;
  final Value<bool> overwrite;
  final Value<DateTime?> remoteMtime;
  final Value<DateTime> createdAt;
  const TransfersCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.kind = const Value.absent(),
    this.remotePath = const Value.absent(),
    this.localPath = const Value.absent(),
    this.bytesDone = const Value.absent(),
    this.bytesTotal = const Value.absent(),
    this.state = const Value.absent(),
    this.error = const Value.absent(),
    this.overwrite = const Value.absent(),
    this.remoteMtime = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TransfersCompanion.insert({
    this.id = const Value.absent(),
    required int serverId,
    required TransferKind kind,
    required String remotePath,
    required String localPath,
    this.bytesDone = const Value.absent(),
    this.bytesTotal = const Value.absent(),
    required TransferState state,
    this.error = const Value.absent(),
    this.overwrite = const Value.absent(),
    this.remoteMtime = const Value.absent(),
    required DateTime createdAt,
  }) : serverId = Value(serverId),
       kind = Value(kind),
       remotePath = Value(remotePath),
       localPath = Value(localPath),
       state = Value(state),
       createdAt = Value(createdAt);
  static Insertable<Transfer> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? kind,
    Expression<String>? remotePath,
    Expression<String>? localPath,
    Expression<int>? bytesDone,
    Expression<int>? bytesTotal,
    Expression<String>? state,
    Expression<String>? error,
    Expression<bool>? overwrite,
    Expression<DateTime>? remoteMtime,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (kind != null) 'kind': kind,
      if (remotePath != null) 'remote_path': remotePath,
      if (localPath != null) 'local_path': localPath,
      if (bytesDone != null) 'bytes_done': bytesDone,
      if (bytesTotal != null) 'bytes_total': bytesTotal,
      if (state != null) 'state': state,
      if (error != null) 'error': error,
      if (overwrite != null) 'overwrite': overwrite,
      if (remoteMtime != null) 'remote_mtime': remoteMtime,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TransfersCompanion copyWith({
    Value<int>? id,
    Value<int>? serverId,
    Value<TransferKind>? kind,
    Value<String>? remotePath,
    Value<String>? localPath,
    Value<int>? bytesDone,
    Value<int?>? bytesTotal,
    Value<TransferState>? state,
    Value<String?>? error,
    Value<bool>? overwrite,
    Value<DateTime?>? remoteMtime,
    Value<DateTime>? createdAt,
  }) {
    return TransfersCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      kind: kind ?? this.kind,
      remotePath: remotePath ?? this.remotePath,
      localPath: localPath ?? this.localPath,
      bytesDone: bytesDone ?? this.bytesDone,
      bytesTotal: bytesTotal ?? this.bytesTotal,
      state: state ?? this.state,
      error: error ?? this.error,
      overwrite: overwrite ?? this.overwrite,
      remoteMtime: remoteMtime ?? this.remoteMtime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $TransfersTable.$converterkind.toSql(kind.value),
      );
    }
    if (remotePath.present) {
      map['remote_path'] = Variable<String>(remotePath.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (bytesDone.present) {
      map['bytes_done'] = Variable<int>(bytesDone.value);
    }
    if (bytesTotal.present) {
      map['bytes_total'] = Variable<int>(bytesTotal.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $TransfersTable.$converterstate.toSql(state.value),
      );
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (overwrite.present) {
      map['overwrite'] = Variable<bool>(overwrite.value);
    }
    if (remoteMtime.present) {
      map['remote_mtime'] = Variable<DateTime>(remoteMtime.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransfersCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('kind: $kind, ')
          ..write('remotePath: $remotePath, ')
          ..write('localPath: $localPath, ')
          ..write('bytesDone: $bytesDone, ')
          ..write('bytesTotal: $bytesTotal, ')
          ..write('state: $state, ')
          ..write('error: $error, ')
          ..write('overwrite: $overwrite, ')
          ..write('remoteMtime: $remoteMtime, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OfflineFilesTable extends OfflineFiles
    with TableInfo<$OfflineFilesTable, OfflineFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remotePathMeta = const VerificationMeta(
    'remotePath',
  );
  @override
  late final GeneratedColumn<String> remotePath = GeneratedColumn<String>(
    'remote_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mtimeMeta = const VerificationMeta('mtime');
  @override
  late final GeneratedColumn<DateTime> mtime = GeneratedColumn<DateTime>(
    'mtime',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    serverId,
    remotePath,
    localPath,
    mtime,
    size,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('remote_path')) {
      context.handle(
        _remotePathMeta,
        remotePath.isAcceptableOrUnknown(data['remote_path']!, _remotePathMeta),
      );
    } else if (isInserting) {
      context.missing(_remotePathMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('mtime')) {
      context.handle(
        _mtimeMeta,
        mtime.isAcceptableOrUnknown(data['mtime']!, _mtimeMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverId, remotePath};
  @override
  OfflineFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineFile(
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      remotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_path'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      mtime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}mtime'],
      ),
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
    );
  }

  @override
  $OfflineFilesTable createAlias(String alias) {
    return $OfflineFilesTable(attachedDatabase, alias);
  }
}

class OfflineFile extends DataClass implements Insertable<OfflineFile> {
  final int serverId;
  final String remotePath;
  final String localPath;

  /// Änderungszeit auf dem NAS beim Download; Vergleich zeigt „geändert“.
  final DateTime? mtime;
  final int size;
  const OfflineFile({
    required this.serverId,
    required this.remotePath,
    required this.localPath,
    this.mtime,
    required this.size,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<int>(serverId);
    map['remote_path'] = Variable<String>(remotePath);
    map['local_path'] = Variable<String>(localPath);
    if (!nullToAbsent || mtime != null) {
      map['mtime'] = Variable<DateTime>(mtime);
    }
    map['size'] = Variable<int>(size);
    return map;
  }

  OfflineFilesCompanion toCompanion(bool nullToAbsent) {
    return OfflineFilesCompanion(
      serverId: Value(serverId),
      remotePath: Value(remotePath),
      localPath: Value(localPath),
      mtime: mtime == null && nullToAbsent
          ? const Value.absent()
          : Value(mtime),
      size: Value(size),
    );
  }

  factory OfflineFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineFile(
      serverId: serializer.fromJson<int>(json['serverId']),
      remotePath: serializer.fromJson<String>(json['remotePath']),
      localPath: serializer.fromJson<String>(json['localPath']),
      mtime: serializer.fromJson<DateTime?>(json['mtime']),
      size: serializer.fromJson<int>(json['size']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<int>(serverId),
      'remotePath': serializer.toJson<String>(remotePath),
      'localPath': serializer.toJson<String>(localPath),
      'mtime': serializer.toJson<DateTime?>(mtime),
      'size': serializer.toJson<int>(size),
    };
  }

  OfflineFile copyWith({
    int? serverId,
    String? remotePath,
    String? localPath,
    Value<DateTime?> mtime = const Value.absent(),
    int? size,
  }) => OfflineFile(
    serverId: serverId ?? this.serverId,
    remotePath: remotePath ?? this.remotePath,
    localPath: localPath ?? this.localPath,
    mtime: mtime.present ? mtime.value : this.mtime,
    size: size ?? this.size,
  );
  OfflineFile copyWithCompanion(OfflineFilesCompanion data) {
    return OfflineFile(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      remotePath: data.remotePath.present
          ? data.remotePath.value
          : this.remotePath,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      mtime: data.mtime.present ? data.mtime.value : this.mtime,
      size: data.size.present ? data.size.value : this.size,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineFile(')
          ..write('serverId: $serverId, ')
          ..write('remotePath: $remotePath, ')
          ..write('localPath: $localPath, ')
          ..write('mtime: $mtime, ')
          ..write('size: $size')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(serverId, remotePath, localPath, mtime, size);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineFile &&
          other.serverId == this.serverId &&
          other.remotePath == this.remotePath &&
          other.localPath == this.localPath &&
          other.mtime == this.mtime &&
          other.size == this.size);
}

class OfflineFilesCompanion extends UpdateCompanion<OfflineFile> {
  final Value<int> serverId;
  final Value<String> remotePath;
  final Value<String> localPath;
  final Value<DateTime?> mtime;
  final Value<int> size;
  final Value<int> rowid;
  const OfflineFilesCompanion({
    this.serverId = const Value.absent(),
    this.remotePath = const Value.absent(),
    this.localPath = const Value.absent(),
    this.mtime = const Value.absent(),
    this.size = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineFilesCompanion.insert({
    required int serverId,
    required String remotePath,
    required String localPath,
    this.mtime = const Value.absent(),
    required int size,
    this.rowid = const Value.absent(),
  }) : serverId = Value(serverId),
       remotePath = Value(remotePath),
       localPath = Value(localPath),
       size = Value(size);
  static Insertable<OfflineFile> custom({
    Expression<int>? serverId,
    Expression<String>? remotePath,
    Expression<String>? localPath,
    Expression<DateTime>? mtime,
    Expression<int>? size,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (remotePath != null) 'remote_path': remotePath,
      if (localPath != null) 'local_path': localPath,
      if (mtime != null) 'mtime': mtime,
      if (size != null) 'size': size,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineFilesCompanion copyWith({
    Value<int>? serverId,
    Value<String>? remotePath,
    Value<String>? localPath,
    Value<DateTime?>? mtime,
    Value<int>? size,
    Value<int>? rowid,
  }) {
    return OfflineFilesCompanion(
      serverId: serverId ?? this.serverId,
      remotePath: remotePath ?? this.remotePath,
      localPath: localPath ?? this.localPath,
      mtime: mtime ?? this.mtime,
      size: size ?? this.size,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (remotePath.present) {
      map['remote_path'] = Variable<String>(remotePath.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (mtime.present) {
      map['mtime'] = Variable<DateTime>(mtime.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineFilesCompanion(')
          ..write('serverId: $serverId, ')
          ..write('remotePath: $remotePath, ')
          ..write('localPath: $localPath, ')
          ..write('mtime: $mtime, ')
          ..write('size: $size, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ServersTable servers = $ServersTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $RecentFilesTable recentFiles = $RecentFilesTable(this);
  late final $TransfersTable transfers = $TransfersTable(this);
  late final $OfflineFilesTable offlineFiles = $OfflineFilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    servers,
    favorites,
    recentFiles,
    transfers,
    offlineFiles,
  ];
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
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  required int serverId,
  required String path,
  required bool isDir,
  required DateTime addedAt,
  Value<int> rowid,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<int> serverId,
  Value<String> path,
  Value<bool> isDir,
  Value<DateTime> addedAt,
  Value<int> rowid,
});

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDir => $composableBuilder(
    column: $table.isDir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDir => $composableBuilder(
    column: $table.isDir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<bool> get isDir =>
      $composableBuilder(column: $table.isDir, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
          Favorite,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> serverId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<bool> isDir = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion(
                serverId: serverId,
                path: path,
                isDir: isDir,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int serverId,
                required String path,
                required bool isDir,
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion.insert(
                serverId: serverId,
                path: path,
                isDir: isDir,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoritesTable, Favorite>(table),
                  BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>(
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

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
      Favorite,
      PrefetchHooks Function()
    >;
typedef $$RecentFilesTableCreateCompanionBuilder =
    RecentFilesCompanion Function({
      required int serverId,
      required String path,
      required DateTime openedAt,
      Value<int> rowid,
    });
typedef $$RecentFilesTableUpdateCompanionBuilder =
    RecentFilesCompanion Function({
      Value<int> serverId,
      Value<String> path,
      Value<DateTime> openedAt,
      Value<int> rowid,
    });

class $$RecentFilesTableFilterComposer
    extends Composer<_$AppDatabase, $RecentFilesTable> {
  $$RecentFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecentFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecentFilesTable> {
  $$RecentFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecentFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecentFilesTable> {
  $$RecentFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);
}

class $$RecentFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecentFilesTable,
          RecentFile,
          $$RecentFilesTableFilterComposer,
          $$RecentFilesTableOrderingComposer,
          $$RecentFilesTableAnnotationComposer,
          $$RecentFilesTableCreateCompanionBuilder,
          $$RecentFilesTableUpdateCompanionBuilder,
          (
            RecentFile,
            BaseReferences<_$AppDatabase, $RecentFilesTable, RecentFile>,
          ),
          RecentFile,
          PrefetchHooks Function()
        > {
  $$RecentFilesTableTableManager(_$AppDatabase db, $RecentFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> serverId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentFilesCompanion(
                serverId: serverId,
                path: path,
                openedAt: openedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int serverId,
                required String path,
                required DateTime openedAt,
                Value<int> rowid = const Value.absent(),
              }) => RecentFilesCompanion.insert(
                serverId: serverId,
                path: path,
                openedAt: openedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecentFilesTable, RecentFile>(table),
                  BaseReferences<_$AppDatabase, $RecentFilesTable, RecentFile>(
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

typedef $$RecentFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecentFilesTable,
      RecentFile,
      $$RecentFilesTableFilterComposer,
      $$RecentFilesTableOrderingComposer,
      $$RecentFilesTableAnnotationComposer,
      $$RecentFilesTableCreateCompanionBuilder,
      $$RecentFilesTableUpdateCompanionBuilder,
      (
        RecentFile,
        BaseReferences<_$AppDatabase, $RecentFilesTable, RecentFile>,
      ),
      RecentFile,
      PrefetchHooks Function()
    >;
typedef $$TransfersTableCreateCompanionBuilder = TransfersCompanion Function({
  Value<int> id,
  required int serverId,
  required TransferKind kind,
  required String remotePath,
  required String localPath,
  Value<int> bytesDone,
  Value<int?> bytesTotal,
  required TransferState state,
  Value<String?> error,
  Value<bool> overwrite,
  Value<DateTime?> remoteMtime,
  required DateTime createdAt,
});
typedef $$TransfersTableUpdateCompanionBuilder = TransfersCompanion Function({
  Value<int> id,
  Value<int> serverId,
  Value<TransferKind> kind,
  Value<String> remotePath,
  Value<String> localPath,
  Value<int> bytesDone,
  Value<int?> bytesTotal,
  Value<TransferState> state,
  Value<String?> error,
  Value<bool> overwrite,
  Value<DateTime?> remoteMtime,
  Value<DateTime> createdAt,
});

class $$TransfersTableFilterComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableFilterComposer({
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

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransferKind, TransferKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesDone => $composableBuilder(
    column: $table.bytesDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesTotal => $composableBuilder(
    column: $table.bytesTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransferState, TransferState, String>
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get overwrite => $composableBuilder(
    column: $table.overwrite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get remoteMtime => $composableBuilder(
    column: $table.remoteMtime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableOrderingComposer({
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

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesDone => $composableBuilder(
    column: $table.bytesDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesTotal => $composableBuilder(
    column: $table.bytesTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get overwrite => $composableBuilder(
    column: $table.overwrite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get remoteMtime => $composableBuilder(
    column: $table.remoteMtime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransferKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get bytesDone =>
      $composableBuilder(column: $table.bytesDone, builder: (column) => column);

  GeneratedColumn<int> get bytesTotal => $composableBuilder(
    column: $table.bytesTotal,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TransferState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<bool> get overwrite =>
      $composableBuilder(column: $table.overwrite, builder: (column) => column);

  GeneratedColumn<DateTime> get remoteMtime => $composableBuilder(
    column: $table.remoteMtime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TransfersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransfersTable,
          Transfer,
          $$TransfersTableFilterComposer,
          $$TransfersTableOrderingComposer,
          $$TransfersTableAnnotationComposer,
          $$TransfersTableCreateCompanionBuilder,
          $$TransfersTableUpdateCompanionBuilder,
          (Transfer, BaseReferences<_$AppDatabase, $TransfersTable, Transfer>),
          Transfer,
          PrefetchHooks Function()
        > {
  $$TransfersTableTableManager(_$AppDatabase db, $TransfersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<TransferKind> kind = const Value.absent(),
                Value<String> remotePath = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int> bytesDone = const Value.absent(),
                Value<int?> bytesTotal = const Value.absent(),
                Value<TransferState> state = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<bool> overwrite = const Value.absent(),
                Value<DateTime?> remoteMtime = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TransfersCompanion(
                id: id,
                serverId: serverId,
                kind: kind,
                remotePath: remotePath,
                localPath: localPath,
                bytesDone: bytesDone,
                bytesTotal: bytesTotal,
                state: state,
                error: error,
                overwrite: overwrite,
                remoteMtime: remoteMtime,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int serverId,
                required TransferKind kind,
                required String remotePath,
                required String localPath,
                Value<int> bytesDone = const Value.absent(),
                Value<int?> bytesTotal = const Value.absent(),
                required TransferState state,
                Value<String?> error = const Value.absent(),
                Value<bool> overwrite = const Value.absent(),
                Value<DateTime?> remoteMtime = const Value.absent(),
                required DateTime createdAt,
              }) => TransfersCompanion.insert(
                id: id,
                serverId: serverId,
                kind: kind,
                remotePath: remotePath,
                localPath: localPath,
                bytesDone: bytesDone,
                bytesTotal: bytesTotal,
                state: state,
                error: error,
                overwrite: overwrite,
                remoteMtime: remoteMtime,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransfersTable, Transfer>(table),
                  BaseReferences<_$AppDatabase, $TransfersTable, Transfer>(
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

typedef $$TransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransfersTable,
      Transfer,
      $$TransfersTableFilterComposer,
      $$TransfersTableOrderingComposer,
      $$TransfersTableAnnotationComposer,
      $$TransfersTableCreateCompanionBuilder,
      $$TransfersTableUpdateCompanionBuilder,
      (Transfer, BaseReferences<_$AppDatabase, $TransfersTable, Transfer>),
      Transfer,
      PrefetchHooks Function()
    >;
typedef $$OfflineFilesTableCreateCompanionBuilder =
    OfflineFilesCompanion Function({
      required int serverId,
      required String remotePath,
      required String localPath,
      Value<DateTime?> mtime,
      required int size,
      Value<int> rowid,
    });
typedef $$OfflineFilesTableUpdateCompanionBuilder =
    OfflineFilesCompanion Function({
      Value<int> serverId,
      Value<String> remotePath,
      Value<String> localPath,
      Value<DateTime?> mtime,
      Value<int> size,
      Value<int> rowid,
    });

class $$OfflineFilesTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineFilesTable> {
  $$OfflineFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get mtime => $composableBuilder(
    column: $table.mtime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineFilesTable> {
  $$OfflineFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get mtime => $composableBuilder(
    column: $table.mtime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineFilesTable> {
  $$OfflineFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<DateTime> get mtime =>
      $composableBuilder(column: $table.mtime, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);
}

class $$OfflineFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineFilesTable,
          OfflineFile,
          $$OfflineFilesTableFilterComposer,
          $$OfflineFilesTableOrderingComposer,
          $$OfflineFilesTableAnnotationComposer,
          $$OfflineFilesTableCreateCompanionBuilder,
          $$OfflineFilesTableUpdateCompanionBuilder,
          (
            OfflineFile,
            BaseReferences<_$AppDatabase, $OfflineFilesTable, OfflineFile>,
          ),
          OfflineFile,
          PrefetchHooks Function()
        > {
  $$OfflineFilesTableTableManager(_$AppDatabase db, $OfflineFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> serverId = const Value.absent(),
                Value<String> remotePath = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<DateTime?> mtime = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineFilesCompanion(
                serverId: serverId,
                remotePath: remotePath,
                localPath: localPath,
                mtime: mtime,
                size: size,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int serverId,
                required String remotePath,
                required String localPath,
                Value<DateTime?> mtime = const Value.absent(),
                required int size,
                Value<int> rowid = const Value.absent(),
              }) => OfflineFilesCompanion.insert(
                serverId: serverId,
                remotePath: remotePath,
                localPath: localPath,
                mtime: mtime,
                size: size,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OfflineFilesTable, OfflineFile>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OfflineFilesTable,
                    OfflineFile
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineFilesTable,
      OfflineFile,
      $$OfflineFilesTableFilterComposer,
      $$OfflineFilesTableOrderingComposer,
      $$OfflineFilesTableAnnotationComposer,
      $$OfflineFilesTableCreateCompanionBuilder,
      $$OfflineFilesTableUpdateCompanionBuilder,
      (
        OfflineFile,
        BaseReferences<_$AppDatabase, $OfflineFilesTable, OfflineFile>,
      ),
      OfflineFile,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ServersTableTableManager get servers =>
      $$ServersTableTableManager(_db, _db.servers);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$RecentFilesTableTableManager get recentFiles =>
      $$RecentFilesTableTableManager(_db, _db.recentFiles);
  $$TransfersTableTableManager get transfers =>
      $$TransfersTableTableManager(_db, _db.transfers);
  $$OfflineFilesTableTableManager get offlineFiles =>
      $$OfflineFilesTableTableManager(_db, _db.offlineFiles);
}
