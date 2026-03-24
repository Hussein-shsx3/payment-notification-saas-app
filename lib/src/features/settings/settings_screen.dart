import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/validation/password_policy.dart';
import '../../core/locale/locale_controller.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.viewerMode = false});

  /// Read-only session: language and logout only (no profile or passwords).
  final bool viewerMode;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailDisplay = ValueNotifier<String>('');

  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  final _viewerPwController = TextEditingController();
  final _viewerPwConfirmController = TextEditingController();

  bool _loading = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _savingViewerPassword = false;
  String? _profileMessage;
  String? _passwordMessage;
  String? _viewerPasswordMessage;

  static const _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: Color(0xFF334155)),
  );

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFF020617),
      border: _border,
      enabledBorder: _border,
      focusedBorder: _border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 1.2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailDisplay.dispose();
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    _viewerPwController.dispose();
    _viewerPwConfirmController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _profileMessage = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.get('/users/profile');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>;
        _nameController.text = (data['fullName'] ?? '').toString();
        _phoneController.text = (data['phoneNumber'] ?? '').toString();
        _emailDisplay.value = (data['email'] ?? '').toString();
      } else {
        _profileMessage = l10n.failedLoadProfile;
      }
    } catch (_) {
      _profileMessage = l10n.networkErrorProfile;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _savingProfile = true;
      _profileMessage = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.put('/users/profile', body: {
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      });
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _profileMessage = l10n.profileUpdated;
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _profileMessage = body['message']?.toString() ?? l10n.couldNotUpdateProfile;
      }
    } catch (_) {
      _profileMessage = l10n.networkError;
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _saveViewerPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final next = _viewerPwController.text;
    final confirm = _viewerPwConfirmController.text;
    if (next.isEmpty) {
      setState(() => _viewerPasswordMessage = l10n.fillPasswordFields);
      return;
    }
    if (next != confirm) {
      setState(() => _viewerPasswordMessage = l10n.viewerPasswordMustMatch);
      return;
    }
    if (!isStrongPassword(next)) {
      setState(() => _viewerPasswordMessage = l10n.passwordPolicyError);
      return;
    }
    setState(() {
      _savingViewerPassword = true;
      _viewerPasswordMessage = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final r = await auth.setViewerPassword(next);
      if (!mounted) return;
      setState(() {
        if (r.ok) {
          _viewerPwController.clear();
          _viewerPwConfirmController.clear();
          _viewerPasswordMessage = l10n.viewerPasswordUpdated;
        } else {
          _viewerPasswordMessage = r.message;
        }
      });
    } finally {
      if (mounted) setState(() => _savingViewerPassword = false);
    }
  }

  Future<void> _savePassword() async {
    final l10n = AppLocalizations.of(context)!;
    final current = _currentPwController.text;
    final next = _newPwController.text;
    final confirm = _confirmPwController.text;

    if (current.isEmpty || next.isEmpty) {
      setState(() => _passwordMessage = l10n.fillPasswordFields);
      return;
    }
    if (next != confirm) {
      setState(() => _passwordMessage = l10n.passwordsDoNotMatch);
      return;
    }
    if (!isStrongPassword(next)) {
      setState(() => _passwordMessage = l10n.passwordPolicyError);
      return;
    }

    setState(() {
      _savingPassword = true;
      _passwordMessage = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.put('/users/change-password', body: {
        'currentPassword': current,
        'newPassword': next,
      });
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _currentPwController.clear();
        _newPwController.clear();
        _confirmPwController.clear();
        _passwordMessage = l10n.passwordUpdated;
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _passwordMessage = body['message']?.toString() ?? l10n.couldNotChangePassword;
      }
    } catch (_) {
      _passwordMessage = l10n.networkError;
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCtrl = context.watch<LocaleController>();

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))),
      );
    }

    if (widget.viewerMode) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.settings),
          actions: [
            IconButton(
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(Icons.logout),
              tooltip: l10n.logout,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.viewerReadOnlyBadge,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.language,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<Locale>(
                    segments: [
                      ButtonSegment<Locale>(
                        value: const Locale('en'),
                        label: Text(l10n.languageEnglish),
                      ),
                      ButtonSegment<Locale>(
                        value: const Locale('ar'),
                        label: Text(l10n.languageArabic),
                      ),
                    ],
                    selected: {localeCtrl.locale},
                    onSelectionChanged: (set) {
                      final loc = set.first;
                      localeCtrl.setLocale(loc);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.reload,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            l10n.accountAndSecurity,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.language,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SegmentedButton<Locale>(
                  segments: [
                    ButtonSegment<Locale>(
                      value: const Locale('en'),
                      label: Text(l10n.languageEnglish),
                    ),
                    ButtonSegment<Locale>(
                      value: const Locale('ar'),
                      label: Text(l10n.languageArabic),
                    ),
                  ],
                  selected: {localeCtrl.locale},
                  onSelectionChanged: (set) {
                    final loc = set.first;
                    localeCtrl.setLocale(loc);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.profileSection,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.profileSectionDesc,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 14),
                ValueListenableBuilder<String>(
                  valueListenable: _emailDisplay,
                  builder: (_, email, __) {
                    return InputDecorator(
                      decoration: _fieldDecoration(l10n.emailLabel),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          email.isEmpty ? '—' : email,
                          style: const TextStyle(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration(l10n.fullName),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _fieldDecoration(l10n.phoneNumber, hint: l10n.phoneHint),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _savingProfile ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: const Color(0xFF020617),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_savingProfile ? l10n.saving : l10n.saveProfile),
                ),
                if (_profileMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _profileMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _profileMessage == l10n.profileUpdated
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFF87171),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.changePasswordSection,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.changePasswordDesc,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _currentPwController,
                  obscureText: true,
                  decoration: _fieldDecoration(l10n.currentPassword),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPwController,
                  obscureText: true,
                  decoration: _fieldDecoration(l10n.newPassword),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPwController,
                  obscureText: true,
                  decoration: _fieldDecoration(l10n.confirmPassword),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _savingPassword ? null : _savePassword,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF06B6D4),
                    side: const BorderSide(color: Color(0xFF06B6D4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_savingPassword ? l10n.updatingPassword : l10n.updatePassword),
                ),
                if (_passwordMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _passwordMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _passwordMessage == l10n.passwordUpdated
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFF87171),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.viewerPasswordSection,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.viewerPasswordSectionDesc,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _viewerPwController,
                  obscureText: true,
                  decoration: _fieldDecoration(l10n.viewerPasswordField),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _viewerPwConfirmController,
                  obscureText: true,
                  decoration: _fieldDecoration(l10n.viewerPasswordConfirm),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _savingViewerPassword ? null : _saveViewerPassword,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF06B6D4),
                    side: const BorderSide(color: Color(0xFF06B6D4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_savingViewerPassword ? l10n.updatingPassword : l10n.viewerPasswordSave),
                ),
                if (_viewerPasswordMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _viewerPasswordMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _viewerPasswordMessage == l10n.viewerPasswordUpdated
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFF87171),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
