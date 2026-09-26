import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

import '../domain/auto_upload_config.dart';

/// Kamera-Rolle über photo_manager. Zugriff wird nur für den Auto-Upload
/// angefragt (CONCEPT.md Abschnitt 8).
class CameraRoll {
  const CameraRoll();

  static PermissionRequestOption _option(bool videos) =>
      PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: videos ? RequestType.common : RequestType.image,
          // Ohne diese Berechtigung entfernt Android die GPS-Daten aus den
          // Originalen – die Sicherung wäre nicht vollständig.
          mediaLocation: true,
        ),
      );

  /// Fragt den Zugriff an (Systemdialog); `true` bei vollem Zugriff.
  Future<bool> requestAccess({required bool videos}) async =>
      (await PhotoManager.requestPermissionExtend(
        requestOption: _option(videos),
      )).isAuth;

  /// Zugriff ohne Dialog prüfen (Hintergrund).
  Future<bool> hasAccess({required bool videos}) async =>
      (await PhotoManager.getPermissionState(requestOption: _option(videos)))
          .isAuth;

  Future<void> openSettings() => PhotoManager.openSetting();

  /// Aufnahmen seit [since] (einschließlich), älteste zuerst. Auf Android nur
  /// aus `DCIM/` (Kamera), nicht Screenshots oder Messenger-Bilder.
  Future<List<CameraAsset>> since(DateTime? since, {required bool videos}) =>
      _entities(since, videos: videos).then(
        (list) => [
          for (final e in list)
            CameraAsset(
              e.id,
              e.createDateTime,
              isVideo: e.type == AssetType.video,
            ),
        ],
      );

  Future<List<AssetEntity>> _entities(
    DateTime? since, {
    required bool videos,
  }) async {
    final type = videos ? RequestType.common : RequestType.image;
    final filter = FilterOptionGroup(
      createTimeCond: DateTimeCond(
        min: since ?? DateTime.fromMillisecondsSinceEpoch(0),
        max: DateTime.now().add(const Duration(days: 1)),
      ),
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: true)],
    );
    final count = await PhotoManager.getAssetCount(
      filterOption: filter,
      type: type,
    );
    final out = <AssetEntity>[];
    for (var start = 0; start < count; start += 200) {
      out.addAll(
        await PhotoManager.getAssetListRange(
          start: start,
          end: start + 200 > count ? count : start + 200,
          filterOption: filter,
          type: type,
        ),
      );
    }
    return [
      for (final e in out)
        if (!Platform.isAndroid ||
            (e.relativePath ?? 'DCIM/').startsWith('DCIM/'))
          e,
    ];
  }

  /// Originaldatei und Dateiname einer Aufnahme; `null`, wenn sie inzwischen
  /// gelöscht wurde.
  Future<({File file, String name})?> original(String id) async {
    final entity = await AssetEntity.fromId(id);
    final file = await entity?.originFile;
    if (entity == null || file == null) return null;
    final title = await entity.titleAsync;
    return (
      file: file,
      name: title.isEmpty ? file.uri.pathSegments.last : title,
    );
  }
}
