import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/utils/private_host.dart';

void main() {
  test('private Hosts', () {
    for (final url in [
      'https://10.0.0.5:5001',
      'https://172.16.0.1',
      'https://172.31.255.255',
      'https://192.168.1.20:5001',
      'https://100.64.0.1',
      'https://100.127.255.254:5001',
      'https://127.0.0.1',
      'https://[::1]:5001',
      'https://[fc00::1]',
      'https://[fd12:3456::1]',
      'https://diskstation.local:5001',
      'https://nas.tailnet-abc.ts.net',
      'https://NAS.TS.NET',
      'https://diskstation:5001',
      '192.168.1.20:5001',
    ]) {
      expect(isPrivateHost(url), isTrue, reason: url);
    }
  });

  test('öffentliche Hosts', () {
    for (final url in [
      'https://nas.example.de',
      'https://nas.example.de:5001',
      'https://172.32.0.1',
      'https://172.15.0.1',
      'https://100.128.0.1',
      'https://100.63.255.255',
      'https://8.8.8.8',
      'https://[2001:db8::1]',
      'https://localhost.example.com',
      '',
    ]) {
      expect(isPrivateHost(url), isFalse, reason: url);
    }
  });
}
