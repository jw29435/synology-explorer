import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/presentation/entry_widgets.dart';
import '../../browser/presentation/file_actions.dart';
import '../domain/share_link.dart';
import 'sharing_providers.dart';

/// Screen 23: eigene Freigabelinks mit Ablauf-/Passwort-Badges, Löschen und
/// „Aufräumen“ für abgelaufene.
class ShareLinksScreen extends ConsumerWidget {
  const ShareLinksScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    List<ShareLink> links,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(sharingApiProvider).delete([for (final l in links) l.id]);
    } catch (e) {
      if (context.mounted) showSnack(context, describeError(e, l10n));
    }
    ref.invalidate(shareLinksProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final links = ref.watch(shareLinksProvider);
    final now = DateTime.now();
    final value = links.value ?? const <ShareLink>[];
    final expired = [
      for (final l in value)
        if (l.isExpired(now)) l,
    ];
    final active = [
      for (final l in value)
        if (!l.isExpired(now)) l,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.shareLinksTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (links.hasValue)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Text(
                  l10n.shareLinksCount(active.length, expired.length),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(shareLinksProvider.future),
        child: switch (links) {
          AsyncData() when value.isEmpty => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text(l10n.shareLinksEmpty)),
              ),
            ],
          ),
          AsyncData() => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              for (final link in active)
                _LinkCard(
                  link: link,
                  now: now,
                  onDelete: () => _delete(context, ref, [link]),
                ),
              if (expired.isNotEmpty)
                _ExpiredCard(
                  links: expired,
                  onCleanUp: () => _delete(context, ref, expired),
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  l10n.shareLinksFooter,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          AsyncError(:final error) => ListView(
            children: [
              ErrorPanel(
                error: error,
                onRetry: () => ref.invalidate(shareLinksProvider),
              ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.link,
    required this.now,
    required this.onDelete,
  });

  final ShareLink link;
  final DateTime now;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = link.daysLeft(now);
    final (label, color) = switch (days) {
      null => (l10n.expiryNone, AppColors.textSecondary),
      0 => (l10n.expiresToday, AppColors.accent),
      final d => (l10n.expiresInDays(d), AppColors.success),
    };
    final folder = parentPath(link.path);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 14),
                  child: Icon(typeIcon(link.type), color: typeColor(link.type)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        [
                          if (folder.length > 1) folder.substring(1),
                          if (link.isFolder) l10n.infoFolder,
                        ].join(' · '),
                        style: TextStyle(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.actionDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Badge(
                  icon: const Icon(Icons.circle, size: 8),
                  label: label,
                  color: color,
                ),
                if (link.hasPassword)
                  _Badge(
                    icon: const Icon(Icons.lock_outline, size: 16),
                    label: l10n.passwordBadge,
                    color: AppColors.accent,
                  ),
                Text(
                  '…/sharing/${link.id}', // l10n-ignore: URL-Pfad
                  style: AppTheme.mono(
                    TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});

  final Widget icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: IconTheme(
      data: IconThemeData(color: color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class _ExpiredCard extends StatelessWidget {
  const _ExpiredCard({required this.links, required this.onCleanUp});

  final List<ShareLink> links;
  final VoidCallback onCleanUp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textMuted),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final l in links)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text.rich(
                      TextSpan(
                        text: l.name,
                        style: TextStyle(color: AppColors.textMuted),
                        children: [
                          if (l.expiresAt case final at?)
                            TextSpan(
                              text: '\n${l10n.expiredOn(formatDate(at, l10n))}',
                            ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: onCleanUp, child: Text(l10n.cleanUp)),
        ],
      ),
    );
  }
}
