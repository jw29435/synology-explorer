import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import 'mock_nas.dart';

/// Start: `dart run tool/mock_nas/main.dart --port 5000`
Future<void> main(List<String> args) async {
  final portIndex = args.indexOf('--port');
  final port = portIndex >= 0 ? int.parse(args[portIndex + 1]) : 5000;
  final fixtures = Directory.fromUri(
    Platform.script.resolve('../../test/fixtures'),
  );
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(mockNasHandler(fixtures));
  final server = await io.serve(handler, InternetAddress.loopbackIPv4, port);
  stdout.writeln(
    'Mock-NAS auf http://${server.address.host}:${server.port}/webapi/entry.cgi',
  );
}
