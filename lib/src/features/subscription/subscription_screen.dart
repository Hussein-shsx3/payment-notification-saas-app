import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';

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
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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
          _start = start == null ? '--' : _format(start);
          _end = end == null ? '--' : _format(end);
          if (statusFromApi != null && statusFromApi.isNotEmpty) {
            _status = statusFromApi == 'active' ? 'Active' : 'Inactive';
          } else if (endDt == null) {
            _status = 'No subscription';
          } else {
            _status = endDt.isAfter(now) ? 'Active' : 'Expired';
          }
        });
      } else {
        setState(() => _error = 'Failed to load subscription data');
      }
    } catch (_) {
      setState(() => _error = 'Network error while loading subscription');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _format(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '--';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Subscription status',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Status: $_status'),
                      Text('Start date: $_start'),
                      Text('Expiration date: $_end'),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Text(
                        'If expired, payment notification forwarding is disabled on server.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

