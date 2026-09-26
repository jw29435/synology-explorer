import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/storage/app_database.dart';

void main() {
  test('v6 → v7: Favoriten bekommen name, remote, broken', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw
          ..execute(
            'CREATE TABLE favorites (server_id INTEGER NOT NULL, '
            'path TEXT NOT NULL, is_dir INTEGER NOT NULL, '
            'added_at INTEGER NOT NULL, PRIMARY KEY (server_id, path))',
          )
          ..execute("INSERT INTO favorites VALUES (1, '/music/Alt', 1, 0)")
          ..execute('PRAGMA user_version = 6'),
      ),
    );
    addTearDown(db.close);

    final rows = await db.select(db.favorites).get();
    expect(rows.single.path, '/music/Alt');
    expect(rows.single.name, isNull);
    expect(rows.single.remote, isFalse);
    expect(rows.single.broken, isFalse);
    await db
        .into(db.favorites)
        .insert(
          FavoritesCompanion.insert(
            serverId: 1,
            path: '/music/Neu',
            isDir: true,
            addedAt: DateTime(2026),
            remote: const Value(true),
          ),
        );
  });
}
