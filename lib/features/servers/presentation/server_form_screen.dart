import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/auth/session_manager.dart';
import '../../../core/network/syno_exception.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/presentation/entry_widgets.dart';
import '../domain/server_profile.dart';
import 'certificate_sheet.dart';
import 'server_providers.dart';

/// Ergänzt `https://`, wenn das Schema fehlt; `null` bei ungültiger Adresse.
String? normalizeServerUrl(String input) {
  final raw = input.trim();
  if (raw.contains(RegExp(r'\s'))) return null;
  final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
  if (uri == null ||
      !(uri.scheme == 'https' || uri.scheme == 'http') ||
      uri.host.isEmpty) {
    return null;
  }
  return uri.toString().replaceFirst(RegExp(r'/+$'), '');
}

/// Screen 02: Server hinzufügen bzw. bearbeiten ([serverId]) und anmelden.
/// Kein automatischer Neuversuch bei Login-Fehlern (DSM-Auto-Block).
class ServerFormScreen extends ConsumerStatefulWidget {
  const ServerFormScreen({super.key, this.serverId});

  final int? serverId;

  @override
  ConsumerState<ServerFormScreen> createState() => _ServerFormScreenState();
}

class _ServerFormScreenState extends ConsumerState<ServerFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _lan = TextEditingController();
  final _external = TextEditingController();
  final _user = TextEditingController();
  final _password = TextEditingController();
  late int? _id = widget.serverId;
  bool _remember = false;
  bool _busy = false;
  bool _validated = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (_id case final id?) {
      ref.read(serversProvider.future).then((servers) {
        final p = servers.where((s) => s.id == id).firstOrNull;
        if (p == null || !mounted) return;
        setState(() {
          _name.text = p.name;
          _lan.text = p.lanUrl;
          _external.text = p.externalUrl ?? '';
          _user.text = p.user;
        });
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _lan, _external, _user, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_form.currentState!.validate()) {
      setState(() => _validated = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(serverRepositoryProvider);
    final user = _user.text.trim();
    final password = _password.text;
    SessionManager? session;
    try {
      var profile = ServerProfile(
        id: _id,
        name: _name.text.trim(),
        lanUrl: normalizeServerUrl(_lan.text)!,
        externalUrl: _external.text.trim().isEmpty
            ? null
            : normalizeServerUrl(_external.text),
        user: user,
      );
      // Beim ersten Versuch speichern, danach dasselbe Profil aktualisieren.
      if (_id == null) {
        profile = await repo.add(profile);
        _id = profile.id;
      } else {
        await repo.update(profile);
        if (ref.read(sessionProvider)?.client.profile.id == _id) {
          await ref.read(sessionProvider.notifier).close();
        }
      }
      ref.invalidate(serversProvider);
      if (!mounted) return;
      session = await withCertificateTrust(
        context,
        ref,
        () => repo.connect(profile),
      );
      if (session == null) return;
      final s = session;
      try {
        await s.login(user, password, rememberPassword: _remember);
      } on SynoOtpRequired {
        if (!mounted) return;
        final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              account: '$user @ ${profile.name}',
              onSubmit: (otp, trust) => s.login(
                user,
                password,
                otp: otp,
                rememberPassword: _remember,
                trustDevice: trust,
              ),
            ),
          ),
        );
        if (ok != true) {
          s.client.close();
          return;
        }
      }
      await ref.read(sessionProvider.notifier).activate(s);
      if (mounted) context.go('/files');
    } catch (e) {
      session?.client.close();
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? l10n.validationRequired : null;
    String? url(String? v) => required(v) ?? _optionalUrl(v, l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(_id == null ? l10n.serverAdd : l10n.serverEditTitle),
      ),
      body: Form(
        key: _form,
        autovalidateMode: _error == null && !_validated
            ? AutovalidateMode.disabled
            : AutovalidateMode.onUserInteraction,
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _Field(
                label: l10n.fieldName,
                child: TextFormField(
                  controller: _name,
                  validator: required,
                  textInputAction: TextInputAction.next,
                ),
              ),
              _Field(
                label: l10n.fieldLanUrl,
                child: TextFormField(
                  controller: _lan,
                  validator: url,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: AppTheme.mono(),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: _urlDecoration(_lan.text, l10n.fieldLanUrlHint),
                ),
              ),
              _Field(
                label: l10n.fieldExternalUrl,
                child: TextFormField(
                  controller: _external,
                  validator: (v) => _optionalUrl(v, l10n),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: AppTheme.mono(),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: _urlDecoration(
                    _external.text,
                    l10n.fieldExternalUrlHint,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Field(
                      label: l10n.fieldUser,
                      child: TextFormField(
                        controller: _user,
                        validator: required,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      label: l10n.fieldPassword,
                      child: TextFormField(
                        controller: _password,
                        validator: (v) =>
                            (v ?? '').isEmpty ? l10n.validationRequired : null,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _connect(),
                      ),
                    ),
                  ),
                ],
              ),
              _SwitchCard(
                title: l10n.rememberPassword,
                subtitle: l10n.rememberPasswordHint,
                value: _remember,
                onChanged: (v) => setState(() => _remember = v),
              ),
              const SizedBox(height: 16),
              _NoticeBox(
                icon: Icons.lock_outline,
                text: l10n.httpsInfo,
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ),
      // Fehler direkt über dem Button, damit er ohne Scrollen sichtbar ist.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error case final error?) ...[
                ErrorBox(describeError(error, l10n)),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _busy ? null : _connect,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(l10n.connect),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _optionalUrl(String? v, AppLocalizations l10n) =>
      (v ?? '').trim().isEmpty || normalizeServerUrl(v!) != null
      ? null
      : l10n.validationUrl;

  InputDecoration _urlDecoration(String value, String hint) {
    final http = value.trim().toLowerCase().startsWith('http://');
    return InputDecoration(
      hintText: 'https://', // l10n-ignore: URL-Schema, keine Sprache
      helperText: http ? AppLocalizations.of(context).httpWarning : hint,
      helperMaxLines: 2,
      helperStyle: http ? TextStyle(color: AppColors.errorSoft) : null,
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label, padding: const EdgeInsets.only(bottom: 8)),
        child,
      ],
    ),
  );
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    ),
  );
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      border: Border.all(color: color.withValues(alpha: 0.6)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 14),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// Roter Hinweis für Fehlerzustände (02, 04).
class ErrorBox extends StatelessWidget {
  const ErrorBox(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: AppColors.errorSoft),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: TextStyle(color: AppColors.errorSoft)),
          ),
        ],
      ),
    ),
  );
}

/// Screen 04: OTP-Eingabe. [onSubmit] meldet an; bei Erfolg schließt der
/// Screen mit `true`. Kein automatischer Neuversuch.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.account, required this.onSubmit});

  final String account;
  final Future<void> Function(String otp, bool trustDevice) onSubmit;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  bool _trust = true;
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_code.text, _trust);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.otpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.phone_android,
                color: AppColors.accent,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.otpHeading,
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.otpIntro(widget.account),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SectionLabel(l10n.otpCode, padding: const EdgeInsets.only(bottom: 8)),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            textAlign: TextAlign.center,
            style: AppTheme.mono(
              const TextStyle(fontSize: 28, letterSpacing: 12),
            ),
            decoration: const InputDecoration(counterText: ''),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          _SwitchCard(
            title: l10n.otpRemember,
            subtitle: l10n.otpRememberHint,
            value: _trust,
            onChanged: (v) => setState(() => _trust = v),
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 16),
            ErrorBox(describeError(error, l10n)),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: _busy || _code.text.length != 6 ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(l10n.signIn),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
