import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/network/syno_exception.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../transfers/presentation/transfer_providers.dart';
import '../domain/nas_entry.dart';
import '../domain/recycle.dart';
import 'browser_providers.dart';
import 'entry_widgets.dart';

/// Datei-Aktionen für Sheet 09 und die Auswahl-Leiste 08: Umbenennen,
/// Verschieben/Kopieren, Löschen, Neuer Ordner, Download.

/// Mit [action] bliebe die SnackBar sonst stehen (`persist`); die Aktion
/// darf den [context] nicht mehr brauchen – er ist beim Tippen oft schon weg.
void showSnack(BuildContext context, String text, {SnackBarAction? action}) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), action: action, persist: false),
      );

/// Favorit umschalten: Ordner auf dem NAS (dieselben wie in DS File),
/// Dateien nur lokal – DSM führt Datei-Favoriten nur als `broken`.
Future<void> toggleFavorite(
  BuildContext context,
  WidgetRef ref,
  NasEntry entry,
  bool favorite,
) async {
  if (!entry.isDir) {
    return ref
        .read(localLibraryProvider)
        .setFavorite(ref.read(serverIdProvider), entry, favorite);
  }
  return setNasFavorite(context, ref, entry, favorite);
}

/// Favorit auf dem NAS setzen bzw. entfernen – auch einen kaputten, dessen
/// Ziel fehlt. Fehler als Snackbar; der Cache bleibt dann, wie er war.
Future<void> setNasFavorite(
  BuildContext context,
  WidgetRef ref,
  NasEntry entry,
  bool favorite,
) async {
  final l10n = AppLocalizations.of(context);
  try {
    await ref
        .read(localLibraryProvider)
        .setFolderFavorite(
          ref.read(serverIdProvider),
          ref.read(favoriteApiProvider),
          entry,
          favorite,
        );
  } on SynoException catch (e) {
    if (!context.mounted) return;
    showSnack(
      context,
      e is SynoPermissionDenied
          ? l10n.favoritesUnavailable
          : describeError(e, l10n),
    );
  }
}

/// Lädt die Ordner neu, die sich durch eine Aktion geändert haben.
void refreshFolders(WidgetRef ref, Iterable<String> folders) {
  for (final f in folders.toSet()) {
    ref.invalidate(folderProvider(f));
  }
}

/// Name abfragen (Umbenennen, Neuer Ordner); markiert den Namen ohne Endung.
Future<String?> askName(
  BuildContext context, {
  required String title,
  required String action,
  String initial = '',
}) => showDialog<String>(
  context: context,
  useRootNavigator: true,
  builder: (_) => _NameDialog(title: title, action: action, initial: initial),
);

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.action,
    required this.initial,
  });

  final String title;
  final String action;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initial.lastIndexOf('.') > 0
          ? widget.initial.lastIndexOf('.')
          : widget.initial.length,
    );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final name = _controller.text.trim();
    final error = name.isEmpty
        ? l10n.validationRequired
        : (name.contains('/') || name == '.' || name == '..')
        ? l10n.validationName
        : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(name == widget.initial ? null : name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.action)),
      ],
    );
  }
}

Future<void> renameEntry(
  BuildContext context,
  WidgetRef ref,
  NasEntry entry,
) async {
  final l10n = AppLocalizations.of(context);
  final api = ref.read(fileOpsApiProvider);
  final name = await askName(
    context,
    title: l10n.actionRename,
    action: l10n.actionRename,
    initial: entry.name,
  );
  if (name == null) return;
  try {
    await api.rename(entry.path, name);
    refreshFolders(ref, [parentPath(entry.path)]);
  } catch (e) {
    if (context.mounted) showSnack(context, describeError(e, l10n));
  }
}

Future<void> createFolderIn(
  BuildContext context,
  WidgetRef ref,
  String parent,
) async {
  final l10n = AppLocalizations.of(context);
  final api = ref.read(fileOpsApiProvider);
  final name = await askName(
    context,
    title: l10n.newFolder,
    action: l10n.create,
  );
  if (name == null) return;
  try {
    await api.createFolder(parent, name);
    refreshFolders(ref, [parent]);
  } catch (e) {
    if (context.mounted) showSnack(context, describeError(e, l10n));
  }
}

