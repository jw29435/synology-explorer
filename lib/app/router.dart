import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/files',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          _placeholderBranch('/files', (l10n) => l10n.tabFiles),
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
