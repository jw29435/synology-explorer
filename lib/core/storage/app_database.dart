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

@DriftDatabase(tables: [Servers])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
