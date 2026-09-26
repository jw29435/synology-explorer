import 'dart:io';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/storage/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/transfer.dart';

/// Eine Sammel-Benachrichtigung mit Gesamtfortschritt, solange ein Transfer
/// läuft (Wartende zählen dann mit); höchstens einmal pro Sekunde
/// aktualisiert. `update([])` schließt sie.
class TransferNotifications {
  static const _id = 7001;

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;
  DateTime _last = DateTime(0);
  bool _shown = false;

  Future<bool> _init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return true;
  }

  Future<void> update(List<Transfer> transfers) async {
    final active = notifiedTransfers(transfers);
    if (active.isEmpty && !_shown) return;
    try {
      if (!await (_ready ??= _init())) return;
      if (active.isEmpty) {
        _shown = false;
        await _plugin.cancel(id: _id);
        return;
      }
      final now = DateTime.now();
      if (_shown && now.difference(_last) < const Duration(seconds: 1)) return;
      _last = now;
      _shown = true;
      final total = active.fold(0, (s, t) => s + (t.bytesTotal ?? 0));
      final done = active.fold(0, (s, t) => s + t.bytesDone);
      final l10n = _l10n();
      await _plugin.show(
        id: _id,
        title: l10n.notificationTransfers(active.length),
        body: total == 0 ? null : '${(done * 100 / total).round()} %',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'transfers',
            l10n.tabTransfers,
            importance: Importance.low,
            ongoing: true,
            onlyAlertOnce: true,
            showProgress: true,
            maxProgress: 100,
            progress: total == 0 ? 0 : (done * 100 ~/ total).clamp(0, 100),
            indeterminate: total == 0,
          ),
          iOS: const DarwinNotificationDetails(presentSound: false),
        ),
      );
    } catch (_) {
      // Benachrichtigungen sind Zusatz; Transfers laufen auch ohne.
    }
  }

  static AppLocalizations _l10n() {
    final locale = PlatformDispatcher.instance.locale;
    return lookupAppLocalizations(
      AppLocalizations.supportedLocales.any(
            (l) => l.languageCode == locale.languageCode,
          )
          ? Locale(locale.languageCode)
          : const Locale('de'),
    );
  }
}

/// Was die Benachrichtigung zählt: Wartende und Laufende, aber nur solange
/// einer wirklich läuft. Wartende allein (Auth-Halt, keine Session, anderer
/// Server) halten keine Dauer-Benachrichtigung offen.
List<Transfer> notifiedTransfers(List<Transfer> transfers) =>
    transfers.any((t) => t.state == TransferState.running)
    ? [
        for (final t in transfers)
          if (t.state == TransferState.queued ||
              t.state == TransferState.running)
            t,
      ]
    : const [];
