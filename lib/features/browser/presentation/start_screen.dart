import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../servers/presentation/server_providers.dart';
import '../domain/nas_entry.dart';
import 'browser_providers.dart';
import 'entry_sheets.dart';
import 'entry_widgets.dart';

/// Screen 05: Shared Folders, Favoriten, Zuletzt geöffnet.
class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();
    final profile = session.client.profile;
    final viaLan = session.client.activeUrl == Uri.parse(profile.lanUrl);
    final shares = ref.watch(sharesProvider);
    final favorites = ref.watch(favoritesProvider).value ?? const [];
    // Favoriten des NAS-Kontos nachladen, solange 05 offen ist.
    ref.watch(favoritesSyncProvider);
    final recent = ref.watch(recentProvider).value ?? const [];
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Row(
              children: [
                const Icon(Icons.circle, size: 8, color: AppColors.success),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.serverStatus(
                      viaLan ? l10n.viaLan : l10n.viaExternal,
                      profile.user,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.search,
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/files/search'),
          ),
          IconButton(
            tooltip: l10n.trashTitle,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => context.push('/files/trash'),
          ),
          IconButton(
            tooltip: l10n.switchServer,
            icon: const Icon(Icons.dns_outlined),
            // push: 01 bekommt einen Zurückknopf, der Ordner-Stack bleibt.
            onPressed: () => context.push('/servers'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.refresh(sharesProvider.future),
          // Ohne NAS bleiben die Favoriten aus dem Cache stehen.
          ref.refresh(favoritesSyncProvider.future).catchError((_) {}),
        ]),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            SectionLabel(
              l10n.sectionShares,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            ),
            ...switch (shares) {
              AsyncData(value: []) => [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    l10n.sharesEmpty,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
              AsyncData(:final value) => [
                for (final share in value)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    leading: const Icon(
                      Icons.folder_outlined,
                      color: AppColors.accent,
                    ),
                    title: Text(share.name),
                    subtitle: share.perm == null
                        ? null
                        : Text(
                            share.perm == NasPerm.readWrite
                                ? l10n.permReadWrite
                                : l10n.permReadOnly,
                          ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openEntry(context, ref, share),
                    onLongPress: () => showEntryActions(context, ref, share),
                  ),
              ],
              AsyncError(:final error) => [
                ErrorPanel(
                  error: error,
                  onRetry: () => ref.invalidate(sharesProvider),
                ),
              ],
              _ => [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            },
            if (favorites.isNotEmpty) ...[
              SectionLabel(
                l10n.sectionFavorites,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              ),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final (:entry, :name, :broken) = favorites[i];
                    final chip = ActionChip(
                      avatar: Icon(
                        Icons.star,
                        color: broken ? AppColors.textMuted : AppColors.accent,
                      ),
                      label: Text(name),
                      // Ordner öffnen 06, Dateien Viewer bzw. Player.
                      onPressed: broken
                          ? null
                          : () => openEntry(context, ref, entry),
                    );
                    return broken
                        ? Tooltip(message: l10n.favoriteBroken, child: chip)
                        : chip;
                  },
                ),
              ),
            ],
            if (recent.isNotEmpty) ...[
              SectionLabel(
                l10n.sectionRecent,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              ),
              for (final (:entry, :openedAt) in recent)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: Icon(
                    typeIcon(entry.type),
                    color: typeColor(entry.type),
                  ),
                  title: Text(entry.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${parentPath(entry.path).substring(1)} · '
                    '${formatRelative(openedAt, l10n)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Die Datei selbst öffnen (Viewer bzw. Ordner abspielen).
                  onTap: () => openEntry(context, ref, entry),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
