import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/sharing/domain/share_link.dart';
import 'package:synology_explorer/features/sharing/presentation/share_link_sheet.dart';

void main() {
  final now = DateTime(2026, 9, 25, 18, 5);

  test('Ablauf: 1/7/30 Tage ab heute, nie = null', () {
    expect(ShareExpiry.day1.expiresAt(now), DateTime(2026, 9, 26));
    expect(ShareExpiry.days7.expiresAt(now), DateTime(2026, 10, 2));
    expect(ShareExpiry.days30.expiresAt(now), DateTime(2026, 10, 25));
    expect(ShareExpiry.never.expiresAt(now), isNull);
    // Monats- und Jahreswechsel.
    expect(
      ShareExpiry.days7.expiresAt(DateTime(2026, 12, 28)),
      DateTime(2027, 1, 4),
    );
  });

  test('date_expired als YYYY-MM-DD', () {
    expect(dateExpiredParam(DateTime(2026, 10, 2)), '2026-10-02');
    expect(dateExpiredParam(null), isNull);
  });

  test('DSM-Datum parsen', () {
    expect(parseSynoDate('2026-10-02'), DateTime(2026, 10, 2));
    expect(parseSynoDate('2026-10-02 18:05:00'), DateTime(2026, 10, 2, 18, 5));
    expect(parseSynoDate(''), isNull);
    expect(parseSynoDate('0'), isNull);
    expect(parseSynoDate(0), isNull);
  });

  ShareLink link({String? expires, String status = 'valid'}) =>
      ShareLink.fromSyno({
        'id': 'kQ7mX2pLv',
        'url': 'https://192.168.1.2:5001/sharing/kQ7mX2pLv',
        'name': '02 Strandgut.flac',
        'path': '/music/Alben/02 Strandgut.flac',
        'isFolder': false,
        'has_password': true,
        'date_expired': ?expires,
        'status': status,
      });

  test('Tage bis Ablauf und abgelaufen', () {
    expect(link(expires: '2026-10-02').daysLeft(now), 7);
    expect(link(expires: '2026-09-25').daysLeft(now), 0);
    expect(link(expires: '2026-09-25').isExpired(now), isFalse);
    expect(link(expires: '2026-09-18').daysLeft(now), -7);
    expect(link(expires: '2026-09-18').isExpired(now), isTrue);
    expect(link().daysLeft(now), isNull);
    expect(link().isExpired(now), isFalse);
    expect(link(status: 'expired').isExpired(now), isTrue);
    expect(link().hasPassword, isTrue);
  });

  test('Link zeigt auf die externe Adresse', () {
    const url = 'https://192.168.1.2:5001/sharing/kQ7mX2pLv';
    expect(
      publicShareUrl(url, 'https://nas.beispiel.de/'),
      'https://nas.beispiel.de/sharing/kQ7mX2pLv',
    );
    expect(
      publicShareUrl(url, 'https://nas.beispiel.de:8443/dsm'),
      'https://nas.beispiel.de:8443/dsm/sharing/kQ7mX2pLv',
    );
    expect(publicShareUrl(url, null), url);
    // QuickConnect-Links bleiben unverändert.
    expect(
      publicShareUrl('https://gofile.me/abc/def', 'https://nas.beispiel.de'),
      'https://gofile.me/abc/def',
    );
  });

  test('Zufallspasswort', () {
    final a = generatePassword();
    expect(a, hasLength(10));
    expect(a, matches(RegExp(r'^[a-zA-Z2-9]+$')));
    expect(generatePassword(), isNot(a));
  });
}
