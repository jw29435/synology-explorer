import 'package:drift/drift.dart';

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

@DriftDatabase(tables: [Servers, Favorites, RecentFiles])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(favorites);
        await m.createTable(recentFiles);
      }
    },
  );
}
