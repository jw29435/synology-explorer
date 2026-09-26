import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/settings_providers.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class NuvoExplorerApp extends ConsumerWidget {
  const NuvoExplorerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.dark;
    final dark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    final neutrals = dark ? Neutrals.dark : Neutrals.light;
    if (!identical(AppColors.neutrals, neutrals)) {
      AppColors.neutrals = neutrals;
      // Widgets, die AppColors direkt lesen, hängen nicht am Theme: nach
      // dem Wechsel alle einmal neu bauen – State (Routen, Eingaben,
      // Snackbars) bleibt erhalten.
      WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildAll());
    }
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: ref.watch(localeProvider).value,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }

  static void _rebuildAll() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(mark);
  }
}
