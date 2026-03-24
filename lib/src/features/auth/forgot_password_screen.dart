import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/app_logo.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final locale = Localizations.localeOf(context).languageCode;
    final auth = context.read<AuthProvider>();
    final result = await auth.requestPasswordReset(
      email: _emailController.text,
      locale: locale,
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (result.success) {
        _sent = true;
      }
    });

    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _sent
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(child: AppLogo(size: 48)),
                            const SizedBox(height: 12),
                            Text(
                              l10n.forgotPasswordSuccess,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                              textAlign: TextAlign.center,
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
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ResetPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(l10n.resetPasswordEnterTokenCta),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(l10n.backToLogin),
                            ),
                          ],
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(child: AppLogo(size: 52)),
                              const SizedBox(height: 12),
                              Text(
                                l10n.forgotPasswordSubtitle,
                                style: const TextStyle(fontSize: 13, color: Colors.white70),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: l10n.email,
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.validationEmailRequired;
                                  }
                                  if (!value.contains('@')) {
                                    return l10n.validationEmailInvalid;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF06B6D4),
                                  foregroundColor: const Color(0xFF020617),
                                  minimumSize: const Size.fromHeight(50),
                                ),
                                onPressed: _submitting ? null : _submit,
                                child: Text(
                                  _submitting ? l10n.forgotPasswordSending : l10n.forgotPasswordSubmit,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              TextButton(
                                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                                child: Text(l10n.backToLogin),
                              ),
                            ],
                          ),
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
