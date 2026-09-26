import '../../../core/network/syno_exception.dart';

enum TransferKind { download, upload }

/// `queued` → `running` → `done`; `paused` und `failed` warten auf den Nutzer.
enum TransferState { queued, running, paused, failed, done }

/// Kurzform eines Fehlers für die Spalte `transfers.error`, z. B.
/// `SynoNetworkError`, `SynoPermissionDenied:407` oder `SynoNetworkError:502`.
String transferErrorTag(Object error) => switch (error) {
  SynoNetworkError(:final statusCode?) => 'SynoNetworkError:$statusCode',
  SynoException(:final code?) => '${error.runtimeType}:$code',
  SynoException() => '${error.runtimeType}',
  _ => 'local',
};

/// Fehler, nach denen der Worker keine weiteren Transfers startet: Ohne
/// gültige Anmeldung würde jeder weitere Versuch nur scheitern (und DSM
/// Auto-Block riskieren).
bool isAuthError(Object error) =>
    error is SynoSessionExpired ||
    error is SynoUnauthorized ||
    error is SynoAccountLocked;
