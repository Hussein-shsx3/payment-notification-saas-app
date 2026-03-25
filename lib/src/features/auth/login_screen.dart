import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/app_segmented_button_style.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

enum _LoginTab {
  main,
  viewer,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _viewerEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  _LoginTab _tab = _LoginTab.main;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _viewerEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitMain() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
    });

    final auth = context.read<AuthProvider>();
    await auth.login(
      emailOrPhone: _emailOrPhoneController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _submitViewer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
    });

    final auth = context.read<AuthProvider>();
    await auth.loginViewer(
      email: _viewerEmailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = context.watch<AuthProvider>().errorMessage;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.login)),
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
                          l10n.appTitle,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<_LoginTab>(
                          style: appDarkSegmentedButtonStyle(),
                          segments: [
                            ButtonSegment<_LoginTab>(
                              value: _LoginTab.main,
                              label: Text(l10n.loginModeMain),
                              icon: const Icon(Icons.person_outline, size: 18),
                            ),
                            ButtonSegment<_LoginTab>(
                              value: _LoginTab.viewer,
                              label: Text(l10n.loginModeViewer),
                              icon: const Icon(Icons.visibility_outlined, size: 18),
                            ),
                          ],
                          selected: {_tab},
                          onSelectionChanged: _submitting
                              ? null
                              : (s) {
                                  setState(() => _tab = s.first);
                                },
                        ),
                        const SizedBox(height: 14),
                        if (_tab == _LoginTab.main) ...[
                          Text(
                            l10n.signInSubtitle,
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailOrPhoneController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: l10n.emailOrPhone,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final t = value?.trim() ?? '';
                              if (t.isEmpty) return l10n.validationEmailOrPhoneRequired;
                              if (t.contains('@')) {
                                final i = t.indexOf('@');
                                if (i <= 0 || i == t.length - 1) {
                                  return l10n.validationEmailInvalid;
                                }
                                return null;
                              }
                              final digitCount = RegExp(r'\d').allMatches(t).length;
                              if (digitCount < 7) {
                                return l10n.validationEmailOrPhoneInvalid;
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          Text(
                            l10n.viewerLoginSubtitle,
                            style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.35),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _viewerEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: l10n.email,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.validationEmailRequired;
                              }
                              final t = value.trim();
                              if (!t.contains('@')) {
                                return l10n.validationEmailInvalid;
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: _tab == _LoginTab.main ? l10n.password : l10n.password,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.validationPasswordRequired;
                            }
                            return null;
                          },
                        ),
                        if (_tab == _LoginTab.main)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: _submitting
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                              child: Text(l10n.forgotPasswordLink),
                            ),
                          )
                        else
                          const SizedBox(height: 8),
                        if (error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            error,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            foregroundColor: const Color(0xFF020617),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _submitting
                              ? null
                              : (_tab == _LoginTab.main ? _submitMain : _submitViewer),
                          child: Text(
                            _submitting
                                ? l10n.loggingIn
                                : (_tab == _LoginTab.main ? l10n.login : l10n.viewerLoginButton),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                        if (_tab == _LoginTab.main) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _submitting
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                            child: Text(l10n.createNewAccount),
                          ),
                        ],
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
