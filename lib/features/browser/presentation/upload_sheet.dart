import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../transfers/presentation/transfer_providers.dart';
import 'file_actions.dart';

enum _UploadSource { files, media, camera, folder }

/// Screen 14: Upload-Menü aus dem FAB für [folder].
Future<void> showUploadSheet(
  BuildContext context,
  WidgetRef ref,
  String folder,
) async {
  final choice = await showModalBottomSheet<(_UploadSource, bool)>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => _UploadSheet(folder: folder),
  );
  if (choice == null || !context.mounted) return;
  final (source, overwrite) = choice;
  final l10n = AppLocalizations.of(context);
  if (source == _UploadSource.folder) {
    await createFolderIn(context, ref, folder);
    return;
  }
  final queue = ref.read(transferQueueProvider);
  try {
    final files = await _pick(source);
    for (final f in files) {
      await queue.enqueueUpload(
        localPath: f.path,
        remotePath: '$folder/${f.name}',
        overwrite: overwrite,
        size: await File(f.path).length(),
      );
    }
    if (files.isEmpty || !context.mounted) return;
    showSnack(
      context,
      l10n.uploadsQueued(files.length),
      action: SnackBarAction(
        label: l10n.tabTransfers,
        onPressed: () => context.go('/transfers'),
      ),
    );
  } catch (e) {
    if (context.mounted) showSnack(context, describeError(e, l10n));
  }
}

/// Gewählte Dateien als lokale Pfade. Liefert der Picker nur eine
/// Content-URI (Android), wird die Datei in den Cache kopiert.
Future<List<({String path, String name})>> _pick(_UploadSource source) async {
  final picker = ImagePicker();
  switch (source) {
    case _UploadSource.files:
      final files = await FilePicker.pickFiles();
      return [
        for (final f in files)
          (
            path: f.path ?? await _stage(f.name, f.readAsByteStream()),
            name: f.name,
          ),
      ];
    case _UploadSource.media:
      return [
        for (final f in await picker.pickMultipleMedia())
          (path: f.path, name: f.name),
      ];
    case _UploadSource.camera:
      final f = await picker.pickImage(source: ImageSource.camera);
      return [if (f != null) (path: f.path, name: f.name)];
    case _UploadSource.folder:
      return const [];
  }
}

// ponytail: Kopien bleiben im Cache, bis das System ihn leert; eigenes
// Aufräumen nach dem Upload, falls das Platz kostet.
Future<String> _stage(String name, Stream<List<int>> bytes) async {
  final dir = Directory(
    '${(await getApplicationCacheDirectory()).path}/uploads/'
    '${DateTime.now().microsecondsSinceEpoch}',
  );
  await dir.create(recursive: true);
  final file = File('${dir.path}/$name');
  await bytes.pipe(file.openWrite());
  return file.path;
}

class _UploadSheet extends StatefulWidget {
  const _UploadSheet({required this.folder});

  final String folder;

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  bool _overwrite = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    Widget tile(
      _UploadSource source,
      IconData icon,
      Color color,
      String title,
      String subtitle,
    ) => Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.topLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: const BorderSide(color: AppColors.textMuted),
          foregroundColor: AppColors.text,
        ),
        onPressed: () => Navigator.of(context).pop((source, _overwrite)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.uploadTitle,
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.uploadTarget(
                          widget.folder.substring(1).replaceAll('/', ' › '),
                        ),
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tile(
                    _UploadSource.files,
                    Icons.upload_file,
                    AppColors.info,
                    l10n.uploadFiles,
                    l10n.uploadFilesHint,
                  ),
                  const SizedBox(width: 12),
                  tile(
                    _UploadSource.media,
                    Icons.photo_outlined,
                    AppColors.success,
                    l10n.uploadMedia,
                    l10n.uploadMediaHint,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tile(
                    _UploadSource.camera,
                    Icons.photo_camera_outlined,
                    AppColors.errorSoft,
                    l10n.uploadCamera,
                    l10n.uploadCameraHint,
                  ),
                  const SizedBox(width: 12),
                  tile(
                    _UploadSource.folder,
                    Icons.create_new_folder_outlined,
                    AppColors.accent,
                    l10n.newFolder,
                    l10n.newFolderHint,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textMuted),
                borderRadius: BorderRadius.circular(18),
              ),
              child: SwitchListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: Text(l10n.uploadOverwrite),
                subtitle: Text(l10n.uploadOverwriteHint),
                value: _overwrite,
                onChanged: (v) => setState(() => _overwrite = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
