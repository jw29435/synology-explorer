import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/network/certificate_pinning.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import 'server_providers.dart';

/// Führt [action] aus; wirft sie ein [UntrustedCertificateException] (auch
/// bei geändertem, bisher gepinntem Zertifikat), fragt Screen 03 nach. Bei „Vertrauen“ wird der Fingerprint gepinnt und [action]
/// wiederholt, bei „Abbrechen“ kommt `null` zurück.
Future<T?> withCertificateTrust<T>(
  BuildContext context,
  WidgetRef ref,
  Future<T> Function() action,
) async {
  while (true) {
    try {
      return await action();
    } on UntrustedCertificateException catch (cert) {
      if (!context.mounted) return null;
      final trust = await showCertificateSheet(context, cert);
      if (trust != true) return null;
      await ref
          .read(pinStoreProvider)
          .pin(cert.host, cert.port, cert.fingerprint);
    }
  }
}

/// Screen 03: Zertifikat bestätigen (TOFU). Liefert `true` bei „Vertrauen“.
Future<bool?> showCertificateSheet(
  BuildContext context,
  UntrustedCertificateException cert,
) => showModalBottomSheet<bool>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  isDismissible: false,
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final rows = [
      (l10n.certSubject, Text(_dn(cert.subject))),
      (l10n.certIssuer, Text(_dn(cert.issuer))),
      (
        l10n.certValidity,
        Text(
          '${formatDate(cert.validFrom, l10n)} – ${formatDate(cert.validTo, l10n)}',
        ),
      ),
      (l10n.certFingerprint, Text(cert.fingerprint, style: AppTheme.mono())),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const _IconBox(Icons.shield_outlined),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.certTitle,
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (cert is CertificateMismatchException) ...[
              Text(
                l10n.errorCertMismatch(cert.host),
                style: const TextStyle(color: AppColors.errorSoft),
              ),
              const SizedBox(height: 8),
            ],
            Text(l10n.certIntro(cert.host)),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, (label, value)) in rows.indexed)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: i == 0
                          ? null
                          : const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColors.border),
                              ),
                            ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label.toUpperCase(),
                            style: text.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          value,
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.certPinInfo,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surfaceRaised,
                      foregroundColor: AppColors.text,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.certTrust),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);

/// `/CN=synology.com/O=Heim-NAS` → `synology.com · Heim-NAS`.
String _dn(String dn) {
  final parts = [
    for (final part in dn.split(RegExp(r'[/,]')))
      if (part.contains('=')) part.substring(part.indexOf('=') + 1).trim(),
  ];
  return parts.isEmpty ? dn : parts.join(' · ');
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: const Color(0x26F2A93B),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: AppColors.accent),
  );
}
