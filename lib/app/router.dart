import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/browser/domain/nas_entry.dart';
import '../features/audio/presentation/now_playing_screen.dart';
import '../features/audio/presentation/playback_providers.dart';
import '../features/audio/presentation/queue_screen.dart';
import '../features/browser/presentation/folder_screen.dart';
import '../features/browser/presentation/search_screen.dart';
import '../features/browser/presentation/start_screen.dart';
import '../features/browser/presentation/trash_screen.dart';
import '../features/servers/presentation/server_form_screen.dart';
import '../features/servers/presentation/server_list_screen.dart';
import '../features/servers/presentation/server_providers.dart';
import '../features/sharing/presentation/share_links_screen.dart';
import '../features/transfers/presentation/offline_screen.dart';
import '../features/transfers/presentation/transfers_screen.dart';
import '../features/viewers/presentation/viewer_screen.dart';
import '../l10n/app_localizations.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/servers',
    // Dateien (inkl. Suche, Papierkorb), Viewer und Freigabelinks nur mit
    // angemeldetem Server; Offline und Transfers gehen auch ohne.
    redirect: (context, state) {
      final location = state.matchedLocation;
      final needsSession =
          location.startsWith('/files') ||
          (location.startsWith('/view') && state.extra is! LocalView) ||
          location.startsWith('/settings/shares');
      return needsSession && ref.read(sessionProvider) == null
          ? '/servers'
          : null;
    },
    routes: [
      GoRoute(
        path: '/servers',
        builder: (context, state) => const ServerListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ServerFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => ServerFormScreen(
              serverId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      // Viewer (15–19) als Vollbild über der Shell; `extra` ist der NasEntry.
      GoRoute(
        path: '/view',
        builder: (context, state) => switch (state.extra) {
          // Offline-Datei (Screen 21): ohne Session, direkt aus der Datei.
          final LocalView view => ViewerScreen.viewerFor(
            view.entry,
            local: view.local,
          ),
          final extra => ViewerScreen(
            path: state.uri.queryParameters['path']!,
            entry: extra as NasEntry?,
          ),
        },
      ),
      // Now Playing (12) und Queue (13) als Vollbild über der Shell.
      GoRoute(
        path: '/player',
        pageBuilder: (context, state) =>
            _slideUp(state, const NowPlayingScreen()),
        routes: [
          GoRoute(
            path: 'queue',
            pageBuilder: (context, state) =>
                _slideUp(state, const QueueScreen()),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/files',
                builder: (context, state) => const StartScreen(),
                routes: [
                  // In der Shell, damit Treffer Ordner auf denselben Stack legen.
                  GoRoute(
                    path: 'search',
                    builder: (context, state) =>
                        SearchScreen(path: state.uri.queryParameters['path']),
                  ),
                  GoRoute(
                    path: 'trash',
                    builder: (context, state) => const TrashScreen(),
                  ),
                  GoRoute(
                    path: 'folder',
                    builder: (context, state) {
                      final path = state.uri.queryParameters['path']!;
                      return FolderScreen(key: ValueKey(path), path: path);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/offline',
                builder: (context, state) => const OfflineScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transfers',
                builder: (context, state) => const TransfersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const _SettingsPlaceholder(),
                routes: [
                  GoRoute(
                    path: 'shares',
                    builder: (context, state) => const ShareLinksScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Platzhalter bis Screen 26 (M5); bietet schon die Freigabelinks (23).
class _SettingsPlaceholder extends ConsumerWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabSettings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.link),
            title: Text(l10n.shareLinksTitle),
            trailing: const Icon(Icons.chevron_right),
            enabled: ref.watch(sessionProvider) != null,
            onTap: () => context.go('/settings/shares'),
          ),
          SwitchListTile(
            key: const Key('wifi-only'),
            secondary: const Icon(Icons.wifi),
            title: Text(l10n.settingsWifiOnly),
            subtitle: Text(l10n.settingsWifiOnlyHint),
            value: ref.watch(wifiOnlyProvider).value ?? false,
            onChanged: (on) =>
                ref.read(playbackRepositoryProvider).setWifiOnly(on),
          ),
        ],
      ),
    );
  }
}

/// Vollbild-Sheet, das von unten hereinfährt.
Page<void> _slideUp(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  child: child,
  transitionsBuilder: (context, animation, _, child) => SlideTransition(
    position: animation.drive(
      Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
    ),
    child: child,
  ),
);
