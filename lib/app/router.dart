import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/browser/presentation/folder_screen.dart';
import '../features/browser/presentation/search_screen.dart';
import '../features/browser/presentation/start_screen.dart';
import '../features/servers/presentation/server_form_screen.dart';
import '../features/servers/presentation/server_list_screen.dart';
import '../features/servers/presentation/server_providers.dart';
import '../l10n/app_localizations.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/servers',
    // Dateien (inkl. Suche) nur mit angemeldetem Server.
    redirect: (context, state) {
      final needsSession = state.matchedLocation.startsWith('/files');
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
          _placeholderBranch('/offline', (l10n) => l10n.tabOffline),
          _placeholderBranch('/transfers', (l10n) => l10n.tabTransfers),
          _placeholderBranch('/settings', (l10n) => l10n.tabSettings),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _placeholderBranch(
  String path,
  String Function(AppLocalizations) title,
) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      builder: (context, state) => Scaffold(
        body: Center(child: Text(title(AppLocalizations.of(context)))),
      ),
    ),
  ],
);
