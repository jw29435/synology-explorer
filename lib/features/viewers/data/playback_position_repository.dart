import 'package:drift/drift.dart';

import '../../../core/storage/app_database.dart';
import '../../browser/domain/nas_entry.dart';

/// Wiedergabepositionen je Datei (Tabelle `playback_positions`, gemeinsam
/// mit Audio). Eine Position gilt nur, solange sich die Datei nicht ändert.
class PlaybackPositionRepository {
  PlaybackPositionRepository(this._db, this._serverId);

  final AppDatabase _db;
  final int _serverId;

  /// Am Anfang (< 10 s) und ab 95 % gibt es nichts fortzusetzen.
  static bool worthKeeping(Duration position, Duration duration) =>
      position >= const Duration(seconds: 10) && position < duration * 0.95;

  Future<Duration?> load(NasEntry entry) async {
    final row =
        await (_db.select(_db.playbackPositions)..where(
              (p) => p.serverId.equals(_serverId) & p.path.equals(entry.path),
            ))
            .getSingleOrNull();
    if (row == null || row.mtime != entry.mtime?.millisecondsSinceEpoch) {
      return null;
    }
    return Duration(milliseconds: row.positionMs);
  }

  Future<void> save(NasEntry entry, Duration position) => _db
      .into(_db.playbackPositions)
      .insertOnConflictUpdate(
        PlaybackPositionsCompanion.insert(
          serverId: _serverId,
          path: entry.path,
          mtime: Value(entry.mtime?.millisecondsSinceEpoch),
          positionMs: position.inMilliseconds,
          updatedAt: DateTime.now(),
        ),
      );

  Future<void> clear(NasEntry entry) =>
      (_db.delete(_db.playbackPositions)..where(
            (p) => p.serverId.equals(_serverId) & p.path.equals(entry.path),
          ))
          .go();
}
