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
    @visibleForTesting Duration receiveTimeout = const Duration(seconds: 30),
  }) : _dio = Dio(
         BaseOptions(
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: receiveTimeout,
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
        onError: (error, handler) async {
          final options = error.requestOptions;
          if (options.extra[_retriedKey] == true ||
              !isStaleConnection(error) ||
              !isIdempotentRead(options)) {
            return handler.next(error);
          }
          // Tote Keep-alive-Verbindung (z. B. nach WLAN aus/an): genau ein
          // zweiter Versuch über eine neue Verbindung. Nur Lese-Requests –
          // Schreiben könnte doppelt ausgeführt werden, Login zählt beim
          // DSM-Auto-Block.
          options.extra[_retriedKey] = true;
          try {
            handler.resolve(await _dio.fetch<dynamic>(options));
          } on DioException catch (e) {
            handler.next(e);
          }
        },
      ),
    );
  }

  static const _retriedKey = 'staleRetry';

  /// Lese-Requests, die sich gefahrlos wiederholen lassen (je API die
  /// Methoden). Schreibende Methoden und `SYNO.API.Auth` fehlen bewusst.
  static const _idempotent = {
    'SYNO.API.Info': {'query'},
    'SYNO.FileStation.List': {'list', 'list_share', 'getinfo'},
    'SYNO.FileStation.Search': {'list'},
    'SYNO.FileStation.DirSize': {'status'},
    'SYNO.FileStation.Thumb': {'get'},
    'SYNO.FileStation.Download': {'download'},
    'SYNO.FileStation.CopyMove': {'status'},
    'SYNO.FileStation.Delete': {'status'},
    'SYNO.FileStation.MD5': {'status'},
    'SYNO.FileStation.Sharing': {'list', 'getinfo'},
    'SYNO.FileStation.Favorite': {'list'},
  };

  /// API und Methode stehen je nach Aufruf in der Query (GET) oder im
  /// Formular (POST).
  @visibleForTesting
  static bool isIdempotentRead(RequestOptions options) {
    final data = options.data;
    String? field(String key) =>
        (options.queryParameters[key] ?? (data is Map ? data[key] : null))
            ?.toString();
    return _idempotent[field('api')]?.contains(field('method')) ?? false;
  }

  /// Verbindung vor oder beim Header geschlossen bzw. vom Server
  /// zurückgesetzt – typisch für eine wiederverwendete, inzwischen tote
  /// Keep-alive-Verbindung. Timeouts, „Connection refused“, DNS usw. zählen
  /// nicht: Da hilft ein sofortiger zweiter Versuch nichts.
  @visibleForTesting
  static bool isStaleConnection(DioException e) {
    if (e.type == DioExceptionType.cancel ||
        e.type == DioExceptionType.badResponse ||
        e.type == DioExceptionType.badCertificate ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return false;
    }
    return switch (e.error) {
      HttpException(:final message) =>
        message.contains('Connection closed before full header') ||
            message.contains('Connection reset'),
      // ECONNRESET (Linux/Android 104, Darwin 54), EPIPE (32).
      SocketException(:final osError?) => const {
        104,
        54,
        32,
      }.contains(osError.errorCode),
      _ => false,
    };
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

  /// Erneuert die Session (Re-Login) nach [cause]. Wirft, wenn das nicht
  /// still geht.
  Future<void> Function(SynoException cause)? onSessionExpired;

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
  }) => _withRelogin(
    api,
    (base, info) => _send(
      base,
      api,
      method,
      params,
      version: info.maxVersion,
      path: info.path,
      bytes: bytes,
    ),
  );

  /// Führt [send] aus und meldet bei abgelaufener Session genau einmal neu an.
  Future<T> _withRelogin<T>(
    String api,
    Future<T> Function(Uri base, ({int maxVersion, String path}) info) send,
  ) async {
    final base = _baseUrl;
    if (base == null) throw StateError('connect() fehlt');
    final info = _apis[api];
    // 102 = API existiert nicht, wie DSM es selbst meldet.
    if (info == null) throw SynoException.fromCode(102, api: api);

    final usedSid = sid;
    try {
      return await send(base, info);
    } on SynoException catch (e) {
      final relogin = onSessionExpired;
      if (relogin == null ||
          api == 'SYNO.API.Auth' ||
          !SynoException.reloginCodes.contains(e.code)) {
        rethrow;
      }
      // Ein paralleler Request hat die SID schon erneuert: nur wiederholen.
      if (sid != null && sid != usedSid) return send(base, info);
      // Genau ein Re-Login je Request-Kette; ein zweiter Fehler geht raus.
      await relogin(e);
      return send(base, info);
    }
  }

  /// Lädt [api]/[method] (Download) als Datei nach [file]. Mit [offset] > 0
  /// per HTTP-Range ab dieser Stelle und an [file] angehängt; ignoriert das
  /// NAS die Range, beginnt die Datei neu. [onProgress] meldet Bytes der
  /// ganzen Datei. Liefert die Gesamtgröße, falls bekannt.
  Future<int?> download(
    String api,
    String method,
    Map<String, Object?> params,
    File file, {
    int offset = 0,
    CancelToken? cancelToken,
    void Function(int done, int? total)? onProgress,
  }) => _withRelogin(api, (base, info) async {
    final url = _url(base, info.path);
    try {
      final res = await _dio.get<ResponseBody>(
        url.toString(),
        queryParameters: {
          'api': api,
          'version': info.maxVersion,
          'method': method,
          for (final MapEntry(:key, :value) in params.entries) key: ?value,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {if (offset > 0) 'range': 'bytes=$offset-'},
        ),
        cancelToken: cancelToken,
      );
      final body = res.data!;
      final headers = res.headers;
      final data = await _unlessEnvelope(body, headers, api);
      final partial = res.statusCode == 206;
      final range = headers.value('content-range');
      // Teilantwort, die nicht an [offset] anschließt: wie 416 behandeln.
      if (partial &&
          int.tryParse(
                RegExp(r'bytes (\d+)-').firstMatch(range ?? '')?.group(1) ?? '',
              ) !=
              offset) {
        throw const SynoNetworkError(statusCode: 416);
      }
      var done = partial ? offset : 0;
      final length = int.tryParse(headers.value('content-length') ?? '');
      final total = range != null
          ? int.tryParse(range.substring(range.lastIndexOf('/') + 1))
          : (length == null ? null : done + length);
      final sink = file.openWrite(
        mode: partial ? FileMode.append : FileMode.write,
      );
      try {
        await for (final chunk in data) {
          sink.add(chunk);
          done += chunk.length;
          onProgress?.call(done, total);
        }
      } finally {
        await sink.close();
      }
      return total;
    } on DioException catch (e) {
      throw _downloadError(url, e);
    }
  });

  /// Rohinhalt als Stream per GET mit HTTP-Range [start]…[end] (exklusiv),
  /// für Player über den Loopback-Proxy. DSM antwortet mit `206` und
  /// `Content-Range`.
  ///
  /// Ohne Receive-Timeout: Ein pausierter Player liest per Backpressure
  /// beliebig lange nichts. Wer den Stream nicht zu Ende liest, muss
  /// [cancelToken] abbrechen – Abbestellen allein beendet den Transfer nicht.
  Future<ResponseBody> requestStream(
    String api,
    String method,
    Map<String, Object?> params, {
    int start = 0,
    int? end,
    CancelToken? cancelToken,
  }) => _withRelogin(api, (base, info) async {
    final url = _url(base, info.path);
    try {
      final res = await _dio.get<ResponseBody>(
        url.toString(),
        queryParameters: {
          'api': api,
          'version': info.maxVersion,
          'method': method,
          for (final MapEntry(:key, :value) in params.entries) key: ?value,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {'range': 'bytes=$start-${end == null ? '' : end - 1}'},
          // ponytail: auch das Warten auf die Header ist dann ohne Limit;
          // der Verbindungsaufbau hat weiter connectTimeout.
          receiveTimeout: Duration.zero,
        ),
        cancelToken: cancelToken,
      );
      final body = res.data!;
      final data = await _unlessEnvelope(body, res.headers, api);
      return identical(data, body.stream)
          ? body
          : ResponseBody(data.cast(), body.statusCode, headers: body.headers);
    } on DioException catch (e) {
      throw _downloadError(url, e);
    }
  });

  static const _maxEnvelope = 4096;

  /// DSM meldet API-Fehler (z. B. 119) auch bei Downloads als kleinen
  /// JSON-Umschlag `{"success": false, …}` – dann wirft das hier. Eine
  /// heruntergeladene .json-Datei ist keiner und kommt unverändert zurück.
  static Future<Stream<List<int>>> _unlessEnvelope(
    ResponseBody body,
    Headers headers,
    String api,
  ) async {
    final json =
        headers.value(Headers.contentTypeHeader)?.contains('json') ?? false;
    if (!json || body.contentLength > _maxEnvelope) return body.stream;
    final bytes = Uint8List.fromList(
      await body.stream.expand((c) => c).toList(),
    );
    if (_envelope(bytes) == null) return Stream.value(bytes);
    _parse(utf8.decode(bytes), api);
    throw SynoException.fromCode(100, api: api);
  }

  /// DSM-Antwort `{"success": bool, …}` oder `null`, wenn [bytes] kein
  /// solcher Umschlag ist.
  static Map<String, dynamic>? _envelope(List<int> bytes) {
    if (bytes.length > _maxEnvelope) return null;
    try {
      final body = jsonDecode(utf8.decode(bytes));
      return body is Map<String, dynamic> && body['success'] is bool
          ? body
          : null;
    } on FormatException {
      return null;
    }
  }

  /// Lädt [file] als Multipart hoch ([fields] vor der Datei, wie DSM es
  /// verlangt). Liefert `data` der Antwort.
  Future<dynamic> upload(
    String api,
    String method,
    Map<String, Object?> fields,
    File file,
    String filename, {
    CancelToken? cancelToken,
    void Function(int sent, int total)? onProgress,
  }) => _withRelogin(api, (base, info) async {
    final url = _url(base, info.path);
    final Response<String> res;
    try {
      res = await _dio.post<String>(
        url.toString(),
        queryParameters: {
          'api': api,
          'version': info.maxVersion,
          'method': method,
        },
        data: FormData.fromMap({
          for (final MapEntry(:key, :value) in fields.entries) key: ?value,
          'file': await MultipartFile.fromFile(file.path, filename: filename),
        }),
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          // Das NAS antwortet erst, wenn die Datei geschrieben ist.
          receiveTimeout: const Duration(minutes: 5),
        ),
        cancelToken: cancelToken,
        onSendProgress: onProgress,
      );
    } on DioException catch (e) {
      throw _networkError(url, e);
    }
    return _parse(res.data!, api);
  });

  static Uri _url(Uri base, String path) => Uri.parse(
    '${base.toString().replaceFirst(RegExp(r'/+$'), '')}/webapi/$path',
  );

  /// `data` einer DSM-Antwort oder die passende [SynoException]. Datei-
  /// Operationen melden den eigentlichen Grund in `error.errors[0].code`
  /// (z. B. 1100 mit 407 = keine Berechtigung).
  static dynamic _parse(String raw, String api) {
    final body = jsonDecode(raw) as Map<String, dynamic>;
    if (body['success'] == true) return body['data'];
    final error = body['error'] as Map?;
    // Auth meldet unter `errors` eine Map (z. B. OTP-Typen) – nur Listen zählen.
    final errors = error?['errors'];
    final nested = errors is List ? errors.firstOrNull as Map? : null;
    throw SynoException.fromCode(
      nested?['code'] as int? ?? error?['code'] as int? ?? 100,
      api: api,
    );
  }

  /// Wie [_networkError], für `SYNO.FileStation.Download`: DSM meldet eine
  /// fehlende Datei dort mit HTTP 502 und HTML statt JSON (SPIKE M4).
  Exception _downloadError(Uri url, DioException e) =>
      e.response?.statusCode == 502
      ? const SynoNotFound(502)
      : _networkError(url, e);

  Exception _networkError(Uri url, DioException e) {
    final cert = _rejected.remove('${url.host}:${url.port}');
    if (cert != null) {
      return _pins.pinFor(url.host, url.port) == null
          ? UntrustedCertificateException(url.host, url.port, cert)
          : CertificateMismatchException(url.host, url.port, cert);
    }
    // Nur Typen loggen: Fehlermeldungen können die URL mit `_sid` enthalten.
    debugPrint('SynoNetworkError: ${e.type} ${e.error.runtimeType}');
    return SynoNetworkError(
      statusCode: e.response?.statusCode,
      cause: e.error ?? e.type,
    );
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
    final url = _url(base, path);
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
      throw _networkError(url, e);
    }
    final Object raw = res.data!;
    if (raw is List<int>) {
      final type = res.headers.value(Headers.contentTypeHeader) ?? '';
      if (!type.contains('json') || _envelope(raw) == null) {
        return Uint8List.fromList(raw);
      }
    }
    return _parse(raw is List<int> ? utf8.decode(raw) : raw as String, api);
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
