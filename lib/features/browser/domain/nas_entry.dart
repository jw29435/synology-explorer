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
  }) = _NasEntry;

  /// Aus einem Eintrag von `list`/`list_share` inkl. `additional`.
  factory NasEntry.fromSyno(Map<String, dynamic> json) {
    final additional = json['additional'] as Map<String, dynamic>? ?? {};
    final name = json['name'] as String;
    final isDir = json['isdir'] as bool;
    final mtime = (additional['time'] as Map?)?['mtime'] as int?;
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
      mtime: mtime == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(mtime * 1000, isUtc: true),
      perm: perm == null
          ? null
          : (writable ? NasPerm.readWrite : NasPerm.readOnly),
    );
  }
}
