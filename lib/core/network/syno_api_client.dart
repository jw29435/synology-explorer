import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../features/servers/domain/server_profile.dart';
import 'certificate_pinning.dart';
import 'trusted_roots.dart';
import 'syno_exception.dart';

/// Einziger Zugang zur DSM Web API eines Servers.
///
/// [connect] wählt die Adresse (LAN, bei Netzwerkfehler extern) und cacht
/// `SYNO.API.Info`; [request] nutzt je API die vom NAS gemeldete maxVersion,
/// hängt `_sid` an und meldet bei abgelaufener Session genau einmal neu an.
class SynoApiClient {
  SynoApiClient(
    this.profile,
    this._pins, {
    @visibleForTesting HttpClientAdapter? adapter,
  }) : _dio = Dio(
         BaseOptions(
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 30),
           responseType: ResponseType.plain,
           contentType: Headers.formUrlEncodedContentType,
         ),
       ) {
    _dio.httpClientAdapter =
        adapter ?? IOHttpClientAdapter(createHttpClient: _createHttpClient);
    // SID-Interceptor: `_sid` immer als Query-Parameter (kein Cookie).
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (sid case final sid?) options.queryParameters['_sid'] = sid;
          if (options.extra['timeout'] case final Duration t) {
            options
              ..connectTimeout = t
              ..receiveTimeout = t;
          }
          handler.next(options);
        },
      ),
    );
  }

  /// Timeout für den LAN-Versuch, wenn eine externe Adresse existiert.
  static const lanTimeout = Duration(seconds: 2);

  final ServerProfile profile;
  final CertificatePinStore _pins;
  final Dio _dio;
  final _activeUrl = StreamController<Uri>.broadcast();

  /// Vom TLS-Callback abgelehnte Zertifikate je `host:port`.
  final _rejected = <String, X509Certificate>{};
  Map<String, ({int maxVersion, String path})> _apis = const {};
  Uri? _baseUrl;

  /// Aktuelle Session-ID; setzt der SessionManager.
  String? sid;

  /// Erneuert die Session (Re-Login). Wirft, wenn das nicht still geht.
  Future<void> Function()? onSessionExpired;

  Uri? get activeUrl => _baseUrl;
  Stream<Uri> get activeUrlChanges => _activeUrl.stream;

  /// Wählt die Adresse und fragt `SYNO.API.Info` ab. Fallback auf die externe
  /// Adresse nur bei Netzwerkfehlern – HTTP-, API- und Zertifikatsfehler
  /// werden durchgereicht.
  Future<void> connect() async {
    final external = profile.externalUrl;
    try {
      await _queryApiInfo(
        Uri.parse(profile.lanUrl),
        timeout: external == null ? null : lanTimeout,
      );
    } on SynoNetworkError catch (e) {
      if (external == null || e.statusCode != null) rethrow;
      await _queryApiInfo(Uri.parse(external));
    }
  }

  Future<void> _queryApiInfo(Uri base, {Duration? timeout}) async {
    // Info selbst ist immer v1 – die einzige fest verdrahtete Version.
    final data = await _send(
      base,
      'SYNO.API.Info',
      'query',
      {'query': 'ALL'},
      version: 1,
      path: 'entry.cgi',
      timeout: timeout,
    );
    _apis = {
      for (final MapEntry(:key, :value) in (data as Map).entries)
        key as String: (
          maxVersion: value['maxVersion'] as int,
          path: value['path'] as String,
        ),
    };
    if (_baseUrl != base) {
      _baseUrl = base;
      _activeUrl.add(base);
    }
  }

  /// Ruft [api]/[method] auf und liefert `data` der Antwort.
  Future<dynamic> request(
    String api,
    String method, [
    Map<String, Object?> params = const {},
  ]) => _request(api, method, params, bytes: false);

  /// Wie [request], liefert aber den Rohinhalt (Thumb, Download). API-Fehler
  /// meldet DSM auch hier als JSON.
  Future<Uint8List> requestBytes(
    String api,
    String method, [
    Map<String, Object?> params = const {},
  ]) async => await _request(api, method, params, bytes: true) as Uint8List;

  Future<dynamic> _request(
    String api,
    String method,
    Map<String, Object?> params, {
    required bool bytes,
  }) async {
    final base = _baseUrl;
    if (base == null) throw StateError('connect() fehlt');
    final info = _apis[api];
    // 102 = API existiert nicht, wie DSM es selbst meldet.
    if (info == null) throw SynoException.fromCode(102, api: api);

    Future<dynamic> send() => _send(
      base,
      api,
      method,
      params,
      version: info.maxVersion,
      path: info.path,
      bytes: bytes,
    );

    try {
      return await send();
    } on SynoException catch (e) {
      final relogin = onSessionExpired;
      if (relogin == null ||
          api == 'SYNO.API.Auth' ||
          !SynoException.reloginCodes.contains(e.code)) {
        rethrow;
      }
      // Genau ein Re-Login je Request-Kette; ein zweiter Fehler geht raus.
      await relogin();
      return send();
    }
  }

  Future<dynamic> _send(
    Uri base,
    String api,
    String method,
    Map<String, Object?> params, {
    required int version,
    required String path,
    Duration? timeout,
    bool bytes = false,
  }) async {
    final url = Uri.parse(
      '${base.toString().replaceFirst(RegExp(r'/+$'), '')}/webapi/$path',
    );
    final Response<dynamic> res;
    try {
      res = await _dio.postUri<dynamic>(
        url,
        data: {
          'api': api,
          'version': version,
          'method': method,
          for (final MapEntry(:key, :value) in params.entries) key: ?value,
        },
        options: Options(
          extra: {'timeout': ?timeout},
          responseType: bytes ? ResponseType.bytes : ResponseType.plain,
        ),
      );
    } on DioException catch (e) {
      final cert = _rejected.remove('${url.host}:${url.port}');
      if (cert != null) {
        throw _pins.pinFor(url.host, url.port) == null
            ? UntrustedCertificateException(url.host, url.port, cert)
            : CertificateMismatchException(url.host, url.port, cert);
      }
      // Nur Typen loggen: Fehlermeldungen können die URL mit `_sid` enthalten.
      debugPrint('SynoNetworkError: ${e.type} ${e.error.runtimeType}');
      throw SynoNetworkError(
        statusCode: e.response?.statusCode,
        cause: e.error ?? e.type,
      );
    }
    final Object raw = res.data!;
    if (raw is List<int>) {
      final type = res.headers.value(Headers.contentTypeHeader) ?? '';
      if (!type.contains('json')) return Uint8List.fromList(raw);
    }
    final body = jsonDecode(
      raw is List<int> ? utf8.decode(raw) : raw as String,
    ) as Map<String, dynamic>;
    if (body['success'] == true) return body['data'];
    throw SynoException.fromCode(
      (body['error'] as Map?)?['code'] as int? ?? 100,
      api: api,
    );
  }

  /// Systemprüfung zuerst (System-Roots plus gebündelte öffentliche Roots,
  /// siehe trusted_roots.dart); nur was dort durchfällt, landet hier. Akzeptiert
  /// wird ausschließlich ein exakt gepinnter Fingerprint.
  HttpClient _createHttpClient() =>
      HttpClient(context: trustedSecurityContext())
        ..badCertificateCallback = (cert, host, port) {
          final pinned = _pins.pinFor(host, port);
          if (pinned != null && pinned == certificateFingerprint(cert)) {
            return true;
          }
          _rejected['$host:$port'] = cert;
          return false;
        };

  void close() {
    _dio.close(force: true);
    _activeUrl.close();
  }
}