Future<void> downloadEntries(
  BuildContext context,
  WidgetRef ref,
  List<NasEntry> entries,
) async {
  final l10n = AppLocalizations.of(context);
  final router = GoRouter.of(context);
  try {
    final count = await enqueueDownloads(ref, entries);
    if (!context.mounted) return;
    showSnack(
      context,
      l10n.downloadsQueued(count),
      action: SnackBarAction(
        label: l10n.tabTransfers,
        onPressed: () => router.go('/transfers'),
      ),
    );
  } catch (e) {
    if (context.mounted) showSnack(context, describeError(e, l10n));
  }
}

/// Verschieben ([move]) bzw. Kopieren nach einem Ordner aus dem Picker.
Future<bool> copyMoveEntries(
  BuildContext context,
  WidgetRef ref,
  List<NasEntry> entries, {
  required bool move,
}) async {
  final l10n = AppLocalizations.of(context);
  final api = ref.read(fileOpsApiProvider);
  final dest = await pickFolder(
    context,
    title: move ? l10n.moveTo : l10n.copyTo,
    confirm: move ? l10n.moveHere : l10n.copyHere,
    start: parentPath(entries.first.path),
    sources: [for (final e in entries) e.path],
  );
  if (dest == null || !context.mounted) return false;
  final paths = [for (final e in entries) e.path];
  final done = await runWithProgress(
    context,
    move ? l10n.moving(entries.length) : l10n.copying(entries.length),
    pollTask(
      start: () => api.copyMoveStart(paths, dest, move: move),
      status: api.copyMoveStatus,
      stop: api.copyMoveStop,
    ),
  );
  refreshFolders(ref, [dest, if (move) ...paths.map(parentPath)]);
  return done;
}

/// Löschen mit Bestätigung und Hinweis, ob der Share einen Papierkorb hat.
Future<bool> deleteEntries(
  BuildContext context,
  WidgetRef ref,
  List<NasEntry> entries,
) async {
  final l10n = AppLocalizations.of(context);
  final api = ref.read(fileOpsApiProvider);
  final share = shareOf(entries.first.path);
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (context) => AlertDialog(
      title: Text(
        entries.length == 1
            ? l10n.deleteConfirmOne(entries.single.name)
            : l10n.deleteConfirmMany(entries.length),
      ),
      content: Consumer(
        builder: (context, ref, _) =>
            Text(switch (ref.watch(recycleBinProvider(share))) {
              AsyncData(value: RecycleBin.available) => l10n.deleteToRecycle,
              AsyncData(value: RecycleBin.missing) => l10n.deleteNoRecycle,
              AsyncData() || AsyncError() => l10n.deleteRecycleUnknown,
              _ => '…',
            }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.text,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.actionDeleteShort),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  final paths = [for (final e in entries) e.path];
  final done = await runWithProgress(
    context,
    l10n.deleting(entries.length),
    pollTask(
      start: () => api.deleteStart(paths),
      status: api.deleteStatus,
      stop: api.deleteStop,
    ),
  );
  refreshFolders(ref, [...paths.map(parentPath), recycleFolder(share)]);
  return done;
}

/// Zeigt [task] als Dialog mit Fortschritt und „Abbrechen“ (stoppt den Task).
/// Liefert `true`, wenn er fertig wurde; Fehler erscheinen als SnackBar.
Future<bool> runWithProgress(
  BuildContext context,
  String title,
  Stream<double?> task,
) async {
  final result = await showDialog<Object>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (_) => _TaskDialog(title: title, task: task),
  );
  if (result == true) return true;
  if (result is! bool && result != null && context.mounted) {
    showSnack(context, describeError(result, AppLocalizations.of(context)));
  }
  return false;
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({required this.title, required this.task});

  final String title;
  final Stream<double?> task;

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late final StreamSubscription<double?> _sub;
  double? _progress;

  /// Nach einem Fehler meldet der Stream noch `done`; der Dialog bleibt
  /// während der Schließ-Animation `mounted` – nur einmal poppen.
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.task.listen(
      (p) => setState(() => _progress = p),
      onError: (Object e) => _close(e),
      onDone: () => _close(true),
    );
  }

  void _close(Object result) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Zurück bräche den Task still (ggf. halb) ab: nur über „Abbrechen“.
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: _progress),
            if (_progress case final p?) ...[
              const SizedBox(height: 8),
              Text('${(p * 100).round()} %', style: AppTheme.mono()),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              unawaited(_sub.cancel());
              _close(false);
            },
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

