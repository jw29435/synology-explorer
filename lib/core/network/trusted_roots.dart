import 'dart:convert';
import 'dart:io';

/// Öffentliche Root-Zertifikate, die ältere Android-Versionen nicht kennen.
///
/// ISRG Root X2 (Let's Encrypt, ECDSA) steckt erst ab Android 14 im System.
/// Let's-Encrypt-Ketten über „Root YE“/„YE2“ enden dort; Android 11 (Samsung
/// A40) lehnt sie sonst ab. Quelle: https://letsencrypt.org/certs/isrg-root-x2.pem,
/// SHA-256 69:72:9B:8E:15:A8:6E:FC:17:7A:57:AF:B7:17:1D:FC:64:AD:D2:8C:2F:CA:8C:F1:50:7E:34:45:3C:CB:14:70,
/// gültig bis 17.09.2040.
const bundledRootsPem = [_isrgRootX2];

/// System-Roots **plus** [extraRootsPem]. Die Prüfung bleibt vollständig
/// aktiv; es kommen nur zusätzliche Vertrauensanker hinzu.
SecurityContext trustedSecurityContext({
  List<String> extraRootsPem = bundledRootsPem,
}) {
  final context = SecurityContext(withTrustedRoots: true);
  for (final pem in extraRootsPem) {
    context.setTrustedCertificatesBytes(utf8.encode(pem));
  }
  return context;
}

const _isrgRootX2 = '''
-----BEGIN CERTIFICATE-----
MIICGzCCAaGgAwIBAgIQQdKd0XLq7qeAwSxs6S+HUjAKBggqhkjOPQQDAzBPMQsw
CQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJuZXQgU2VjdXJpdHkgUmVzZWFyY2gg
R3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBYMjAeFw0yMDA5MDQwMDAwMDBaFw00
MDA5MTcxNjAwMDBaME8xCzAJBgNVBAYTAlVTMSkwJwYDVQQKEyBJbnRlcm5ldCBT
ZWN1cml0eSBSZXNlYXJjaCBHcm91cDEVMBMGA1UEAxMMSVNSRyBSb290IFgyMHYw
EAYHKoZIzj0CAQYFK4EEACIDYgAEzZvVn4CDCuwJSvMWSj5cz3es3mcFDR0HttwW
+1qLFNvicWDEukWVEYmO6gbf9yoWHKS5xcUy4APgHoIYOIvXRdgKam7mAHf7AlF9
ItgKbppbd9/w+kHsOdx1ymgHDB/qo0IwQDAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0T
AQH/BAUwAwEB/zAdBgNVHQ4EFgQUfEKWrt5LSDv6kviejM9ti6lyN5UwCgYIKoZI
zj0EAwMDaAAwZQIwe3lORlCEwkSHRhtFcP9Ymd70/aTSVaYgLXTWNLxBo1BfASdW
tL4ndQavEi51mI38AjEAi/V3bNTIZargCyzuFJ0nN6T5U6VR5CmD1/iQMVtCnwr1
/q4AaOeMSQ+2b1tbFfLn
-----END CERTIFICATE-----
''';
