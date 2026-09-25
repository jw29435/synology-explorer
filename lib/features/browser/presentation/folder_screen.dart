import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../data/file_station_list_api.dart';
import '../domain/nas_entry.dart';
import 'browser_providers.dart';
import 'entry_sheets.dart';
import 'entry_widgets.dart';

/// Screens 06 (Liste) und 07 (Grid): Ordnerinhalt mit Breadcrumb,
/// Sortierung, Paging und Pull-to-Refresh.
class FolderScreen extends ConsumerWidget {
  const FolderScreen({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final folder = ref.watch(folderProvider(path));
    final grid = ref.watch(gridViewProvider);
    final selection = ref.watch(selectionProvider(path));
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              segments.last,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
            _Breadcrumb(segments: segments),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.search,
            icon: const Icon(Icons.search),
            onPressed: () => context.push(
              Uri(
                path: '/files/search',
                queryParameters: {'path': path},
              ).toString(),
            ),
          ),
          IconButton(
            tooltip: grid ? l10n.viewList : l10n.viewGrid,
            icon: Icon(grid ? Icons.view_list : Icons.grid_view),
            onPressed: () => ref.read(gridViewProvider.notifier).set(!grid),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.fabLater))),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                const _SortButton(),
                const Spacer(),
                if (selection.isNotEmpty) ...[
                  Text(l10n.selectedCount(selection.length)),
                  IconButton(
                    tooltip: l10n.close,
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        ref.read(selectionProvider(path).notifier).clear(),
                  ),
                ] else if (folder.value case final state?)
                  Text(
                    l10n.itemCount(state.total),
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(folderProvider(path).future),
              child: switch (folder) {
                AsyncValue(value: final state?) when state.entries.isEmpty =>
                  ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(child: Text(l10n.folderEmpty)),
                      ),
                    ],
                  ),
                AsyncValue(value: final state?) =>
                  grid
                      ? _FolderGrid(path: path, state: state)
                      : _FolderList(path: path, state: state),
                AsyncError(:final error) => ListView(
                  children: [
                    ErrorPanel(
                      error: error,
                      onRetry: () => ref.invalidate(folderProvider(path)),
                    ),
                  ],
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.segments});

  final List<String> segments;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.textSecondary);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        children: [
          for (final (i, segment) in segments.indexed) ...[
            if (i > 0) Icon(Icons.chevron_right, size: 16, color: style?.color),
            InkWell(
              onTap: i == segments.length - 1
                  ? null
                  : () => context.go(
                      folderLocation('/${segments.take(i + 1).join('/')}'),
                    ),
              child: Text(segment, style: style),
            ),
          ],
        ],
      ),
    );
  }
}

class _SortButton extends ConsumerWidget {
  const _SortButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sort = ref.watch(sortProvider);
    String label(NasSortBy by) => switch (by) {
      NasSortBy.name => l10n.sortName,
      NasSortBy.mtime => l10n.sortDate,
      NasSortBy.size => l10n.sortSize,
      NasSortBy.type => l10n.sortType,
    };
    final arrow = sort.descending ? Icons.arrow_downward : Icons.arrow_upward;
    return PopupMenuButton<Object>(
      tooltip: '',
      onSelected: (choice) =>
          ref.read(sortProvider.notifier).set(switch (choice) {
            // Nochmal derselbe Schlüssel dreht die Richtung um.
            NasSortBy by => (
              by: by,
              descending: by == sort.by && !sort.descending,
            ),
            final bool descending => (by: sort.by, descending: descending),
            _ => sort,
          }),
      itemBuilder: (context) => [
        for (final by in NasSortBy.values)
          PopupMenuItem(
            value: by,
            child: Row(
              children: [
                Expanded(child: Text(label(by))),
                if (by == sort.by) Icon(arrow, size: 18),
              ],
            ),
          ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
          value: false,
          checked: !sort.descending,
          child: Text(l10n.sortAscending),
        ),
        CheckedPopupMenuItem(
          value: true,
          checked: sort.descending,
          child: Text(l10n.sortDescending),
        ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textMuted),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 20),
            const SizedBox(width: 8),
            Text(label(sort.by)),
            const SizedBox(width: 4),
            Icon(arrow, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Lädt die nächste Seite, sobald das Ende der Liste näher kommt – nicht
/// nach einem Fehler (dann „Erneut versuchen“ in [_PageFooter]).
void _maybeLoadMore(WidgetRef ref, String path, FolderState state, int index) {
  if (state.hasMore &&
      state.loadMoreError == null &&
      index >= state.entries.length - 50) {
    scheduleMicrotask(() => ref.read(folderProvider(path).notifier).loadMore());
  }
}

/// Letzte Zeile/Kachel beim Paging: Spinner oder Fehler mit Retry.
class _PageFooter extends ConsumerWidget {
  const _PageFooter({required this.path, required this.state});

  final String path;
  final FolderState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = state.loadMoreError;
    if (error == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final l10n = AppLocalizations.of(context);
    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.refresh),
        label: Text(l10n.retry),
        onPressed: () =>
            ref.read(folderProvider(path).notifier).retryLoadMore(),
      ),
    );
  }
}

