import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../network/certificate_pinning.dart';
import '../network/syno_exception.dart';

/// Binäre Einheiten wie DSM (1 MB = 1024² Byte), eine Nachkommastelle.
String formatSize(int bytes, String locale) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final number = NumberFormat(unit == 0 ? '0' : '0.#', locale).format(value);
  return '$number ${units[unit]}';
}

String formatInt(int n, String locale) =>
    NumberFormat.decimalPattern(locale).format(n);

String formatDate(DateTime time, AppLocalizations l10n) =>
    DateFormat(l10n.datePattern, l10n.localeName).format(time.toLocal());

String formatDateTime(DateTime time, AppLocalizations l10n) =>
    '${formatDate(time, l10n)}, ${DateFormat.Hm(l10n.localeName).format(time.toLocal())}';

/// „heute 17:12“, „gestern“, Wochentag der letzten Woche, sonst Datum.
String formatRelative(DateTime time, AppLocalizations l10n, {DateTime? now}) {
  final local = time.toLocal();
  final today = _dateOnly(now ?? DateTime.now());
  final days = today.difference(_dateOnly(local)).inDays;
  return switch (days) {
    0 => l10n.today(DateFormat.Hm(l10n.localeName).format(local)),
    1 => l10n.yesterday,
    > 1 && < 7 => DateFormat.E(l10n.localeName).format(local),
    _ => formatDate(local, l10n),
  };
}

DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

/// Text für Fehler aus Netzwerk, Auth und Zertifikat-Pinning.
String describeError(Object error, AppLocalizations l10n) => switch (error) {
  SynoUnauthorized() => l10n.errorUnauthorized,
  SynoAccountLocked() => l10n.errorAccountLocked,
  SynoOtpRequired() => l10n.errorOtpRequired,
  SynoOtpInvalid() => l10n.errorOtpInvalid,
  SynoSessionExpired() => l10n.errorSessionExpired,
  SynoPermissionDenied() => l10n.errorPermission,
  SynoNotFound() => l10n.errorNotFound,
  SynoNetworkError(:final statusCode?) => l10n.errorHttp(statusCode),
  SynoNetworkError() => l10n.errorNetwork,
  SynoUnknown(:final code?) => l10n.errorCode(code),
  CertificateMismatchException(:final host) => l10n.errorCertMismatch(host),
  _ => l10n.errorGeneric,
};
