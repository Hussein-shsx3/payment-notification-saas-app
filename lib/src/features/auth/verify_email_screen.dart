import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/app_logo.dart';
import 'login_screen.dart';

/// Enter the 6-digit code from the verification email.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.showEmailDeliveryWarning = false,
  });

  final String email;
  final bool showEmailDeliveryWarning;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;
  bool _resending = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _localeTag(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code.startsWith('ar') ? 'ar' : 'en';
  }

  Future<void> _verifyWith(String raw) async {
    var s = raw.trim();
    final asUri = Uri.tryParse(s);
    if (asUri != null && asUri.hasQuery) {
      s = asUri.queryParameters['code'] ?? asUri.queryParameters['token'] ?? s;
    } else {
      final m = RegExp(r'[?&](?:code|token)=([^&\s]+)').firstMatch(s);
      if (m != null) {
        s = Uri.decodeQueryComponent(m.group(1)!);
      }
    }
    final code = s.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) return;

    setState(() {
      _submitting = true;
      _message = null;
      _success = false;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(code);

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
    final r = await auth.resendVerificationEmail(
      widget.email,
      locale: _localeTag(context),
    );
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

    final defaultPinTheme = PinTheme(
      width: 46,
      height: 54,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
        letterSpacing: 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: const Color(0xFF06B6D4), width: 2),
      ),
    );

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
                      const SizedBox(height: 20),
                      if (_success) ...[
                        Text(
                          l10n.verifySuccess,
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            foregroundColor: const Color(0xFF020617),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: Text(l10n.login),
                        ),
                      ] else ...[
                        Text(
                          l10n.verifyCodeLabel,
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                        const SizedBox(height: 8),
                        Pinput(
                          length: 6,
                          controller: _pinController,
                          focusNode: _focusNode,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: focusedPinTheme,
                          submittedPinTheme: focusedPinTheme,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          autofocus: true,
                          onCompleted: _verifyWith,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.verifyTokenHint,
                          style: const TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            foregroundColor: const Color(0xFF020617),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _submitting
                              ? null
                              : () => _verifyWith(_pinController.text),
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