class _FolderList extends ConsumerWidget {
  const _FolderList({required this.path, required this.state});

  final String path;
  final FolderState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selection = ref.watch(selectionProvider(path));
    final entries = state.entries;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: entries.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        _maybeLoadMore(ref, path, state, i);
        if (i == entries.length) {
          return _PageFooter(path: path, state: state);
        }
        final e = entries[i];
        final selected = selection.contains(e.path);
        void toggle() =>
            ref.read(selectionProvider(path).notifier).toggle(e.path);
        return ListTile(
          contentPadding: const EdgeInsets.only(left: 20, right: 8),
          minVerticalPadding: 12,
          selected: selected,
          selectedTileColor: AppColors.surfaceRaised,
          leading: selected
              ? const SizedBox.square(
                  dimension: 40,
                  child: Icon(Icons.check_circle, color: AppColors.accent),
                )
              : EntryIcon(e),
          title: Text(e.name, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [
              if (e.size case final size?) formatSize(size, l10n.localeName),
              if (e.mtime case final mtime?) formatDate(mtime, l10n),
            ].join(' · '),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          trailing: IconButton(
            tooltip: l10n.more,
            icon: const Icon(Icons.more_vert),
            onPressed: () => showEntryActions(context, ref, e),
          ),
          onTap: selection.isEmpty ? () => openEntry(context, ref, e) : toggle,
          onLongPress: toggle,
        );
      },
    );
  }
}

class _FolderGrid extends ConsumerWidget {
  const _FolderGrid({required this.path, required this.state});

  final String path;
  final FolderState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectionProvider(path));
    final entries = state.entries;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: entries.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        _maybeLoadMore(ref, path, state, i);
        if (i == entries.length) {
          return _PageFooter(path: path, state: state);
        }
        final e = entries[i];
        final selected = selection.contains(e.path);
        void toggle() =>
            ref.read(selectionProvider(path).notifier).toggle(e.path);
        final ext = e.name.contains('.')
            ? e.name.substring(e.name.lastIndexOf('.') + 1).toUpperCase()
            : '';
        return GestureDetector(
          onTap: selection.isEmpty ? () => openEntry(context, ref, e) : toggle,
          onLongPress: toggle,
          child: Stack(
            fit: StackFit.expand,
            children: [
              EntryIcon(e, label: true),
              if (ext == 'HEIC' || ext == 'HEIF')
                Positioned(left: 6, top: 6, child: _Badge(ext)),
              if (e.type == NasFileType.video)
                const Center(
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.playScrim,
                    child: Icon(Icons.play_arrow, color: AppColors.text),
                  ),
                ),
              if (selected)
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent, width: 3),
                  ),
                  child: const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.check_circle, color: AppColors.accent),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.badgeScrim,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}
