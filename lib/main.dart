import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'core/storage/storage_providers.dart';
import 'features/audio/data/audio_handler.dart';
import 'features/audio/presentation/playback_providers.dart';
import 'features/autoupload/data/background.dart';

Future<void> main() async {
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
    // Native Bibliotheken ohne eigenes Dart-Paket (media_kit_libs_*).
    yield const LicenseEntryWithLineBreaks(['libmpv', 'FFmpeg'], _lgplNotice);
  });
  if (Platform.isIOS) {
    try {
      await migrateSecureStorage();
    } catch (_) {
      // Alte Einträge bleiben lesbar (nur nicht bei gesperrtem Gerät).
    }
  }
  // Auto-Upload im Hintergrund (WorkManager bzw. BGTaskScheduler).
  await Workmanager().initialize(autoUploadDispatcher);
  // Foreground-Service/Now Playing für die Hintergrundwiedergabe.
  final audioHandler = await AppAudioHandler.init();
  runApp(
    ProviderScope(
      overrides: [audioHandlerProvider.overrideWithValue(audioHandler)],
      // Kein automatischer Retry fehlgeschlagener Provider: ein Login-Fehler
      // darf nie wiederholt werden (DSM-Auto-Block).
      retry: (_, _) => null,
      child: const SynologyExplorerApp(),
    ),
  );
}

const _lgplNotice =
    'Die Videowiedergabe nutzt libmpv (https://mpv.io) und FFmpeg '
    '(https://ffmpeg.org), eingebunden über media_kit_libs_video als '
    'dynamisch gelinkte Bibliotheken unter der GNU Lesser General Public '
    'License 2.1 oder neuer. Quelltext und Build-Skripte: '
    'https://github.com/media-kit/libmpv-android-video-build und '
    'https://github.com/media-kit/libmpv-darwin-build.\n\n'
    'Video playback uses libmpv and FFmpeg, bundled via media_kit_libs_video '
    'as dynamically linked libraries under the GNU Lesser General Public '
    'License 2.1 or later. Full license text: '
    'https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt';
