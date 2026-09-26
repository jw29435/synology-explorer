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

/// Bis wohin die Kamera-Rolle verarbeitet ist: Aufnahmezeit der zuletzt
/// verarbeiteten Aufnahme und alle IDs mit genau dieser Zeit (mehrere
/// Aufnahmen in derselben Sekunde).
class UploadCursor {
  const UploadCursor(this.created, this.ids);

  final DateTime created;
  final Set<String> ids;

  bool covers(CameraAsset a) =>
      a.created.isBefore(created) ||
      (a.created.isAtSameMomentAs(created) && ids.contains(a.id));

  UploadCursor advance(CameraAsset a) => a.created.isAtSameMomentAs(created)
      ? UploadCursor(created, {...ids, a.id})
      : a.created.isAfter(created)
      ? UploadCursor(a.created, {a.id})
      : this;

  Map<String, Object> toJson() => {
    'created': created.millisecondsSinceEpoch,
    'ids': [...ids],
  };

  static UploadCursor fromJson(Map<String, dynamic> json) => UploadCursor(
    DateTime.fromMillisecondsSinceEpoch(json['created'] as int),
    {...(json['ids'] as List).cast<String>()},
  );
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
