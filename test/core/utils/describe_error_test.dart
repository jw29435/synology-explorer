import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/network/certificate_pinning.dart';
import 'package:nuvo_explorer/core/utils/format.dart';
import 'package:nuvo_explorer/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('de'));

  test('unbekanntes Zertifikat hat eine eigene Meldung (E2E-032)', () {
    final cert = _Cert();
    final untrusted = UntrustedCertificateException('nas.example', 5001, cert);
    expect(
      describeError(untrusted, l10n),
      l10n.errorCertUntrusted('nas.example'),
    );
    expect(describeError(untrusted, l10n), isNot(l10n.errorGeneric));
    expect(
      describeError(
        CertificateMismatchException('nas.example', 5001, cert),
        l10n,
      ),
      l10n.errorCertMismatch('nas.example'),
    );
  });
}

class _Cert implements X509Certificate {
  @override
  Uint8List get der => Uint8List.fromList([1, 2, 3]);
  @override
  String get subject => 'CN=synology';
  @override
  String get issuer => 'CN=synology';
  @override
  DateTime get startValidity => DateTime(2026);
  @override
  DateTime get endValidity => DateTime(2027);
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
