import 'package:drift/drift.dart' show countAll;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../audio/presentation/playback_providers.dart';
import '../../autoupload/presentation/auto_upload_providers.dart';
import '../../browser/presentation/entry_widgets.dart';
import '../../browser/presentation/file_actions.dart';
import '../../servers/presentation/server_providers.dart';
import '../../sharing/presentation/sharing_providers.dart';
import '../../transfers/presentation/transfer_providers.dart';
import '../../viewers/presentation/viewer_providers.dart';
import '../data/settings_repository.dart';
import 'settings_providers.dart';
import 'settings_widgets.dart';

/// Screen 26: Einstellungen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final text = Theme.of(context).textTheme;
    final repo = ref.read(settingsRepositoryProvider);
    final loggedIn = ref.watch(sessionProvider) != null;
    final servers = ref.watch(serversProvider).value?.length;
    final links = loggedIn ? ref.watch(shareLinksProvider).value : null;
    final autoUpload = ref.watch(autoUploadConfigProvider).value;
    final usage = ref.watch(storageUsageProvider).value;
    final limitMb = ref.watch(cacheLimitMbProvider).value ?? 500;
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.dark;
    final language = ref.watch(localeProvider).value?.languageCode;
    final info = ref.watch(packageInfoProvider).value;

    Widget row({
      Key? key,
      required IconData? icon,
      required String title,
      Widget? trailing,
      VoidCallback? onTap,
      Color? color,
    }) => ListTile(
      key: key,
      minTileHeight: 60,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: icon == null
          ? null
          : Icon(icon, color: color ?? AppColors.textSecondary),
      title: Text(
        title,
        style: text.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Text(
          l10n.tabSettings,
          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SectionLabel(
            l10n.settingsSectionConnection,
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
          ),
          SettingsGroup(
            children: [
              row(
                key: const Key('settings-servers'),
                icon: Icons.dns_outlined,
                title: l10n.settingsServers,
                trailing: SettingsValue(servers == null ? '' : '$servers'),
                onTap: () => context.go('/servers'),
              ),
              row(
                key: const Key('settings-share-links'),
                icon: Icons.link,
                title: l10n.shareLinksTitle,
                trailing: SettingsValue(
                  links == null
                      ? ''
                      : l10n.settingsLinksActive(
                          links
                              .where((l) => !l.isExpired(DateTime.now()))
                              .length,
                        ),
                ),
                onTap: loggedIn
                    ? () => context.go('/settings/shares')
                    : () => showSnack(context, l10n.settingsNeedsServer),
              ),
              SwitchListTile(
                key: const Key('wifi-only'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                secondary: Icon(Icons.wifi, color: AppColors.textSecondary),
                title: Text(
                  l10n.settingsWifiOnly,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: ref.watch(wifiOnlyProvider).value ?? false,
                onChanged: (on) =>
                    ref.read(playbackRepositoryProvider).setWifiOnly(on),
              ),
            ],
          ),
          SectionLabel(
            l10n.settingsSectionMedia,
            padding: const EdgeInsets.fromLTRB(8, 24, 0, 8),
          ),
          SettingsGroup(
            children: [
              row(
                key: const Key('settings-auto-upload'),
                icon: Icons.photo_camera_outlined,
                title: l10n.autoUploadTitle,
                trailing: autoUpload?.enabled ?? false
                    ? SettingsValue(l10n.settingsOn, color: AppColors.success)
                    : SettingsValue(l10n.settingsOff),
                onTap: () => context.go('/settings/autoupload'),
              ),
              row(
                icon: Icons.music_note_outlined,
                title: l10n.settingsPlayback,
                trailing: SettingsValue(l10n.settingsPlaybackHint),
                onTap: () => _showPlayback(context, ref),
              ),
              row(
                key: const Key('settings-cache'),
                icon: Icons.storage_outlined,
                title: l10n.settingsCacheLimit,
                trailing: SettingsValue(
                  l10n.settingsCacheValue(
                    formatSize(limitMb << 20, locale),
                    formatSize(usage?.cache ?? 0, locale),
                  ),
                  mono: true,
                ),
                onTap: () => _showCache(context),
              ),
              row(
                icon: Icons.cloud_outlined,
                title: l10n.settingsOfflineStorage,
                trailing: SettingsValue(
                  formatSize(usage?.offline ?? 0, locale),
                  mono: true,
                ),
                onTap: () => context.go('/offline'),
              ),
            ],
          ),
          SectionLabel(
            l10n.settingsSectionApp,
            padding: const EdgeInsets.fromLTRB(8, 24, 0, 8),
          ),
          SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.settingsDesign,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final (m, label) in [
                            (ThemeMode.system, l10n.themeSystem),
                            (ThemeMode.light, l10n.themeLight),
                            (ThemeMode.dark, l10n.themeDark),
                          ])
                            ChoiceChip(
                              key: Key('theme-${m.name}'),
                              visualDensity: VisualDensity.compact,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              label: Text(label),
                              selected: mode == m,
                              onSelected: (_) => repo.write(
                                SettingsRepository.themeMode,
                                m.name,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              row(
                key: const Key('settings-language'),
                icon: null,
                title: l10n.settingsLanguage,
                trailing: SettingsValue(switch (language) {
                  'de' => l10n.languageGerman,
                  'en' => l10n.languageEnglish,
                  _ => l10n.languageSystem(
                    locale == 'de' ? l10n.languageGerman : l10n.languageEnglish,
                  ),
                }),
                onTap: () => _pickLanguage(context, ref, language),
              ),
              row(
                icon: null,
                title: l10n.settingsAbout,
                trailing: SettingsValue(
                  info == null ? '' : 'v${info.version} (${info.buildNumber})',
                  mono: true,
                ),
                onTap: () => showLicensePage(
                  context: context,
                  useRootNavigator: true,
                  applicationName: l10n.appTitle,
                  applicationVersion: info?.version,
                  applicationLegalese: l10n.aboutLegalese,
                ),
              ),
              ListTile(
                key: const Key('settings-clear-all'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  l10n.settingsClearAll,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.errorSoft,
                  ),
                ),
                trailing: Text(
                  l10n.settingsClearAllHint,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                onTap: () => _confirmClearAll(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: RadioGroup<String>(
          groupValue: current ?? '',
          onChanged: (v) => Navigator.pop(context, v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(value: '', title: Text(l10n.languageSystemOption)),
              RadioListTile(value: 'de', title: Text(l10n.languageGerman)),
              RadioListTile(value: 'en', title: Text(l10n.languageEnglish)),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    await ref
        .read(settingsRepositoryProvider)
        .write(SettingsRepository.locale, picked.isEmpty ? null : picked);
  }

  void _showCache(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (_) => const _CacheSheet(),
  );

  Future<void> _showPlayback(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final db = ref.read(appDatabaseProvider);
    final all = countAll();
    final count = await (db.selectOnly(
      db.playbackPositions,
    )..addColumns([all])).map((r) => r.read(all)!).getSingle();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.settingsPlayback,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.playbackInfo,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: count == 0
                    ? null
                    : () async {
                        await db.delete(db.playbackPositions).go();
                        if (sheet.mounted) Navigator.pop(sheet);
                        if (context.mounted) {
                          showSnack(context, l10n.playbackPositionsCleared);
                        }
                      },
                child: Text(l10n.playbackClearPositions(count)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsClearAllConfirm),
        content: Text(l10n.settingsClearAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('clear-all-confirm'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsClearAllAction),
          ),
        ],
      ),
    );
    if (!(ok ?? false) || !context.mounted) return;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await clearAllLocalData(ref);
    router.go('/servers');
    messenger.showSnackBar(SnackBar(content: Text(l10n.settingsCleared)));
  }
}

/// Slider für das Cache-Limit (200 MB – 5 GB) und „Cache leeren“.
class _CacheSheet extends ConsumerStatefulWidget {
  const _CacheSheet();

  @override
  ConsumerState<_CacheSheet> createState() => _CacheSheetState();
}

class _CacheSheetState extends ConsumerState<_CacheSheet> {
  int? _index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final saved = ref.watch(cacheLimitMbProvider).value ?? 500;
    final index =
        _index ??
        cacheLimitSteps.indexWhere((s) => s >= saved).clamp(0, 99).toInt();
    final used = ref.watch(storageUsageProvider).value?.cache ?? 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.settingsCacheLimit,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.settingsCacheValue(
                formatSize(cacheLimitSteps[index] << 20, locale),
                formatSize(used, locale),
              ),
              style: AppTheme.mono(TextStyle(color: AppColors.textSecondary)),
            ),
            Slider(
              key: const Key('cache-slider'),
              value: index.toDouble(),
              max: cacheLimitSteps.length - 1.0,
              divisions: cacheLimitSteps.length - 1,
              label: formatSize(cacheLimitSteps[index] << 20, locale),
              onChanged: (v) => setState(() => _index = v.round()),
              onChangeEnd: (v) async {
                final mb = cacheLimitSteps[v.round()];
                await ref
                    .read(settingsRepositoryProvider)
                    .write(SettingsRepository.cacheLimitMb, '$mb');
                try {
                  await ref.read(mediaCacheProvider).trim((mb << 20) * 4 ~/ 5);
                } catch (_) {
                  // Kein Cache-Verzeichnis: nichts zu verdrängen.
                }
                ref.invalidate(storageUsageProvider);
              },
            ),
            Text(
              l10n.settingsCacheHint,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () async {
                await clearCache(ref);
                if (context.mounted) showSnack(context, l10n.cacheCleared);
              },
              child: Text(l10n.cacheClear),
            ),
          ],
        ),
      ),
    );
  }
}
