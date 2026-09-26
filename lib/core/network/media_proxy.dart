import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import 'syno_api_client.dart';
import 'syno_exception.dart';

/// Lokaler HTTP-Proxy für Player mit eigenem Netzwerk-Stack (media_kit/libmpv).
///
/// Lauscht nur auf 127.0.0.1 (zufälliger Port) und reicht Range-Anfragen über
/// [SynoApiClient] an `SYNO.FileStation.Download` weiter. So gelten Pinning,
/// gebündelte Roots und die Re-Login-Policy auch fürs Streaming, und die SID
/// verlässt nie die App: Der Player sieht nur eine URL mit einem zufälligen
/// Token, das je Wiedergabe neu ist. Andere Pfade bekommen 403.
class MediaProxy {
  MediaProxy._(
    this._server,
    this._client,
    this._path,
    this._token,
    this._allow,
  ) {
    _server.listen(_handle);
  }

  /// Startet den Proxy für die Datei [path] auf dem NAS. [allow] wird vor
  /// jedem Request gefragt (z. B. „Streaming nur im WLAN“); `false` = 403,
  /// ohne das NAS zu fragen.
  static Future<MediaProxy> start(
    SynoApiClient client,
    String path, {
    Future<bool> Function()? allow,
  }) async {
    final random = Random.secure();
    final token = base64Url
        .encode([for (var i = 0; i < 32; i++) random.nextInt(256)])
        .replaceAll('=', '');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return MediaProxy._(server, client, path, token, allow);
  }

  final HttpServer _server;
  final SynoApiClient _client;
  final String _path;
  final String _token;
  final Future<bool> Function()? _allow;

  InternetAddress get address => _server.address;

  /// URL für den Player; der Dateiname hilft nur bei der Formaterkennung.
  Uri get url => Uri(
    scheme: 'http',
    host: _server.address.address,
    port: _server.port,
    pathSegments: [_token, _path.substring(_path.lastIndexOf('/') + 1)],
  );

  Future<void> close() => _server.close(force: true);

  static final _range = RegExp(r'^bytes=(\d+)-(\d*)$');

  Future<void> _handle(HttpRequest request) async {
    final res = request.response;
    // Beendet den Transfer vom NAS, sobald diese Antwort fertig ist oder der
    // Player trennt (Seek, HEAD, close) – Abbestellen allein reicht nicht.
    final upstream = CancelToken();
    try {
      if (request.uri.pathSegments.firstOrNull != _token) {
        res.statusCode = HttpStatus.forbidden;
        return;
      }
      if (request.method != 'GET' && request.method != 'HEAD') {
        res.statusCode = HttpStatus.methodNotAllowed;
        return;
      }
      if (_allow != null && !await _allow()) {
        res.statusCode = HttpStatus.forbidden;
        return;
      }
      final range = request.headers.value(HttpHeaders.rangeHeader);
      final match = range == null ? null : _range.firstMatch(range);
      if (range != null && match == null) {
        res.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        return;
      }
      final end = match?.group(2);
      final body = await _client.requestStream(
        'SYNO.FileStation.Download',
        'download',
        {'path': _path, 'mode': 'open'},
        start: int.parse(match?.group(1) ?? '0'),
        end: end == null || end.isEmpty ? null : int.parse(end) + 1,
        cancelToken: upstream,
      );
      String? header(String name) => body.headers[name]?.first;
      final contentRange = header('content-range');
      // Ohne Range-Anfrage des Players: ganze Datei als 200.
      res.statusCode = match != null && contentRange != null
          ? HttpStatus.partialContent
          : HttpStatus.ok;
      res.headers
        ..set(HttpHeaders.acceptRangesHeader, 'bytes')
        ..set(
          HttpHeaders.contentTypeHeader,
          header('content-type') ?? 'application/octet-stream',
        );
      if (res.statusCode == HttpStatus.partialContent) {
        res.headers.set(HttpHeaders.contentRangeHeader, contentRange!);
      }
      if (header('content-length') case final length?) {
        res.headers.contentLength = int.parse(length);
      }
      if (request.method != 'HEAD') {
        // Backpressure: liest vom NAS nur so schnell, wie der Player
        // abnimmt (auch in Pause); trennt er, endet der Upstream-Stream.
        await res.addStream(body.stream);
      }
    } on SynoException catch (e) {
      res.statusCode = switch (e) {
        SynoNotFound() => HttpStatus.notFound,
        SynoPermissionDenied() => HttpStatus.forbidden,
        _ => HttpStatus.badGateway,
      };
    } catch (_) {
      // Player hat die Verbindung beim Seek abgebrochen o. Ä.
    } finally {
      upstream.cancel();
      try {
        await res.close();
      } catch (_) {
        // Verbindung schon weg.
      }
    }
  }
}
