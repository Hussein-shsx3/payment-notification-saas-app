import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/app_urls.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/app_logo.dart';
import 'login_screen.dart';

/// Verification UI aligned with web dashboard: slate/cyan, 6-digit code, resend, open in browser.
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

  static const _bg = Color(0xFF020617);
  static const _panel = Color(0xFF0F172A);
  static const _border = Color(0xFF1E293B);
  static const _accent = Color(0xFF06B6D4);
  static const _text = Color(0xFFF1F5F9);
  static const _muted = Color(0xFF94A3B8);

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

  Future<void> _openVerifyInBrowser() async {
    final uri = AppUrls.verifyEmailInBrowser(widget.email);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        setState(() => _message = 'Could not open browser.');
      }
    } catch (_) {
      if (mounted) setState(() => _message = 'Could not open browser.');
    }
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
      width: 48,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: _accent,
        letterSpacing: 1,
      ),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.25),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.verifyEmailTitle,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero card (matches web verify card)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B1220),
                      Color(0xFF0F172A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(size: 36),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.mark_email_read_outlined,
                            color: _accent,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.verifyEmailSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        height: 1.45,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.alternate_email_rounded, size: 20, color: _accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.email,
                              style: const TextStyle(
                                color: _text,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.showEmailDeliveryWarning) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF422006),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCA8A04)),
                  ),
                  child: Text(
                    l10n.verificationEmailNotSent,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFFEF08A), height: 1.4),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              if (_success) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF052E16).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF4ADE80), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.verifySuccess,
                          style: const TextStyle(color: Color(0xFFBBF7D0), fontSize: 14, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _bg,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(l10n.login, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ] else ...[
                // Steps (like web instructions)
                Text(
                  l10n.verifyStepsTitle,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                _StepLine(index: 1, text: l10n.verifyStep1),
                _StepLine(index: 2, text: l10n.verifyStep2),
                _StepLine(index: 3, text: l10n.verifyStep3),
                const SizedBox(height: 20),

                Text(
                  l10n.verifyCodeLabel,
                  style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                  decoration: BoxDecoration(
                    color: _panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Pinput(
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
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.verifyTokenHint,
                  style: TextStyle(fontSize: 11, color: _muted.withValues(alpha: 0.85), height: 1.35),
                ),

                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openVerifyInBrowser,
                  icon: const Icon(Icons.open_in_browser_rounded, size: 20, color: _accent),
                  label: Text(
                    l10n.verifyOpenInBrowser,
                    style: const TextStyle(color: _accent, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _border),
                    backgroundColor: _panel.withValues(alpha: 0.5),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.verifyOpenInBrowserHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: _muted.withValues(alpha: 0.9), height: 1.35),
                ),

                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _bg,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitting ? null : () => _verifyWith(_pinController.text),
                  child: Text(
                    _submitting ? l10n.loading : l10n.verifyButton,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _resending ? null : _resend,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _border),
                      foregroundColor: _text,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _resending ? l10n.resending : l10n.resendVerification,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(l10n.backToLogin, style: TextStyle(color: _muted.withValues(alpha: 0.95))),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: _message == l10n.resendSent
                          ? const Color(0xFF4ADE80)
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
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.index, required this.text});

  final int index;
  final String text;

  static const _border = Color(0xFF1E293B);
  static const _accent = Color(0xFF06B6D4);
  static const _muted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: _accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
