import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/viewers/presentation/text_viewer_screen.dart';

void main() {
  Uint8List b(List<int> bytes) => Uint8List.fromList(bytes);

  test('UTF-8, mit und ohne BOM', () {
    expect(decodeText(b(utf8.encode('Grüße'))), 'Grüße');
    expect(decodeText(b([0xEF, 0xBB, 0xBF, ...utf8.encode('Grüße')])), 'Grüße');
  });

  test('Latin-1/Windows-1252 statt kaputter Umlaute', () {
    expect(decodeText(b(latin1.encode('Grüße aus Köln'))), 'Grüße aus Köln');
  });

  test('UTF-16 LE und BE per BOM', () {
    List<int> le(String s) => [
      for (final c in s.codeUnits) ...[c & 0xFF, c >> 8],
    ];
    List<int> be(String s) => [
      for (final c in s.codeUnits) ...[c >> 8, c & 0xFF],
    ];
    expect(decodeText(b([0xFF, 0xFE, ...le('Grüße €')])), 'Grüße €');
    expect(decodeText(b([0xFE, 0xFF, ...be('Grüße €')])), 'Grüße €');
  });
}
