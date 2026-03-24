import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/format/app_date_format.dart';
import 'subscription_bank_payment.dart';
import 'subscription_payment_process.dart';
import 'subscription_plan_choice.dart';
import 'subscription_plan_picker.dart';
import 'subscription_proof_gallery.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = true;
  bool _uploading = false;
  bool _savingPlan = false;
  String? _error;
  String _status = '--';
  String _start = '--';
  String _end = '--';
  List<SubscriptionProofItem> _proofItems = [];
  final Map<String, bool> _proofExpandedMap = {};
  SubscriptionPlanChoice? _planChoice;
  bool _proofImagesVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String _ilsAmountForPlan(SubscriptionPlanChoice plan) {
    final v = plan == SubscriptionPlanChoice.week ? kSubscriptionPriceWeekIls : kSubscriptionPriceMonthIls;
    if (v == v.roundToDouble()) {
      return '₪${v.toInt()}';
    }
    return '₪${v.toStringAsFixed(2)}';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.get('/users/profile');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>;
        final start = data['subscriptionStart']?.toString();
        final end = data['subscriptionEnd']?.toString();
        final statusFromApi = data['subscriptionStatus']?.toString();
        final now = DateTime.now();
        final endDt = end == null ? null : DateTime.tryParse(end);

        setState(() {
          _error = null;
          _proofImagesVisible = false;
          _start = start == null ? '--' : formatDateDmyFromIso(start);
          _end = end == null ? '--' : formatDateDmyFromIso(end);
          if (statusFromApi != null && statusFromApi.isNotEmpty) {
            _status = statusFromApi == 'active' ? l10n.statusActive : l10n.statusInactive;
          } else if (endDt == null) {
            _status = l10n.statusNoSubscription;
          } else {
            _status = endDt.isAfter(now) ? l10n.statusActive : l10n.statusExpired;
          }
          _proofItems = SubscriptionProofItem.parseList(data);
          _proofExpandedMap.clear();
          _planChoice = tryParseSubscriptionPlanChoice(data['subscriptionPlanPreference']?.toString());
        });
        if (mounted) {
          await context.read<AuthProvider>().refreshSubscription();
        }
      } else {
        setState(() => _error = l10n.failedLoadSubscription);
      }
    } catch (_) {
      setState(() => _error = l10n.networkErrorSubscription);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePlan(SubscriptionPlanChoice plan) async {
    if (_savingPlan) return;
    final l10n = AppLocalizations.of(context)!;
    final previous = _planChoice;
    setState(() {
      _savingPlan = true;
      _planChoice = plan;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.put(
        '/users/profile',
        body: {'subscriptionPlanPreference': plan.apiValue},
      );
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.subscriptionPlanSaved)),
          );
        }
        await context.read<AuthProvider>().refreshSubscription();
      } else {
        if (mounted) {
          setState(() => _planChoice = previous);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.subscriptionPlanSaveFailed)),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _planChoice = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.subscriptionPlanSaveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPlan = false);
    }
  }

  void _toggleProofExpanded(String id) {
    setState(() {
      _proofExpandedMap[id] = !(_proofExpandedMap[id] ?? false);
    });
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    if (_planChoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.subscriptionPlanRequiredBeforeUpload)),
      );
      return;
    }
    final api = context.read<AuthProvider>().api;
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      imageQuality: 88,
    );
    if (xfile == null || !mounted) return;

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final bytes = await xfile.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) setState(() => _error = l10n.subscriptionProofTooLarge);
        return;
      }
      final name = xfile.name.isNotEmpty ? xfile.name : 'payment-proof.jpg';
      final file = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: name,
      );
      final res = await api.postMultipart('/users/subscription-payment-proof', file: file);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.subscriptionProofUploadSuccess)),
          );
        }
        await _load();
      } else {
        String msg = l10n.subscriptionProofUploadFailed(res.statusCode);
        try {
          final b = jsonDecode(res.body) as Map<String, dynamic>?;
          final m = b?['message']?.toString();
          if (m != null && m.isNotEmpty) msg = m;
        } catch (_) {}
        if (mounted) setState(() => _error = msg);
      }
    } catch (_) {
      if (mounted) setState(() => _error = l10n.networkErrorSubscription);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _showSourcePicker() async {
    final l10n = AppLocalizations.of(context)!;
    if (_planChoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.subscriptionPlanRequiredBeforeUpload)),
      );
      return;
    }
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF06B6D4)),
              title: Text(l10n.subscriptionProofPickGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFF06B6D4)),
              title: Text(l10n.subscriptionProofPickCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (choice != null && mounted) {
      await _pickAndUpload(choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscriptionTitle)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
            : ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.subscriptionStatusHeading,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(l10n.statusLabel(_status)),
                          Text(l10n.startDate(_start)),
                          Text(l10n.expirationDate(_end)),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            l10n.subscriptionFooterNote,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: const SubscriptionBankPayment(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: const SubscriptionPaymentProcess(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: const SubscriptionPlanPricing(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.subscriptionPlanSelectLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<SubscriptionPlanChoice>(
                                value: _planChoice,
                                hint: Text(
                                  l10n.subscriptionPlanSelectPrompt,
                                  style: const TextStyle(color: Color(0xFF64748B)),
                                ),
                                isExpanded: true,
                                dropdownColor: const Color(0xFF0F172A),
                                style: const TextStyle(
                                  color: Color(0xFFF1F5F9),
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF334155)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF334155)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF06B6D4)),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: SubscriptionPlanChoice.week,
                                    child: Text(l10n.subscriptionPlanSelectWeek),
                                  ),
                                  DropdownMenuItem(
                                    value: SubscriptionPlanChoice.month,
                                    child: Text(l10n.subscriptionPlanSelectMonth),
                                  ),
                                ],
                                onChanged: _savingPlan
                                    ? null
                                    : (v) {
                                        if (v != null) _savePlan(v);
                                      },
                              ),
                              if (_planChoice != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      '${l10n.subscriptionAmountDueLabel}: ',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    Text(
                                      _ilsAmountForPlan(_planChoice!),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF06B6D4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          if (_savingPlan)
                            const Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0x66020617),
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF06B6D4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.subscriptionProofSectionTitle,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.subscriptionProofSectionHint,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.35),
                          ),
                          const SizedBox(height: 12),
                          if (_proofItems.isNotEmpty) ...[
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _proofImagesVisible = !_proofImagesVisible);
                              },
                              icon: Icon(
                                _proofImagesVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                                color: const Color(0xFF06B6D4),
                              ),
                              label: Text(
                                _proofImagesVisible
                                    ? l10n.subscriptionProofToggleHide
                                    : l10n.subscriptionProofToggleShow,
                                style: const TextStyle(
                                  color: Color(0xFF06B6D4),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF334155)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                            if (_proofImagesVisible) ...[
                              const SizedBox(height: 12),
                              SubscriptionProofGallery(
                                items: _proofItems,
                                expandedById: _proofExpandedMap,
                                onToggle: _toggleProofExpanded,
                              ),
                            ],
                            const SizedBox(height: 8),
                          ],
                          FilledButton.icon(
                            onPressed: (_uploading || _planChoice == null) ? null : _showSourcePicker,
                            icon: _uploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF020617)),
                                  )
                                : const Icon(Icons.upload_file_outlined, size: 20),
                            label: Text(_uploading ? l10n.subscriptionProofUploading : l10n.subscriptionProofUploadCta),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF06B6D4),
                              foregroundColor: const Color(0xFF020617),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
