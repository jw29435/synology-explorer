import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/settings_providers.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class SynologyExplorerApp extends ConsumerWidget {
  const SynologyExplorerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.dark;
    final dark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    AppColors.neutrals = dark ? Neutrals.dark : Neutrals.light;
    return MaterialApp.router(
      // Neuer Key beim Designwechsel: Alle Widgets bauen neu und lesen die
      // neutralen Töne aus AppColors neu (die Route bleibt erhalten).
      key: ValueKey(dark),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: ref.watch(localeProvider).value,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