/// Ordner-Picker als Sheet: Shares → Unterordner, ab [start] (`null` = Liste
/// der Shares). Nicht wählbar sind die Share-Ebene, die Quellen selbst,
/// Ordner darin und ihr bisheriger Ordner sowie Ordner ohne Schreibrecht.
Future<String?> pickFolder(
  BuildContext context, {
  required String title,
  required String confirm,
  required String? start,
  List<String> sources = const [],
}) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _FolderPickerSheet(
    title: title,
    confirm: confirm,
    start: start,
    sources: sources,
  ),
);

/// Ob [dest] als Ziel für [sources] taugt.
bool isValidDestination(String dest, List<String> sources) => !sources.any(
  (s) => dest == s || dest.startsWith('$s/') || dest == parentPath(s),
);

class _FolderPickerSheet extends ConsumerStatefulWidget {
  const _FolderPickerSheet({
    required this.title,
    required this.confirm,
    required this.start,
    required this.sources,
  });

  final String title;
  final String confirm;
  final String? start;
  final List<String> sources;

  @override
  ConsumerState<_FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends ConsumerState<_FolderPickerSheet> {
  /// `null` = Liste der Shares.
  late String? _path = widget.start;

  /// Rechte des aktuellen Ordners, sobald bekannt (aus der Liste darüber).
  NasPerm? _perm;

  /// Eine Ebene hoch; von der Share-Ebene zur Liste der Shares.
  void _up() => setState(() {
    final path = _path!;
    _path = path.lastIndexOf('/') == 0 ? null : parentPath(path);
    _perm = null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final path = _path;
    final AsyncValue<List<NasEntry>> folders = path == null
        ? ref.watch(sharesProvider)
        : ref
              .watch(folderProvider(path))
              .whenData((s) => [...s.entries.where((e) => e.isDir)]);
    final writable = _perm != NasPerm.readOnly;
    final valid =
        path != null && writable && isValidDestination(path, widget.sources);
    // Zurück-Geste wie der Zurück-Pfeil; erst auf der Share-Liste zu.
    return PopScope(
      canPop: path == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _up();
      },
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 8, right: 8),
                leading: IconButton(
                  tooltip: l10n.back,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: path == null ? null : _up,
                ),
                title: Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  path?.substring(1) ?? l10n.sectionShares,
                  style: AppTheme.mono(
                    TextStyle(color: AppColors.textSecondary),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: l10n.close,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: switch (folders) {
                  AsyncData(:final value) when value.isEmpty => Center(
                    child: Text(l10n.noSubfolders),
                  ),
                  AsyncData(:final value) => ListView(
                    children: [
                      for (final f in value)
                        ListTile(
                          leading: const Icon(
                            Icons.folder_outlined,
                            color: AppColors.accent,
                          ),
                          title: Text(f.name),
                          trailing: const Icon(Icons.chevron_right),
                          enabled: !widget.sources.contains(f.path),
                          onTap: () => setState(() {
                            _path = f.path;
                            _perm = f.perm;
                          }),
                        ),
                    ],
                  ),
                  AsyncError(:final error) => Center(
                    child: Text(describeError(error, l10n)),
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
              if (!writable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    l10n.noWritePermission,
                    style: TextStyle(color: AppColors.errorSoft),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: valid
                      ? () => Navigator.of(context).pop(path)
                      : null,
                  child: Text(widget.confirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
