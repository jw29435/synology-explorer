import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/presentation/entry_widgets.dart';
import '../../browser/presentation/file_actions.dart';
import '../../servers/presentation/server_providers.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../data/auto_uploader.dart';
import '../domain/auto_upload_config.dart';
import 'auto_upload_providers.dart';

/// Screen 25: Auto-Upload der Kamera-Rolle in einen Ordner auf dem NAS.
class AutoUploadScreen extends ConsumerWidget {
  const AutoUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config =
        ref.watch(autoUploadConfigProvider).value ?? const AutoUploadConfig();
    final controller = ref.read(autoUploadControllerProvider.notifier);
    final titleStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w700);
    Widget toggle({
      required Key key,
      required String title,
      required String hint,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) => SwitchListTile(
      key: key,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title, style: titleStyle),
      subtitle: Text(hint, style: TextStyle(color: AppColors.textSecondary)),
      value: value,
      onChanged: onChanged,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.autoUploadTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SettingsGroup(
            highlight: config.enabled ? AppColors.accent : null,
            children: [
              SwitchListTile(
                key: const Key('auto-upload-enabled'),
                contentPadding: const EdgeInsets.all(16),
                secondary: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.accent,
                  ),
                ),
                title: Text(l10n.autoUploadHeroTitle, style: titleStyle),
                subtitle: Text(
                  l10n.autoUploadHeroSubtitle,
                  style: TextStyle(
                    color: config.enabled
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
                value: config.enabled,
                onChanged: (on) => on
                    ? _enable(context, ref, config)
                    : controller.update((c) => c.copyWith(enabled: false)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsGroup(
            children: [
              ListTile(
                key: const Key('auto-upload-target'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                title: SectionLabel(l10n.autoUploadTarget),
                subtitle: config.targetPath == null
                    ? Text(
                        l10n.autoUploadTargetNone,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      )
                    : Text(
                        config.targetPath!.substring(1),
                        style: AppTheme.mono(
                          TextStyle(color: AppColors.text, fontSize: 16),
                        ),
                      ),
                trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
                onTap: () => _pickTarget(context, ref, config),
              ),
              ListTile(
                key: const Key('auto-upload-scheme'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                title: SectionLabel(l10n.autoUploadScheme),
                subtitle: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: _schemeName(config.scheme, l10n)),
                      if (config.scheme != FolderScheme.flat)
                        TextSpan(
                          text: ' (${config.scheme.subfolder(DateTime.now())})',
                          style: AppTheme.mono(
                            TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                    ],
                  ),
                  style: TextStyle(color: AppColors.text, fontSize: 16),
                ),
                trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
                onTap: () => _pickScheme(context, ref, config.scheme),
              ),
              toggle(
                key: const Key('auto-upload-wifi'),
                title: l10n.autoUploadWifiOnly,
                hint: l10n.autoUploadWifiOnlyHint,
                value: config.wifiOnly,
                onChanged: (v) =>
                    controller.update((c) => c.copyWith(wifiOnly: v)),
              ),
              toggle(
                key: const Key('auto-upload-videos'),
                title: l10n.autoUploadVideos,
                hint: l10n.autoUploadVideosHint,
                value: config.includeVideos,
                onChanged: (v) => _setVideos(context, ref, config, v),
              ),
              toggle(
                key: const Key('auto-upload-charging'),
                title: l10n.autoUploadCharging,
                hint: l10n.autoUploadChargingHint,
                value: config.chargingOnly,
                onChanged: (v) =>
                    controller.update((c) => c.copyWith(chargingOnly: v)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatusCard(config: config),
          if (Platform.isIOS) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.textSecondary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l10n.autoUploadIosHint,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _schemeName(FolderScheme s, AppLocalizations l10n) =>
      switch (s) {
        FolderScheme.yearMonth => l10n.schemeYearMonth,
        FolderScheme.year => l10n.schemeYear,
        FolderScheme.flat => l10n.schemeFlat,
      };

  /// Einschalten: erst Fotozugriff, dann (falls noch keiner) Zielordner.
  /// Gesichert wird, was ab jetzt aufgenommen wird.
  Future<void> _enable(
    BuildContext context,
    WidgetRef ref,
    AutoUploadConfig config,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!await _ensureAccess(context, ref, videos: config.includeVideos) ||
        !context.mounted) {
      return;
    }
    if (config.targetPath == null &&
        await _pickTarget(context, ref, config) == null) {
      return;
    }
    await ref
        .read(autoUploadControllerProvider.notifier)
        .update(
          (c) => c.copyWith(
            enabled: true,
            cursor: UploadCursor(DateTime.now(), const {}),
          ),
        );
    if (context.mounted) showSnack(context, l10n.autoUploadEnabled);
  }

  Future<void> _setVideos(
    BuildContext context,
    WidgetRef ref,
    AutoUploadConfig config,
    bool on,
  ) async {
    if (on &&
        config.enabled &&
        !await _ensureAccess(context, ref, videos: true)) {
      return;
    }
    await ref
        .read(autoUploadControllerProvider.notifier)
        .update((c) => c.copyWith(includeVideos: on));
  }

  /// Fragt den Fotozugriff an; bei Ablehnung Hinweis mit Weg in die
  /// Systemeinstellungen.
  Future<bool> _ensureAccess(
    BuildContext context,
    WidgetRef ref, {
    required bool videos,
  }) async {
    final camera = ref.read(cameraRollProvider);
    if (await camera.requestAccess(videos: videos)) return true;
    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context);
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.autoUploadTitle),
        content: Text(l10n.autoUploadPermissionDenied),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.openSystemSettings),
          ),
        ],
      ),
    );
    if (open ?? false) await camera.openSettings();
    return false;
  }

  /// Zielordner auf dem angemeldeten Server wählen; Ordner ohne
  /// Schreibrecht lehnt der Picker ab.
  Future<AutoUploadConfig?> _pickTarget(
    BuildContext context,
    WidgetRef ref,
    AutoUploadConfig config,
  ) async {
    final l10n = AppLocalizations.of(context);
    final session = ref.read(sessionProvider);
    if (session == null) {
      showSnack(context, l10n.autoUploadNeedsSession);
      return null;
    }
    final serverId = session.client.profile.id!;
    final path = await pickFolder(
      context,
      title: l10n.autoUploadTarget,
      confirm: l10n.autoUploadPickConfirm,
      start: config.serverId == serverId ? config.targetPath : null,
    );
    if (path == null) return null;
    return ref
        .read(autoUploadControllerProvider.notifier)
        .update((c) => c.copyWith(serverId: serverId, targetPath: path));
  }

  Future<void> _pickScheme(
    BuildContext context,
    WidgetRef ref,
    FolderScheme current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<FolderScheme>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: RadioGroup<FolderScheme>(
          groupValue: current,
          onChanged: (s) => Navigator.pop(context, s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in FolderScheme.values)
                RadioListTile<FolderScheme>(
                  value: s,
                  title: Text(_schemeName(s, l10n)),
                  subtitle: s == FolderScheme.flat
                      ? null
                      : Text(
                          s.subfolder(DateTime.now()),
                          style: AppTheme.mono(),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    await ref
        .read(autoUploadControllerProvider.notifier)
        .update((c) => c.copyWith(scheme: picked));
  }
}

/// Status letzter Lauf, Wartendes, Summe; „Jetzt ausführen“ und Protokoll.
class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.config});

  final AutoUploadConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final runs = ref.watch(autoUploadRunsProvider).value ?? const [];
    final lastUpload = runs.where((r) => r.files > 0).firstOrNull;
    final latest = runs.firstOrNull;
    final lastCheck = ref.watch(autoUploadLastCheckProvider).value;
    final totals = ref.watch(autoUploadTotalsProvider).value;
    final running = ref.watch(autoUploadControllerProvider);
    final session = ref.watch(sessionProvider);
    final canRun =
        config.ready &&
        !running &&
        session?.client.profile.id == config.serverId;

    Widget line(Color color, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 10, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            l10n.autoUploadStatus,
            padding: const EdgeInsets.only(bottom: 12),
          ),
          if (lastUpload != null)
            line(
              lastUpload.failed == 0 ? AppColors.success : AppColors.error,
              l10n.autoUploadLastRun(
                formatRelative(lastUpload.startedAt, l10n),
                lastUpload.files,
                lastUpload.failed,
              ),
            )
          else
            line(AppColors.textMuted, l10n.autoUploadNeverRun),
          if (latest?.note case final note?)
            line(AppColors.accent, noteText(note, latest!.waiting, l10n)),
          if (running) line(AppColors.info, l10n.autoUploadRunning),
          if (lastCheck != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                l10n.autoUploadLastCheck(formatRelative(lastCheck, l10n)),
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          Text(
            l10n.autoUploadTotal(
              formatInt(totals?.files ?? 0, locale),
              formatSize(totals?.bytes ?? 0, locale),
            ),
            style: AppTheme.mono(TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('auto-upload-run'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: canRun
                      ? () => ref
                            .read(autoUploadControllerProvider.notifier)
                            .run(manual: true)
                      : null,
                  child: Text(l10n.autoUploadRunNow),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _showLog(context),
                  child: Text(l10n.autoUploadLog),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLog(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => const _LogSheet(),
  );
}

/// Text zu einem Protokoll-Grund ([AutoUploadNote]).
String noteText(String note, int waiting, AppLocalizations l10n) =>
    switch (note) {
      AutoUploadNote.noWifi => l10n.autoUploadWaitingWifi(waiting),
      AutoUploadNote.notCharging => l10n.autoUploadWaitingCharging(waiting),
      AutoUploadNote.unreachable => l10n.autoUploadNoteUnreachable(waiting),
      AutoUploadNote.otherServer => l10n.autoUploadNoteOtherServer(waiting),
      AutoUploadNote.sessionExpired => l10n.autoUploadNoteSession,
      AutoUploadNote.noWritePermission => l10n.autoUploadNoteWrite,
      AutoUploadNote.noTarget => l10n.autoUploadNoteTarget,
      AutoUploadNote.noPermission => l10n.autoUploadNotePermission,
      _ => l10n.autoUploadNoteError,
    };

class _LogSheet extends ConsumerWidget {
  const _LogSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final runs = ref.watch(autoUploadRunsProvider).value ?? const [];
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.autoUploadLog,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: runs.isEmpty
                  ? Center(child: Text(l10n.autoUploadLogEmpty))
                  : ListView(children: [for (final r in runs) _LogRow(run: r)]),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.run});

  final AutoUploadRun run;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final note = run.note;
    final ok = run.files > 0 && run.failed == 0 && note == null;
    return ListTile(
      leading: Icon(
        ok ? Icons.cloud_done_outlined : Icons.schedule,
        color: ok ? AppColors.success : AppColors.accent,
      ),
      title: Text(formatDateTime(run.startedAt, l10n)),
      subtitle: Text(
        [
          if (run.files > 0)
            l10n.autoUploadRunSummary(
              run.files,
              run.failed,
              formatSize(run.bytes, l10n.localeName),
            ),
          if (note != null) noteText(note, run.waiting, l10n),
        ].join('\n'),
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
