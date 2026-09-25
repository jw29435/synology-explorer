import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import '../../tool/mock_nas/mock_nas.dart';

void main() {
  final handler = mockNasHandler(Directory('test/fixtures'));

  Future<Map<String, dynamic>> call(String query, {String? body}) async {
    final url = Uri.parse('http://nas/webapi/entry.cgi?$query');
    final response = await handler(
      body == null ? Request('GET', url) : Request('POST', url, body: body),
    );
    expect(response.statusCode, 200);
    return jsonDecode(await response.readAsString()) as Map<String, dynamic>;
  }

  test('liefert Fixture für api/method per GET', () async {
    final json = await call('api=SYNO.API.Info&version=1&method=query');
    expect(json['success'], isTrue);
    expect(json['data']['SYNO.API.Auth']['maxVersion'], 7);
  });

  test('liest Parameter aus POST-Formular', () async {
    final json = await call('', body: 'api=SYNO.API.Auth&method=login');
    expect(json['data']['sid'], isNotEmpty);
  });

  test('unbekannte API → 102, unbekannte Methode → 103', () async {
    expect((await call('api=SYNO.Nope&method=x'))['error']['code'], 102);
    expect((await call('api=SYNO.API.Auth&method=nope'))['error']['code'], 103);
    expect((await call('api=..&method=pubspec'))['error']['code'], 102);
  });

  test('andere Pfade → 404', () async {
    final response = await handler(Request('GET', Uri.parse('http://nas/x')));
    expect(response.statusCode, 404);
  });
}
