import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/format/app_date_format.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  String _status = '--';
  String _start = '--';
  String _end = '--';
  String? _proofUrl;
  String? _proofUploadedAtIso;
  String? _proofReviewedAtIso;
  bool _proofExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
          _start = start == null ? '--' : formatDateDmyFromIso(start);
          _end = end == null ? '--' : formatDateDmyFromIso(end);
          if (statusFromApi != null && statusFromApi.isNotEmpty) {
            _status = statusFromApi == 'active' ? l10n.statusActive : l10n.statusInactive;
          } else if (endDt == null) {
            _status = l10n.statusNoSubscription;
          } else {
            _status = endDt.isAfter(now) ? l10n.statusActive : l10n.statusExpired;
          }
          final u = data['subscriptionPaymentProofUrl']?.toString().trim();
          _proofUrl = u != null && u.isNotEmpty ? u : null;
          final rawAt = data['subscriptionPaymentProofUploadedAt']?.toString();
          _proofUploadedAtIso = rawAt != null && rawAt.isNotEmpty ? rawAt : null;
          final rawRv = data['subscriptionPaymentProofReviewedAt']?.toString();
          _proofReviewedAtIso = rawRv != null && rawRv.isNotEmpty ? rawRv : null;
          _proofExpanded = false;
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

  Future<void> _pickAndUpload(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
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
        padding: const EdgeInsets.all(16),
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
                          if (_proofUrl != null && _proofUrl!.isNotEmpty) ...[
                            TextButton.icon(
                              onPressed: () => setState(() => _proofExpanded = !_proofExpanded),
                              icon: Icon(
                                _proofExpanded ? Icons.expand_less : Icons.expand_more,
                                size: 20,
                                color: const Color(0xFF06B6D4),
                              ),
                              label: Text(
                                _proofExpanded
                                    ? l10n.subscriptionProofHideScreenshot
                                    : l10n.subscriptionProofShowScreenshot,
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFE2E8F0),
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                            if (_proofExpanded) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AspectRatio(
                                  aspectRatio: 16 / 10,
                                  child: Image.network(
                                    _proofUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFF1E293B),
                                      alignment: Alignment.center,
                                      child: Text(l10n.subscriptionProofImageError),
                                    ),
                                  ),
                                ),
                              ),
                              if (_proofUploadedAtIso != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  l10n.subscriptionProofUploadedLabel(
                                    formatDateTimeDmyFromIso(_proofUploadedAtIso!),
                                  ),
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                _proofReviewedAtIso != null
                                    ? l10n.subscriptionProofReviewedByAdmin(
                                        formatDateTimeDmyFromIso(_proofReviewedAtIso!),
                                      )
                                    : l10n.subscriptionProofAwaitingAdmin,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: _proofReviewedAtIso != null
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFFFBBF24),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                          FilledButton.icon(
                            onPressed: _uploading ? null : _showSourcePicker,
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
