import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/app_logo.dart';
import 'login_screen.dart';

/// Enter the token from the verification email, or open the link from the email in a browser.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.showEmailDeliveryWarning = false,
  });

  final String email;
  /// True when register/resend indicated the server did not dispatch an email.
  final bool showEmailDeliveryWarning;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _tokenController = TextEditingController();
  bool _submitting = false;
  bool _resending = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  String _normalizeToken(String raw) {
    var t = raw.trim();
    final asUri = Uri.tryParse(t);
    if (asUri != null && asUri.queryParameters.containsKey('token')) {
      return asUri.queryParameters['token'] ?? t;
    }
    final m = RegExp(r'[?&]token=([^&\s]+)').firstMatch(t);
    if (m != null) {
      return Uri.decodeQueryComponent(m.group(1)!);
    }
    return t;
  }

  Future<void> _verify() async {
    final token = _normalizeToken(_tokenController.text);
    if (token.isEmpty) return;

    setState(() {
      _submitting = true;
      _message = null;
      _success = false;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(token);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _success = ok;
      _message = ok ? null : AppLocalizations.of(context)!.verifyFailed;
    });
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _message = null;
    });
    final auth = context.read<AuthProvider>();
    final r = await auth.resendVerificationEmail(widget.email);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _resending = false;
      if (!r.httpOk) {
        _message = l10n.networkError;
      } else if (!r.emailSent) {
        _message = l10n.verificationEmailNotSent;
      } else {
        _message = l10n.resendSent;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyEmailTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppLogo(size: 48)),
                      const SizedBox(height: 12),
                      Text(
                        l10n.verifyEmailSubtitle,
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      if (widget.showEmailDeliveryWarning) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF422006),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCA8A04)),
                          ),
                          child: Text(
                            l10n.verificationEmailNotSent,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFFEF08A)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        widget.email,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF06B6D4)),
                      ),
                      const SizedBox(height: 16),
                      if (_success) ...[
                        Text(
                          l10n.verifySuccess,
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: Text(l10n.login),
                        ),
                      ] else ...[
                        TextField(
                          controller: _tokenController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.verifyTokenLabel,
                            hintText: l10n.verifyTokenHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _submitting ? null : _verify,
                          child: Text(_submitting ? l10n.loading : l10n.verifyButton),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _resending ? null : _resend,
                          child: Text(_resending ? l10n.resending : l10n.resendVerification),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: Text(l10n.backToLogin),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _message!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _message == l10n.resendSent
                                  ? Colors.greenAccent
                                  : _message == l10n.verificationEmailNotSent
                                      ? const Color(0xFFFBBF24)
                                      : Colors.redAccent,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
