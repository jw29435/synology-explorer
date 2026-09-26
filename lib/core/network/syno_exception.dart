/// Fehler aus der DSM Web API. Synology meldet API-Fehler mit HTTP 200 und
/// `{"success": false, "error": {"code": n}}`; die Codes 400–4xx bedeuten bei
/// `SYNO.API.Auth` etwas anderes als bei File Station.
sealed class SynoException implements Exception {
  const SynoException([this.code]);

  /// Synology-Fehlercode, falls vorhanden.
  final int? code;

  /// Codes, bei denen der Client genau einmal neu anmeldet.
  static const reloginCodes = {105, 106, 107, 119};

  factory SynoException.fromCode(int code, {required String api}) {
    if (api == 'SYNO.API.Auth') {
      switch (code) {
        case 400 || 408 || 409 || 410:
          return SynoUnauthorized(code);
        case 401 || 407:
          return SynoAccountLocked(code);
        case 402:
          return SynoPermissionDenied(code);
        case 403 || 406:
          return SynoOtpRequired(code);
        case 404:
          return SynoOtpInvalid(code);
      }
    }
    return switch (code) {
      105 || 407 => SynoPermissionDenied(code),
      106 || 107 || 119 => SynoSessionExpired(code),
      408 || 599 => SynoNotFound(code),
      414 => SynoAlreadyExists(code),
      _ => SynoUnknown(code),
    };
  }

  @override
  String toString() => '$runtimeType(code: $code)';
}

/// Benutzer oder Passwort falsch (bzw. Passwort abgelaufen).
final class SynoUnauthorized extends SynoException {
  const SynoUnauthorized([super.code]);
}

/// Konto deaktiviert oder IP durch DSM-Auto-Block gesperrt.
final class SynoAccountLocked extends SynoException {
  const SynoAccountLocked([super.code]);
}

final class SynoOtpRequired extends SynoException {
  const SynoOtpRequired([super.code]);
}

final class SynoOtpInvalid extends SynoException {
  const SynoOtpInvalid([super.code]);
}

/// Session abgelaufen und nicht still erneuerbar (kein Passwort gespeichert
/// oder Re-Login schon verbraucht).
final class SynoSessionExpired extends SynoException {
  const SynoSessionExpired([super.code]);
}

final class SynoPermissionDenied extends SynoException {
  const SynoPermissionDenied([super.code]);
}

final class SynoNotFound extends SynoException {
  const SynoNotFound([super.code]);
}

/// Ziel existiert schon (Umbenennen, Kopieren, Ordner anlegen).
final class SynoAlreadyExists extends SynoException {
  const SynoAlreadyExists([super.code]);
}

/// NAS nicht erreichbar (Timeout, Verbindungsfehler) oder HTTP-Fehler;
/// dann steht der HTTP-Status in [statusCode].
final class SynoNetworkError extends SynoException {
  const SynoNetworkError({this.statusCode, this.cause});

  final int? statusCode;
  final Object? cause;

  /// Ohne Session-ID: dart:io-Fehler nennen die URL samt `_sid`, und
  /// unbehandelte Fehler landen im Log.
  @override
  String toString() =>
      'SynoNetworkError(status: $statusCode, cause: ${redactSecrets('$cause')})';
}

/// Ersetzt Session-ID und Passwort in URLs/Formularen durch `***`.
String redactSecrets(String text) => text.replaceAllMapped(
  RegExp(r'(_sid|passwd|synotoken)=[^&\s,)]+'),
  (m) => '${m[1]}=***',
);

final class SynoUnknown extends SynoException {
  const SynoUnknown(int super.code);
}
