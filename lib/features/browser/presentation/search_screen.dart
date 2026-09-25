import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import 'browser_providers.dart';
import 'entry_sheets.dart';
import 'entry_widgets.dart';

/// Screen 11: Namenssuche im Ordner [path] (rekursiv) oder mit `null` auf
/// allen Shares. Verlassen stoppt und räumt den Search-Task auf.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.path});

  final String? path;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late String? _scope = widget.path;
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = searchProvider(_scope);
    final search = ref.watch(provider);
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.textSecondary);

    String filterLabel(SearchFilter f) => switch (f) {
      SearchFilter.all => l10n.filterAll,
      SearchFilter.audio => l10n.filterAudio,
      SearchFilter.image => l10n.filterImage,
      SearchFilter.video => l10n.filterVideo,
      SearchFilter.document => l10n.filterDocument,
    };

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: l10n.close,
                icon: const Icon(Icons.close),
                onPressed: () {
                  _query.clear();
                  ref.read(provider.notifier).setQuery('');
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
            onChanged: ref.read(provider.notifier).setQuery,
            onSubmitted: (q) =>
                ref.read(provider.notifier).search(q, search.filter),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: switch (_scope) {
              final scope? => Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${l10n.searchIn(scope.substring(scope.lastIndexOf('/') + 1))} · ',
                    style: muted,
                  ),
                  InkWell(
                    onTap: () {
                      final filter = search.filter;
                      setState(() => _scope = null);
                      // Erst nach dem Build, der den neuen Provider beobachtet –
                      // sonst verwirft autoDispose ihn sofort wieder.
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => ref
                            .read(searchProvider(null).notifier)
                            .search(_query.text, filter),
                      );
                    },
                    child: Text(
                      l10n.searchWholeNas,
                      style: muted?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              null => Text(l10n.searchAllShares, style: muted),
            },
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                for (final f in SearchFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filterLabel(f)),
                      selected: search.filter == f,
                      onSelected: (_) =>
                          ref.read(provider.notifier).search(_query.text, f),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                if (search.running) ...[
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.searchRunning(search.entries.length),
                      style: muted,
                    ),
                  ),
                ] else if (search.error case final error?)
                  Expanded(
                    child: Text(
                      describeError(error, l10n),
                      style: const TextStyle(color: AppColors.errorSoft),
                    ),
                  )
                else if (search.total case final total?)
                  Expanded(
                    child: Text(
                      total > search.entries.length
                          ? l10n.searchTruncated(search.entries.length, total)
                          : l10n.searchDone(total),
                      style: muted,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: search.entries.length,
              itemBuilder: (context, i) {
                final e = search.entries[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: EntryIcon(e),
                  title: Text.rich(
                    TextSpan(children: highlight(e.name, search.query.trim())),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      _relativeParent(e.path, _scope),
                      if (e.size case final size?)
                        formatSize(size, l10n.localeName),
                    ].where((s) => s.isNotEmpty).join(' · '),
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                  onTap: () => context.push(
                    folderLocation(e.isDir ? e.path : parentPath(e.path)),
                  ),
                  onLongPress: () => showEntryActions(context, ref, e),
                );
              },
            ),
          ),
          if (search.entries.isEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(l10n.searchFooter, style: text.bodySmall),
              ),
            ),
        ],
      ),
    );
  }
}

/// Elternordner relativ zum Suchordner, z. B. `Alben/Nordlicht – Treibholz`.
String _relativeParent(String path, String? scope) {
  final parent = parentPath(path);
  if (scope != null && parent.startsWith(scope)) {
    final rest = parent.substring(scope.length);
    return rest.startsWith('/') ? rest.substring(1) : rest;
  }
  return parent.startsWith('/') ? parent.substring(1) : parent;
}

/// Hebt alle Vorkommen von [query] in [name] hervor (ohne Groß-/Klein-
/// schreibung). Bei Glob-Mustern keine Hervorhebung.
List<TextSpan> highlight(String name, String query) {
  if (query.isEmpty || query.contains(RegExp(r'[*?]'))) {
    return [TextSpan(text: name)];
  }
  final lower = name.toLowerCase();
  final q = query.toLowerCase();
  if (lower.length != name.length) return [TextSpan(text: name)];
  final spans = <TextSpan>[];
  var start = 0;
  for (var i = lower.indexOf(q); i >= 0; i = lower.indexOf(q, start)) {
    if (i > start) spans.add(TextSpan(text: name.substring(start, i)));
    spans.add(
      TextSpan(
        text: name.substring(i, i + q.length),
        style: const TextStyle(
          color: AppColors.accent,
          backgroundColor: AppColors.accentHighlight,
        ),
      ),
    );
    start = i + q.length;
  }
  if (start < name.length) spans.add(TextSpan(text: name.substring(start)));
  return spans;
}
