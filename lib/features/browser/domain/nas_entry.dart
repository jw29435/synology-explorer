import 'package:freezed_annotation/freezed_annotation.dart';

part 'nas_entry.freezed.dart';

enum NasFileType {
  folder,
  audio,
  image,
  video,
  pdf,
  text,
  docx,
  other;

  static const _byExtension = {
    'mp3': audio,
    'm4a': audio,
    'aac': audio,
    'flac': audio,
    'ogg': audio,
    'opus': audio,
    'wav': audio,
    'jpg': image,
    'jpeg': image,
    'png': image,
    'gif': image,
    'webp': image,
    'heic': image,
    'heif': image,
    'mp4': video,
    'm4v': video,
    'mkv': video,
    'mov': video,
    'avi': video,
    'webm': video,
    'pdf': pdf,
    'txt': text,
    'md': text,
    'markdown': text,
    'log': text,
    'csv': text,
    'json': text,
    'xml': text,
    'yaml': text,
    'yml': text,
    'ini': text,
    'sh': text,
    'py': text,
    'dart': text,
    'js': text,
    'ts': text,
    'html': text,
    'css': text,
    'sql': text,
    'docx': docx,
  };

  /// Alle Endungen der Typen [types], z. B. für den Such-Filter.
  static List<String> extensionsOf(Set<NasFileType> types) => [
    for (final MapEntry(:key, :value) in _byExtension.entries)
      if (types.contains(value)) key,
  ];

  /// Typ aus der Dateiendung, ohne Groß-/Kleinschreibung.
  static NasFileType fromName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 1) return other;
    return _byExtension[name.substring(dot + 1).toLowerCase()] ?? other;
  }
}

enum NasPerm { readOnly, readWrite }

/// Datei, Ordner oder Shared Folder auf dem NAS.
@freezed
abstract class NasEntry with _$NasEntry {
  const factory NasEntry({
    required String path,
    required String name,
    required bool isDir,
    required NasFileType type,
    int? size,
    DateTime? mtime,
    NasPerm? perm,

    /// Nur bei `getinfo` (Info-Sheet) befüllt.
    DateTime? crtime,
    String? owner,
    String? group,
    int? posix,
  }) = _NasEntry;

  /// Aus einem Eintrag von `list`/`list_share` inkl. `additional`.
  factory NasEntry.fromSyno(Map<String, dynamic> json) {
    final additional = json['additional'] as Map<String, dynamic>? ?? {};
    final name = json['name'] as String;
    final isDir = json['isdir'] as bool;
    final time = additional['time'] as Map?;
    final owner = additional['owner'] as Map?;
    final perm = additional['perm'] as Map?;
    // Shares melden share_right, Dateien/Ordner eine ACL.
    final writable =
        perm?['share_right'] == 'RW' ||
        (perm?['acl'] as Map?)?['write'] == true;
    return NasEntry(
      path: json['path'] as String,
      name: name,
      isDir: isDir,
      type: isDir ? NasFileType.folder : NasFileType.fromName(name),
      size: isDir ? null : additional['size'] as int?,
      mtime: _time(time?['mtime']),
      perm: perm == null
          ? null
          : (writable ? NasPerm.readWrite : NasPerm.readOnly),
      crtime: _time(time?['crtime']),
      owner: owner?['user'] as String?,
      group: owner?['group'] as String?,
      posix: perm?['posix'] as int?,
    );
  }

  static DateTime? _time(Object? seconds) => seconds is int
      ? DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true)
      : null;
}
