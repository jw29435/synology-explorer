import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/audio/presentation/playback_providers.dart';
import '../l10n/app_localizations.dart';

/// Rahmen mit Tab-Leiste; darüber der Slot für den Mini-Player.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini-Player-Slot: 64 px, sobald etwas läuft; der Player kommt in M2.
          if (ref.watch(hasActivePlaybackProvider))
            const SizedBox(key: Key('mini-player-slot'), height: 64),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.folder_outlined),
                  label: l10n.tabFiles,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: l10n.tabOffline,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.swap_vert),
                  label: l10n.tabTransfers,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  label: l10n.tabSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
