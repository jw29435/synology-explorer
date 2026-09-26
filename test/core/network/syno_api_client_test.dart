import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/network/certificate_pinning.dart';
import 'package:nuvo_explorer/core/network/syno_api_client.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';
import 'package:nuvo_explorer/features/servers/domain/server_profile.dart';

/// Antwortet per Skript statt übers Netz; merkt sich jede Anfrage.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);

  final Map<String, Object?> Function(Map<String, Object?> params) respond;
  final requests = <Map<String, Object?>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final params = {
      ...options.queryParameters,
      ...options.data as Map<String, Object?>,
    };
    requests.add(params);
    return ResponseBody.fromString(jsonEncode(respond(params)), 200);
  }

  Iterable<Map<String, Object?>> calls(String method) =>
      requests.where((r) => r['method'] == method);

  @override
  void close({bool force = false}) {}
}

const apiInfo = {
  'success': true,
  'data': {
    'SYNO.API.Info': {'maxVersion': 1, 'path': 'entry.cgi'},
    'SYNO.API.Auth': {'maxVersion': 7, 'path': 'entry.cgi'},
    'SYNO.FileStation.List': {'maxVersion': 2, 'path': 'entry.cgi'},
  },
};

Map<String, Object?> error(int code) => {
  'success': false,
  'error': {'code': code},
};

void main() {
  late FakeAdapter adapter;
  late SynoApiClient client;
  late int relogins;

  /// [listResponses] liefert der Reihe nach die Antworten auf `list_share`.
  Future<void> setUpClient(List<Map<String, Object?>> listResponses) async {
    final queue = [...listResponses];
    adapter = FakeAdapter(
      (p) => switch (p['method']) {
        'query' => apiInfo,
        'list_share' => queue.removeAt(0),
        _ => error(119),
      },
    );
    client = SynoApiClient(
      const ServerProfile(
        id: 1,
        name: 'NAS',
        lanUrl: 'https://nas.lan:5001',
        user: 'johann',
      ),
      CertificatePinStore(const FlutterSecureStorage()),
      adapter: adapter,
    );
    relogins = 0;
    client
      ..sid = 'alt'
      ..onSessionExpired = (_) async {
        relogins++;
        client.sid = 'neu';
      };
    await client.connect();
  }

  Future<dynamic> listShares() =>
      client.request('SYNO.FileStation.List', 'list_share');

  test('Info mit v1, danach maxVersion je API und _sid', () async {
    await setUpClient([
      {'success': true, 'data': 'ok'},
    ]);
    expect(await listShares(), 'ok');
    expect(adapter.calls('query').single, containsPair('version', 1));
    expect(adapter.calls('list_share').single, {
      'api': 'SYNO.FileStation.List',
      'version': 2,
      'method': 'list_share',
      '_sid': 'alt',
    });
  });

  for (final code in SynoException.reloginCodes) {
    test(
      'Fehler $code → genau ein Re-Login, dann Retry mit neuer SID',
      () async {
        await setUpClient([
          error(code),
          {'success': true, 'data': 'ok'},
        ]);
        expect(await listShares(), 'ok');
        expect(relogins, 1);
        expect(adapter.calls('list_share').map((r) => r['_sid']), [
          'alt',
          'neu',
        ]);
      },
    );
  }

  test(
    'scheitert der Retry, wird abgebrochen – kein zweiter Re-Login',
    () async {
      await setUpClient([error(119), error(119)]);
      await expectLater(listShares(), throwsA(isA<SynoSessionExpired>()));
      expect(relogins, 1);
      expect(adapter.calls('list_share'), hasLength(2));
    },
  );

  test('105 bleibt nach Re-Login → permissionDenied', () async {
    await setUpClient([error(105), error(105)]);
    await expectLater(listShares(), throwsA(isA<SynoPermissionDenied>()));
    expect(relogins, 1);
  });

  test('scheitert der Re-Login selbst, kein Retry', () async {
    await setUpClient([error(119)]);
    client.onSessionExpired = (_) async => throw const SynoSessionExpired();
    await expectLater(listShares(), throwsA(isA<SynoSessionExpired>()));
    expect(adapter.calls('list_share'), hasLength(1));
  });

  test('andere Fehler lösen keinen Re-Login aus', () async {
    await setUpClient([error(408)]);
    await expectLater(listShares(), throwsA(isA<SynoNotFound>()));
    expect(relogins, 0);
  });

  test('119 bei SYNO.API.Auth → kein Re-Login (Auto-Block)', () async {
    await setUpClient([]);
    await expectLater(
      client.request('SYNO.API.Auth', 'login'),
      throwsA(isA<SynoSessionExpired>()),
    );
    expect(relogins, 0);
    expect(adapter.calls('login'), hasLength(1));
  });

  test('API, die das NAS nicht meldet → 102 ohne Request', () async {
    await setUpClient([]);
    await expectLater(
      client.request('SYNO.FileStation.Nope', 'x'),
      throwsA(isA<SynoUnknown>().having((e) => e.code, 'code', 102)),
    );
    expect(adapter.requests, hasLength(1)); // nur Info
  });
}
