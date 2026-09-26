import 'dart:io';

/// `true`, wenn der Host von [url] nur im LAN, per VPN/Tailscale oder lokal
/// erreichbar ist: RFC 1918, 100.64.0.0/10 (CGNAT/Tailscale), Loopback,
/// `fc00::/7`, `*.local`, `*.ts.net` und Hostnamen ohne Punkt.
bool isPrivateHost(String url) {
  final host = Uri.tryParse(url.contains('://') ? url : 'https://$url')?.host
      .toLowerCase();
  if (host == null || host.isEmpty) return false;
  final ip = InternetAddress.tryParse(host);
  if (ip == null) {
    return !host.contains('.') ||
        host.endsWith('.local') ||
        host.endsWith('.ts.net');
  }
  final b = ip.rawAddress;
  if (ip.type == InternetAddressType.IPv6) {
    return ip.isLoopback || b[0] & 0xfe == 0xfc;
  }
  return b[0] == 10 ||
      b[0] == 127 ||
      (b[0] == 172 && b[1] & 0xf0 == 16) ||
      (b[0] == 192 && b[1] == 168) ||
      (b[0] == 100 && b[1] & 0xc0 == 64);
}
