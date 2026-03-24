import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/app_logo.dart';
import 'reset_password_token.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.initialToken});

  /// If provided (e.g. deep link later), token field is prefilled.
  final String? initialToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null && widget.initialToken!.trim().isNotEmpty) {
      _tokenController.text = widget.initialToken!.trim();
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final token = extractPasswordResetToken(_tokenController.text);
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.resetPasswordTokenInvalid)),
      );
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.resetPasswordMismatch)),
      );
      return;
    }

    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    final result = await auth.completePasswordReset(
      token: token,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.resetPasswordSuccess)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AppLogo(size: 52)),
                        const SizedBox(height: 12),
                        Text(
                          l10n.resetPasswordSubtitle,
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tokenController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: l10n.resetPasswordTokenLabel,
                            hintText: l10n.resetPasswordTokenHint,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.validationTokenRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: l10n.resetPasswordNewLabel,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return l10n.passwordTooShort;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: l10n.resetPasswordConfirmLabel,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.validationPasswordRequired;
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
                            _submitting ? l10n.resetPasswordSubmitting : l10n.resetPasswordSubmit,
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
