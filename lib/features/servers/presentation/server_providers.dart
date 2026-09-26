import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_manager.dart';
import '../../../core/network/certificate_pinning.dart';
import '../../../core/network/syno_api_client.dart';
import '../../../core/storage/storage_providers.dart';
import '../../transfers/presentation/transfer_providers.dart';
import '../data/server_repository.dart';
import '../domain/server_profile.dart';

final pinStoreProvider = Provider<CertificatePinStore>(
  (ref) => CertificatePinStore(ref.watch(secureStorageProvider)),
);

final serverRepositoryProvider = Provider<ServerRepository>(
  (ref) => ServerRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(secureStorageProvider),
    ref.watch(pinStoreProvider),
  ),
);

final serversProvider = FutureProvider<List<ServerProfile>>(
  (ref) => ref.watch(serverRepositoryProvider).all(),
);

/// Die angemeldete Session; `null` = kein Server aktiv.
final sessionProvider = NotifierProvider<SessionNotifier, SessionManager?>(
  SessionNotifier.new,
);

class SessionNotifier extends Notifier<SessionManager?> {
  static const _lastServerKey = 'lastServer';

  @override
  SessionManager? build() => null;

  /// Die letzte Session endete, weil der stille Re-Login scheiterte (für die
  /// Meldung auf Screen 01).
  bool expired = false;

  /// Macht [session] zur aktiven Session und merkt den Server für den
  /// nächsten App-Start.
  Future<void> activate(SessionManager session) async {
    final old = state;
    if (old != null && !identical(old, session)) await _suspendTransfers();
    expired = false;
    session.onSessionLost = () {
      if (!identical(state, session)) return;
      expired = true;
      unawaited(close());
    };
    state = session;
    if (old != null && !identical(old, session)) old.client.close();
    await ref
        .read(secureStorageProvider)
        .write(key: _lastServerKey, value: '${session.client.profile.id}');
  }

  /// Meldet am NAS ab (löscht SID, Geräte-Token, Passwort).
  Future<void> logout() async {
    final session = state;
    if (session == null) return;
    await _suspendTransfers();
    state = null;
    await ref.read(secureStorageProvider).delete(key: _lastServerKey);
    await session.logout();
    session.client.close();
  }

  /// Verwirft die Session lokal, ohne Secrets zu löschen.
  Future<void> close() async {
    final session = state;
    if (session == null) return;
    await _suspendTransfers();
    state = null;
    session.client.close();
  }

  /// Laufende Transfers pausieren, bevor ihr Client geschlossen wird – sonst
  /// scheitern sie mit Netzwerkfehlern oder laufen gegen den falschen Server.
  Future<void> _suspendTransfers() async {
    try {
      await ref.read(transferQueueProvider).suspend();
    } catch (_) {
      // Transfers sind Zusatz; der Serverwechsel geht vor.
    }
  }

  /// Verbindet beim App-Start still mit dem zuletzt genutzten Server, wenn
  /// dafür eine SID vorliegt. Liefert, ob das geklappt hat. Kein Login-Versuch.
  Future<bool> resumeLast() async {
    final id = int.tryParse(
      await ref.read(secureStorageProvider).read(key: _lastServerKey) ?? '',
    );
    final profile = (await ref.read(serversProvider.future))
        .where((p) => p.id == id)
        .firstOrNull;
    if (profile == null) return false;
    try {
      final session = await ref.read(serverRepositoryProvider).connect(profile);
      if (!session.isLoggedIn) {
        session.client.close();
        return false;
      }
      await activate(session);
      return true;
    } catch (_) {
      // Nicht erreichbar, Zertifikat unbekannt …: Nutzer wählt selbst.
      return false;
    }
  }
}

/// Client der aktiven Session; wirft ohne Session.
SynoApiClient sessionClient(Ref ref) =>
    (ref.watch(sessionProvider) ?? (throw StateError('Keine Session'))).client;

/// Einmal pro App-Start: [SessionNotifier.resumeLast].
final startupProvider = FutureProvider<bool>(
  (ref) => ref.read(sessionProvider.notifier).resumeLast(),
);
