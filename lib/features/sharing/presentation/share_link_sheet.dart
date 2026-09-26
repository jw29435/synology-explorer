import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/domain/nas_entry.dart';
import '../../browser/presentation/entry_widgets.dart';
import '../../servers/presentation/server_providers.dart';
import '../domain/share_link.dart';
import 'sharing_providers.dart';

/// Screen 22: Freigabelink(s) für [entries] erstellen.
Future<void> showShareLinkSheet(
  BuildContext context,
  WidgetRef ref,
  List<NasEntry> entries,
) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => ShareLinkSheet(entries: entries),
);

/// Zufallspasswort ohne leicht verwechselbare Zeichen.
String generatePassword([int length = 10]) {
  const chars = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random.secure();
  return String.fromCharCodes([
    for (var i = 0; i < length; i++)
      chars.codeUnitAt(random.nextInt(chars.length)),
  ]);
}

class ShareLinkSheet extends ConsumerStatefulWidget {
  const ShareLinkSheet({super.key, required this.entries});

  final List<NasEntry> entries;

  @override
  ConsumerState<ShareLinkSheet> createState() => _ShareLinkSheetState();
}

class _ShareLinkSheetState extends ConsumerState<ShareLinkSheet> {
  final _password = TextEditingController();
  var _expiry = ShareExpiry.days7;
  var _obscure = true;
  var _busy = false;
  List<String>? _urls;
  Object? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final external = ref.read(sessionProvider)?.client.profile.externalUrl;
    try {
      final links = await ref
          .read(sharingApiProvider)
          .create(
            [for (final e in widget.entries) e.path],
            password: _password.text,
            expiresAt: _expiry.expiresAt(DateTime.now()),
          );
      ref.invalidate(shareLinksProvider);
      if (!mounted) return;
      setState(
        () => _urls = [for (final l in links) publicShareUrl(l.url, external)],
      );
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final entries = widget.entries;
    final external = ref.watch(sessionProvider)?.client.profile.externalUrl;
    final expiresAt = _expiry.expiresAt(DateTime.now());
    final urls = _urls;
    final locked = _busy || urls != null;

    String expiryLabel(ShareExpiry e) => switch (e) {
      ShareExpiry.day1 => l10n.expiryDay1,
      ShareExpiry.days7 => l10n.expiryDays(7),
      ShareExpiry.days30 => l10n.expiryDays(30),
      ShareExpiry.never => l10n.expiryNever,
    };

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
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
                        l10n.shareLinkTitle,
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        entries.length == 1
                            ? '${entries.single.name} · '
                                  '${parentPath(entries.single.path).substring(1)}'
                            : l10n.itemCount(entries.length),
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 16),
            SectionLabel(l10n.shareValidUntil),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final e in ShareExpiry.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        showCheckmark: false,
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(
                            expiryLabel(e),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        selected: _expiry == e,
                        onSelected: locked
                            ? null
                            : (_) => setState(() => _expiry = e),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              expiresAt == null
                  ? l10n.expiryNone
                  : l10n.expiresOn(formatDate(expiresAt, l10n)),
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SectionLabel(l10n.sharePassword),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              enabled: !locked,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(6),
                  child: TextButton(
                    onPressed: locked
                        ? null
                        : () => setState(() {
                            _password.text = generatePassword();
                            _obscure = false;
                          }),
                    child: Text(l10n.generate),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  describeError(error, l10n),
                  style: const TextStyle(color: AppColors.errorSoft),
                ),
              ),
            if (urls == null)
              FilledButton(
                onPressed: _busy ? null : _create,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.shareCreate),
              )
            else
              _Result(urls: urls),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    external == null
                        ? l10n.shareNoExternal
                        : l10n.shareExternalHint,
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

class _Result extends StatelessWidget {
  const _Result({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = urls.join('\n');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.shareCreated,
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final url in urls) SelectableText(url, style: AppTheme.mono()),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(l10n.copy),
                  // Nie ohne Tipp in die Zwischenablage (CONCEPT.md 8).
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: all));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: Text(l10n.share),
                  onPressed: () =>
                      SharePlus.instance.share(ShareParams(text: all)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
