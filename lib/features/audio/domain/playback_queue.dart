import 'dart:math';

import '../../browser/data/file_station_list_api.dart';
import '../../browser/domain/nas_entry.dart';

/// Alle Dateien von [folder] (alle Seiten) in der Sortierung des Ordners,
/// danach die der Unterordner bis [depth] Ebenen tiefer (Tiefensuche, also
/// Album für Album).
Future<List<NasEntry>> listFilesDeep(
  FileStationListApi api,
  String folder, {
  NasSortBy sortBy = NasSortBy.name,
  bool descending = false,
  int depth = 0,
}) async {
  final entries = <NasEntry>[];
  NasPage page;
  do {
    page = await api.list(
      folder,
      sortBy: sortBy,
      descending: descending,
      offset: entries.length,
    );
    entries.addAll(page.entries);
  } while (page.entries.isNotEmpty && entries.length < page.total);
  return [
    ...entries.where((e) => !e.isDir),
    if (depth > 0)
      for (final dir in entries.where((e) => e.isDir))
        ...await listFilesDeep(
          api,
          dir.path,
          sortBy: sortBy,
          descending: descending,
          depth: depth - 1,
        ),
  ];
}

/// Wiederholen: aus, aktueller Titel, ganze Queue („Ordner“).
enum QueueRepeat { off, one, all }

/// Wiedergabeliste: Titel in Abspielreihenfolge und der aktuelle Index.
/// Unveränderlich; jede Operation liefert eine neue Queue.
class PlaybackQueue {
  const PlaybackQueue(this.tracks, this.index, {this.unshuffled});

  static const empty = PlaybackQueue([], 0);

  /// Alle Audiodateien aus [entries] in der gegebenen (Ordner-)Reihenfolge;
  /// Start bei [startPath], sonst beim ersten Titel.
  factory PlaybackQueue.fromEntries(
    Iterable<NasEntry> entries, {
    String? startPath,
  }) {
    final tracks = [
      for (final e in entries)
        if (!e.isDir && e.type == NasFileType.audio) e,
    ];
    final start = tracks.indexWhere((t) => t.path == startPath);
    return PlaybackQueue(tracks, start < 0 ? 0 : start);
  }

  final List<NasEntry> tracks;
  final int index;

  /// Reihenfolge vor dem Mischen; `null` = nicht gemischt.
  final List<NasEntry>? unshuffled;

  bool get isEmpty => tracks.isEmpty;
  bool get shuffled => unshuffled != null;
  NasEntry? get current => isEmpty ? null : tracks[index];

  /// Nächster Index nach [index]. [auto] = Titel ist zu Ende gelaufen (dann
  /// wiederholt [QueueRepeat.one] denselben Titel). `null` = Ende der Queue.
  int? next(QueueRepeat repeat, {bool auto = false}) {
    if (isEmpty) return null;
    if (auto && repeat == QueueRepeat.one) return index;
    if (index + 1 < tracks.length) return index + 1;
    return repeat == QueueRepeat.off ? null : 0;
  }

  int? previous(QueueRepeat repeat) {
    if (isEmpty) return null;
    if (index > 0) return index - 1;
    return repeat == QueueRepeat.off ? null : tracks.length - 1;
  }

  PlaybackQueue jump(int i) => PlaybackQueue(tracks, i, unshuffled: unshuffled);

  /// Mischt alle Titel außer dem aktuellen, der an den Anfang rückt.
  /// Gleicher [seed] = gleiche Reihenfolge.
  PlaybackQueue shuffle(int seed) {
    if (isEmpty) return this;
    final rest = [...tracks]..removeAt(index);
    rest.shuffle(Random(seed));
    return PlaybackQueue(
      [tracks[index], ...rest],
      0,
      unshuffled: unshuffled ?? tracks,
    );
  }

  /// Zurück zur ursprünglichen Reihenfolge; seitdem entfernte Titel bleiben
  /// weg, hinzugefügte kommen ans Ende.
  PlaybackQueue unshuffle() {
    final original = unshuffled;
    if (original == null) return this;
    final paths = {for (final t in tracks) t.path};
    final ordered = [
      for (final t in original)
        if (paths.remove(t.path)) t,
      for (final t in tracks)
        if (paths.contains(t.path)) t,
    ];
    final current = this.current;
    return PlaybackQueue(
      ordered,
      max(0, ordered.indexWhere((t) => t.path == current?.path)),
    );
  }

  /// Verschiebt den Titel an [from] nach [to] (Index nach dem Entfernen).
  PlaybackQueue move(int from, int to) {
    final list = [...tracks];
    final track = list.removeAt(from);
    list.insert(to, track);
    var current = from < index ? index - 1 : index;
    if (from == index) {
      current = to;
    } else if (to <= current) {
      current++;
    }
    return PlaybackQueue(list, current, unshuffled: unshuffled);
  }

  /// Entfernt den Titel an [i]; der aktuelle bleibt aktuell. Wird der
  /// aktuelle entfernt, rückt der nächste nach.
  PlaybackQueue removeAt(int i) {
    final list = [...tracks]..removeAt(i);
    final newIndex = i < index ? index - 1 : index;
    return PlaybackQueue(
      list,
      list.isEmpty ? 0 : min(newIndex, list.length - 1),
      unshuffled: unshuffled?.where((t) => t != tracks[i]).toList(),
    );
  }

  PlaybackQueue add(Iterable<NasEntry> more) => PlaybackQueue(
    [...tracks, ...more],
    index,
    unshuffled: unshuffled == null ? null : [...unshuffled!, ...more],
  );
}
