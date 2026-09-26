import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/server_profile.dart';
import 'certificate_sheet.dart';
import 'server_form_screen.dart' show ErrorBox;
import 'server_providers.dart';

/// Screen 01: Server wählen. Beim App-Start wird still mit dem zuletzt
/// genutzten Server verbunden, wenn dafür eine SID vorliegt.
class ServerListScreen extends ConsumerStatefulWidget {
  const ServerListScreen({super.key, this.sessionExpired = false});

  /// Hierher umgeleitet, weil der stille Re-Login scheiterte.
  final bool sessionExpired;

  @override
  ConsumerState<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends ConsumerState<ServerListScreen> {
  int? _connecting;

  Future<void> _open(ServerProfile profile) async {
    final active = ref.read(sessionProvider);
    if (active != null &&
        active.client.profile.id == profile.id &&
        active.isLoggedIn) {
      // Aus der Shell geöffnet: zurück an die alte Stelle.
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/files');
      }
      return;
    }
    setState(() => _connecting = profile.id);
    try {
      final session = await withCertificateTrust(
        context,
        ref,
        () => ref.read(serverRepositoryProvider).connect(profile),
      );
      if (session == null || !mounted) return;
      if (!session.isLoggedIn) {
        session.client.close();
        context.push('/servers/${profile.id}');
        return;
      }
      await ref.read(sessionProvider.notifier).activate(session);
      if (mounted) context.go('/files');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeError(e, AppLocalizations.of(context)))),
      );
    } finally {
      if (mounted) setState(() => _connecting = null);
    }
  }

  Future<void> _manage(ServerProfile profile, bool active) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.serverEdit),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            if (active)
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l10n.serverLogout),
                onTap: () => Navigator.pop(context, 'logout'),
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.errorSoft),
              title: Text(
                l10n.serverDelete,
                style: TextStyle(color: AppColors.errorSoft),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'edit':
        context.push('/servers/${profile.id}');
      case 'logout':
        await ref.read(sessionProvider.notifier).logout();
        // Unter einem gepushten 01 liegt die Shell der alten Session.
        if (mounted) context.go('/servers');
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(l10n.serverDeleteConfirm(profile.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  l10n.serverDelete,
                  style: TextStyle(color: AppColors.errorSoft),
                ),
              ),
            ],
          ),
        );
        if (ok != true) return;
        if (active) await ref.read(sessionProvider.notifier).logout();
        await ref.read(serverRepositoryProvider).remove(profile.id!);
        ref.invalidate(serversProvider);
        if (active && mounted) context.go('/servers');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(startupProvider, (_, next) {
      if (next.value == true) context.go('/files');
    });
    if (ref.watch(startupProvider).isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final servers = ref.watch(serversProvider).value ?? const [];
    final session = ref.watch(sessionProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Text(
          l10n.serversTitle,
          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: l10n.serverAdd,
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/servers/new'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          if (widget.sessionExpired && session == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ErrorBox(l10n.errorSessionExpired),
            ),
          if (servers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.serversEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          for (final p in servers)
            _ServerCard(
              profile: p,
              activeUrl: session?.client.profile.id == p.id
                  ? session?.client.activeUrl
                  : null,
              connecting: _connecting == p.id,
              onTap: _connecting == null ? () => _open(p) : null,
              onLongPress: () => _manage(p, session?.client.profile.id == p.id),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.textSecondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.serverInfo,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.serverAdd),
            onPressed: () => context.push('/servers/new'),
          ),
        ),
      ),
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    required this.profile,
    required this.activeUrl,
    required this.connecting,
    required this.onTap,
    required this.onLongPress,
  });

  final ServerProfile profile;

  /// Adresse der aktiven Session, sonst `null`.
  final Uri? activeUrl;
  final bool connecting;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final url = activeUrl;
    final active = url != null;
    final viaLan = url == Uri.parse(profile.lanUrl);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.accentSurface
                            : AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.dns_outlined,
                        color: active
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            profile.user,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (connecting)
                      const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: active ? AppColors.success : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    if (url != null) ...[
                      Text(
                        l10n.serverConnectedVia(
                          viaLan ? l10n.viaLan : l10n.viaExternal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          url.hasPort ? '${url.host}:${url.port}' : url.host,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.mono(
                            TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ] else
                      Text(
                        l10n.serverNotConnected,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
