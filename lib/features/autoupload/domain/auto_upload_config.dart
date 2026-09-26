import 'dart:convert';

/// Unterordner unter dem Ziel nach Aufnahmedatum.
enum FolderScheme {
  /// `2026/09`
  yearMonth,

  /// `2026`
  year,

  /// Alles direkt ins Ziel.
  flat;

  /// Unterordner für eine Aufnahme vom [date] (ohne führenden Slash).
  String subfolder(DateTime date) => switch (this) {
    yearMonth => '${date.year}/${date.month.toString().padLeft(2, '0')}',
    year => '${date.year}',
    flat => '',
  };
}

/// Was aus der Kamera-Rolle schon verarbeitet ist.
///
/// Aufnahmen tauchen nicht in Aufnahmereihenfolge auf: Android filtert nach
/// dem Zeitpunkt, an dem die Datei sichtbar wurde (`DATE_ADDED`), meldet aber
/// die Aufnahmezeit (`DATE_TAKEN`); Nachtmodus, lange Videos und noch
/// schreibende Apps (`IS_PENDING`) werden erst später sichtbar. Deshalb
/// fragt ein Lauf ab [windowStart] (letzte Prüfung minus [lookback]) und
/// merkt sich die dort verarbeiteten IDs in [done], statt „älter als der
/// Cursor = erledigt“ anzunehmen.
class UploadCursor {
  const UploadCursor(this.since, {this.checked, this.done = const {}});

  /// Aktivierung: Ältere Aufnahmen werden nie gesichert.
  final DateTime since;

  /// Letzte vollständig abgearbeitete Abfrage.
  final DateTime? checked;

  /// Verarbeitete Asset-IDs mit dem Zeitpunkt der Verarbeitung.
  final Map<String, DateTime> done;

  // ponytail: Wer später als einen Tag nach dem letzten Lauf sichtbar wird,
  // fällt aus dem Fenster; größeres Fenster, falls das vorkommt.
  static const lookback = Duration(days: 1);

  /// Ab hier fragt der nächste Lauf die Kamera-Rolle ab.
  DateTime get windowStart {
    final from = checked?.subtract(lookback);
    return from == null || from.isBefore(since) ? since : from;
  }

  bool covers(CameraAsset a) =>
      a.created.isBefore(since) || done.containsKey(a.id);

  /// [a] ist verarbeitet (eingereiht oder inzwischen gelöscht).
  UploadCursor advance(CameraAsset a, DateTime at) =>
      UploadCursor(since, checked: checked, done: {...done, a.id: at});

  /// Abfrage bis [at] vollständig abgearbeitet. IDs, die vor dem neuen
  /// Fenster verarbeitet wurden, fragt kein Lauf mehr ab – sie fallen weg.
  UploadCursor checkedAt(DateTime at) {
    final keepFrom = at.subtract(lookback);
    return UploadCursor(
      since,
      checked: at,
      done: {
        for (final MapEntry(:key, :value) in done.entries)
          if (!value.isBefore(keepFrom)) key: value,
      },
    );
  }

  Map<String, Object> toJson() => {
    'since': since.millisecondsSinceEpoch,
    'checked': ?checked?.millisecondsSinceEpoch,
    'done': {
      for (final MapEntry(:key, :value) in done.entries)
        key: value.millisecondsSinceEpoch,
    },
  };

  static UploadCursor fromJson(Map<String, dynamic> json) {
    DateTime at(Object? ms) => DateTime.fromMillisecondsSinceEpoch(ms! as int);
    return UploadCursor(
      at(json['since'] ?? json['created']),
      checked: json['checked'] == null ? null : at(json['checked']),
      done: {
        for (final MapEntry(:key, :value)
            in ((json['done'] as Map?) ?? const {}).entries)
          key as String: at(value),
      },
    );
  }
}

/// Eine Aufnahme der Kamera-Rolle (Metadaten ohne Datei).
class CameraAsset {
  const CameraAsset(this.id, this.created, {this.isVideo = false});

  final String id;
  final DateTime created;
  final bool isVideo;
}

/// Noch nicht verarbeitete Aufnahmen, älteste zuerst.
List<CameraAsset> pendingAssets(
  Iterable<CameraAsset> assets,
  UploadCursor? cursor, {
  required bool includeVideos,
}) => [
  for (final a in assets)
    if ((includeVideos || !a.isVideo) && !(cursor?.covers(a) ?? false)) a,
]..sort((a, b) => a.created.compareTo(b.created));

/// Einstellungen des Auto-Uploads (Screen 25), als JSON in `settings`.
class AutoUploadConfig {
  const AutoUploadConfig({
    this.enabled = false,
    this.serverId,
    this.targetPath,
    this.scheme = FolderScheme.yearMonth,
    this.wifiOnly = true,
    this.includeVideos = false,
    this.chargingOnly = false,
    this.cursor,
  });

  final bool enabled;

  /// Server und Ordner, in den hochgeladen wird (z. B. `/photo/Handy`).
  final int? serverId;
  final String? targetPath;
  final FolderScheme scheme;
  final bool wifiOnly;
  final bool includeVideos;
  final bool chargingOnly;
  final UploadCursor? cursor;

  bool get ready => enabled && serverId != null && targetPath != null;

  /// Zielordner für eine Aufnahme vom [date].
  String folderFor(DateTime date) {
    final sub = scheme.subfolder(date);
    return sub.isEmpty ? targetPath! : '$targetPath/$sub';
  }

  AutoUploadConfig copyWith({
    bool? enabled,
    int? serverId,
    String? targetPath,
    FolderScheme? scheme,
    bool? wifiOnly,
    bool? includeVideos,
    bool? chargingOnly,
    UploadCursor? cursor,
  }) => AutoUploadConfig(
    enabled: enabled ?? this.enabled,
    serverId: serverId ?? this.serverId,
    targetPath: targetPath ?? this.targetPath,
    scheme: scheme ?? this.scheme,
    wifiOnly: wifiOnly ?? this.wifiOnly,
    includeVideos: includeVideos ?? this.includeVideos,
    chargingOnly: chargingOnly ?? this.chargingOnly,
    cursor: cursor ?? this.cursor,
  );

  String encode() => jsonEncode({
    'enabled': enabled,
    'serverId': ?serverId,
    'targetPath': ?targetPath,
    'scheme': scheme.name,
    'wifiOnly': wifiOnly,
    'includeVideos': includeVideos,
    'chargingOnly': chargingOnly,
    'cursor': ?cursor?.toJson(),
  });

  static AutoUploadConfig decode(String? raw) {
    if (raw == null) return const AutoUploadConfig();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return AutoUploadConfig(
      enabled: j['enabled'] as bool? ?? false,
      serverId: j['serverId'] as int?,
      targetPath: j['targetPath'] as String?,
      scheme: FolderScheme.values.asNameMap()[j['scheme']] ?? .yearMonth,
      wifiOnly: j['wifiOnly'] as bool? ?? true,
      includeVideos: j['includeVideos'] as bool? ?? false,
      chargingOnly: j['chargingOnly'] as bool? ?? false,
      cursor: switch (j['cursor']) {
        final Map<String, dynamic> c => UploadCursor.fromJson(c),
        _ => null,
      },
    );
  }
}
