import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// SHA-256 über das DER-kodierte Zertifikat, als `AB:CD:…`.
String certificateFingerprint(X509Certificate cert) => sha256
    .convert(cert.der)
    .bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join(':');

/// Gepinnte Fingerprints selbstsignierter Zertifikate je `host:port` im
/// Secure Storage. [load] vor dem ersten Verbindungsaufbau aufrufen – der
/// TLS-Callback ist synchron und liest nur den Speicherstand.
class CertificatePinStore {
  CertificatePinStore(this._storage);

  static const _prefix = 'pin:';

  final FlutterSecureStorage _storage;
  final _pins = <String, String>{};

  Future<void> load() async {
    final all = await _storage.readAll();
    _pins
      ..clear()
      ..addEntries(
        all.entries
            .where((e) => e.key.startsWith(_prefix))
            .map((e) => MapEntry(e.key.substring(_prefix.length), e.value)),
      );
  }

  String? pinFor(String host, int port) => _pins['$host:$port'];

  /// Nur nach ausdrücklicher Bestätigung durch den Nutzer aufrufen.
  Future<void> pin(String host, int port, String fingerprint) async {
    _pins['$host:$port'] = fingerprint;
    await _storage.write(key: '$_prefix$host:$port', value: fingerprint);
  }
}

/// Zertifikat, das die Systemprüfung nicht besteht und noch nicht gepinnt ist.
/// Die UI zeigt die Daten an und ruft nach Bestätigung
/// [CertificatePinStore.pin] auf.
class UntrustedCertificateException implements Exception {
  UntrustedCertificateException(this.host, this.port, X509Certificate cert)
    : subject = cert.subject,
      issuer = cert.issuer,
      validFrom = cert.startValidity,
      validTo = cert.endValidity,
      fingerprint = certificateFingerprint(cert);

  final String host;
  final int port;
  final String subject;
  final String issuer;
  final DateTime validFrom;
  final DateTime validTo;
  final String fingerprint;

  @override
  String toString() =>
      'UntrustedCertificateException($host:$port, $fingerprint)';
}

/// Der Host hat ein anderes Zertifikat als das gepinnte. Harter Fehler: keine
/// Verbindung, kein Fallback. Die UI zeigt den Bestätigungsdialog erneut
/// (CONCEPT.md Abschnitt 8) – nötig z. B. nach Zertifikatserneuerung.
class CertificateMismatchException extends UntrustedCertificateException {
  CertificateMismatchException(super.host, super.port, super.cert);

  @override
  String toString() =>
      'CertificateMismatchException($host:$port, $fingerprint)';
}
