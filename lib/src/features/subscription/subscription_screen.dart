import 'package:flutter/material.dart';
import 'dart:convert';
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
  String? _error;
  String _status = '--';
  String _start = '--';
  String _end = '--';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscriptionTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
            : Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
