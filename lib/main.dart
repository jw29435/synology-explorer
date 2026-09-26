import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  // Keine Drittserver: Fonts kommen ausschließlich aus assets/fonts/.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Manrope', 'JetBrainsMono']) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/OFL-$font.txt'));
    }
  });
  runApp(
    ProviderScope(
      // Kein automatischer Retry fehlgeschlagener Provider: ein Login-Fehler
      // darf nie wiederholt werden (DSM-Auto-Block).
      retry: (_, _) => null,
      child: const SynologyExplorerApp(),
    ),
  );
}
