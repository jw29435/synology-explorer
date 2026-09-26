import 'package:drift/drift.dart';

import '../../features/transfers/domain/transfer.dart';

part 'app_database.g.dart';

/// Server-Profile ohne Secrets (die liegen im Secure Storage).
class Servers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get lanUrl => text()();
  TextColumn get externalUrl => text().nullable()();
  TextColumn get user => text()();
}

/// Lokale Favoriten je Server (Ordner und Dateien).
class Favorites extends Table {
  IntColumn get serverId => integer()();
  TextColumn get path => text()();
  BoolColumn get isDir => boolean()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {serverId, path};
}

/// Zuletzt geöffnete Dateien je Server, höchstens 50.
class RecentFiles extends Table {
  IntColumn get serverId => integer()();
  TextColumn get path => text()();
  DateTimeColumn get openedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {serverId, path};
}

/// Download-/Upload-Queue (Screen 20); überlebt App-Neustarts. Downloads
/// landen im Offline-Bereich, [localPath] ist dann die fertige Datei.
class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer()();
  TextColumn get kind => textEnum<TransferKind>()();
  TextColumn get remotePath => text()();
  TextColumn get localPath => text()();
  IntColumn get bytesDone => integer().withDefault(const Constant(0))();
  IntColumn get bytesTotal => integer().nullable()();
  TextColumn get state => textEnum<TransferState>()();
  TextColumn get error => text().nullable()();

  /// Nur Upload: vorhandene Datei überschreiben statt „ (1)“ anhängen.
  BoolColumn get overwrite => boolean().withDefault(const Constant(false))();

  /// Nur Download: Änderungszeit auf dem NAS, wandert nach [OfflineFiles].
  DateTimeColumn get remoteMtime => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Offline verfügbare Dateien (Screen 21) im App-Documents-Verzeichnis.
class OfflineFiles extends Table {
  IntColumn get serverId => integer()();
  TextColumn get remotePath => text()();
  TextColumn get localPath => text()();

  /// Änderungszeit auf dem NAS beim Download; Vergleich zeigt „geändert“.
  DateTimeColumn get mtime => dateTime().nullable()();
  IntColumn get size => integer()();

  @override
  Set<Column> get primaryKey => {serverId, remotePath};
}

@DriftDatabase(
  tables: [Servers, Favorites, RecentFiles, Transfers, OfflineFiles],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(favorites);
        await m.createTable(recentFiles);
      }
      if (from < 3) {
        await m.createTable(transfers);
        await m.createTable(offlineFiles);
      }
    },
  );
}
