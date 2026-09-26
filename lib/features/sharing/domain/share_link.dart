import '../../browser/domain/nas_entry.dart';

/// Ablauf-Optionen beim Erstellen (Screen 22); Default 7 Tage.
enum ShareExpiry {
  day1(1),
  days7(7),
  days30(30),
  never(null);

  const ShareExpiry(this.days);

  final int? days;

  /// Ablaufdatum (Tagesbeginn, lokale Zeit) ab [now]; `null` = nie.
  DateTime? expiresAt(DateTime now) => switch (days) {
    final d? => DateTime(now.year, now.month, now.day + d),
    null => null,
  };
}

/// `date_expired` für `Sharing create`: DSM nimmt ein Datum `YYYY-MM-DD`.
String? dateExpiredParam(DateTime? date) => date == null
    ? null
    : '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

/// Ein Freigabelink aus `SYNO.FileStation.Sharing`.
class ShareLink {
  const ShareLink({
    required this.id,
    required this.url,
    required this.name,
    required this.path,
    required this.isFolder,
    required this.hasPassword,
    this.expiresAt,
    this.status,
  });

  factory ShareLink.fromSyno(Map<String, dynamic> json) {
    final path = json['path'] as String? ?? '';
    return ShareLink(
      id: json['id'] as String,
      url: json['url'] as String,
      name: json['name'] as String? ?? path.split('/').last,
      path: path,
      isFolder: json['isFolder'] == true,
      hasPassword: json['has_password'] == true,
      expiresAt: parseSynoDate(json['date_expired']),
      status: json['status'] as String?,
    );
  }

  final String id;
  final String url;
  final String name;
  final String path;
  final bool isFolder;
  final bool hasPassword;

  /// `null` = kein Ablauf.
  final DateTime? expiresAt;

  /// DSM: `valid`, `expired`, `invalid`, `broken` …
  final String? status;

  NasFileType get type =>
      isFolder ? NasFileType.folder : NasFileType.fromName(name);

  /// Tage bis zum Ablauf ab dem Kalendertag von [now]: 0 = läuft heute ab,
  /// negativ = abgelaufen, `null` = kein Ablauf.
  int? daysLeft(DateTime now) {
    final at = expiresAt;
    if (at == null) return null;
    return DateTime(
      at.year,
      at.month,
      at.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// Abgelaufen laut DSM oder weil das Ablaufdatum vorbei ist. Ein Link mit
  /// Ablauf „heute“ gilt noch.
  bool isExpired(DateTime now) =>
      status == 'expired' || (daysLeft(now) ?? 0) < 0;
}

/// DSM-Datum `YYYY-MM-DD` oder `YYYY-MM-DD hh:mm:ss`; leer/`0` = keins.
DateTime? parseSynoDate(Object? value) => value is String && value.length >= 10
    ? DateTime.tryParse(value.replaceFirst(' ', 'T'))
    : null;

/// Freigabelinks sollen von außen erreichbar sein: Zeigt DSM auf eine
/// `/sharing/`-Adresse, wird Schema/Host/Port durch die externe Adresse des
/// Servers ersetzt. Andere Links (z. B. QuickConnect `gofile.me`) bleiben.
String publicShareUrl(String url, String? externalUrl) {
  final uri = Uri.tryParse(url);
  if (externalUrl == null || uri == null) return url;
  final index = uri.path.indexOf('/sharing/');
  if (index < 0) return url;
  final base = externalUrl.replaceFirst(RegExp(r'/+$'), '');
  return '$base${uri.path.substring(index)}';
}
