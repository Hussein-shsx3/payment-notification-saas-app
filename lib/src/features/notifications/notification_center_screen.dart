import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';

enum _DateFilter {
  today,
  yesterday,
  last7Days,
  last30Days,
  all,
}

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  bool _loading = true;
  bool _deletingPayments = false;
  String? _error;
  int _paymentPage = 1;
  int _paymentTotalPages = 1;
  int _paymentTotal = 0;
  static const int _paymentLimit = 15;
  _DateFilter _dateFilter = _DateFilter.all;
  List<Map<String, dynamic>> _paymentItems = const [];

  String _getFilterLabel(_DateFilter f) {
    switch (f) {
      case _DateFilter.today:
        return 'Today';
      case _DateFilter.yesterday:
        return 'Yesterday';
      case _DateFilter.last7Days:
        return 'Last 7 days';
      case _DateFilter.last30Days:
        return 'Last 30 days';
      case _DateFilter.all:
        return 'All';
    }
  }

  (DateTime?, DateTime?) _getDateRange() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    switch (_dateFilter) {
      case _DateFilter.today:
        return (todayStart, todayEnd);
      case _DateFilter.yesterday:
        final yesterdayStart = todayStart.subtract(const Duration(days: 1));
        final yesterdayEnd = todayStart.subtract(const Duration(milliseconds: 1));
        return (yesterdayStart, yesterdayEnd);
      case _DateFilter.last7Days:
        final from = todayStart.subtract(const Duration(days: 6));
        return (from, todayEnd);
      case _DateFilter.last30Days:
        final from = todayStart.subtract(const Duration(days: 29));
        return (from, todayEnd);
      case _DateFilter.all:
        return (null, null);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final (from, to) = _getDateRange();
      String query = 'page=$_paymentPage&limit=$_paymentLimit';
      if (from != null) query += '&from=${from.toIso8601String()}';
      if (to != null) query += '&to=${to.toIso8601String()}';

      final paymentsRes = await api.get('/notifications/payments?$query');
      final paymentList = <Map<String, dynamic>>[];

      if (paymentsRes.statusCode >= 200 && paymentsRes.statusCode < 300) {
        final body = jsonDecode(paymentsRes.body) as Map<String, dynamic>;
        final container = body['data'] as Map<String, dynamic>;
        paymentList.addAll(
          (container['data'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _paymentPage = (container['page'] as num?)?.toInt() ?? _paymentPage;
        _paymentTotalPages = (container['totalPages'] as num?)?.toInt() ?? 1;
        _paymentTotal = (container['total'] as num?)?.toInt() ?? paymentList.length;
      } else {
        _error = 'Failed to load payment notifications (${paymentsRes.statusCode}). '
            'Please redeploy backend and try again.';
      }

      setState(() {
        _paymentItems = paymentList;
      });
    } catch (e) {
      setState(() {
        _error = 'Network error while loading payment notifications.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAllPayments() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all payment notifications?'),
        content: const Text(
          'This will permanently remove all payment notifications from your account.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete all')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;

    setState(() => _deletingPayments = true);
    try {
      final api = context.read<AuthProvider>().api;
      await api.delete('/notifications/payments');
      _paymentPage = 1;
      await _load();
    } finally {
      if (mounted) setState(() => _deletingPayments = false);
    }
  }

  Future<void> _deleteSingle(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this notification?'),
        content: const Text('This will permanently remove this payment notification.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;

    try {
      final api = context.read<AuthProvider>().api;
      await api.delete('/notifications/payments/$id');
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete notification')),
        );
      }
    }
  }

  Future<void> _nextPage() async {
    if (_paymentPage >= _paymentTotalPages) return;
    _paymentPage += 1;
    await _load();
  }

  Future<void> _previousPage() async {
    if (_paymentPage <= 1) return;
    _paymentPage -= 1;
    await _load();
  }

  void _onFilterChanged(_DateFilter? value) {
    if (value == null) return;
    setState(() {
      _dateFilter = value;
      _paymentPage = 1;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Center')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Payment notifications',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),

                // Date filter - prominent
                DropdownButtonFormField<_DateFilter>(
                  value: _dateFilter,
                  decoration: const InputDecoration(
                    labelText: 'Show notifications from',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _DateFilter.values
                      .map((f) => DropdownMenuItem(value: f, child: Text(_getFilterLabel(f))))
                      .toList(),
                  onChanged: _onFilterChanged,
                ),
                const SizedBox(height: 16),

                // Pagination & Delete all - clearly visible at top
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$_paymentTotal total · Page $_paymentPage of $_paymentTotalPages',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: _deletingPayments ? null : _deleteAllPayments,
                        child: Text(_deletingPayments ? 'Deleting…' : 'Delete all'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                ],

                if (_paymentItems.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('No payment notifications'),
                      subtitle: Text(
                        'Notifications from the selected period will appear here.',
                      ),
                    ),
                  )
                else
                  ..._paymentItems.map((p) {
                    final id = (p['_id'] ?? '').toString();
                    final amount = p['amount'];
                    final currency = (p['currency'] ?? '').toString();
                    final title = (p['title'] ?? '').toString();
                    final msg = (p['message'] ?? '').toString();
                    final src = (p['source'] ?? '').toString();
                    final receivedAtRaw = (p['receivedAt'] ?? '').toString();
                    final receivedAtParsed = DateTime.tryParse(receivedAtRaw);
                    final receivedAtLabel = receivedAtParsed == null
                        ? ''
                        : receivedAtParsed.toLocal().toString().split('.').first;
                    return Card(
                      child: ListTile(
                        title: Text(title.isEmpty ? 'Payment message' : title),
                        subtitle: Text(
                          'Source: $src\n'
                          'Amount: ${amount ?? '--'} ${currency.isEmpty ? '' : currency}\n'
                          '${receivedAtLabel.isNotEmpty ? 'Received: $receivedAtLabel\n' : ''}'
                          'Message: $msg',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deleteSingle(id),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 16),

                // Pagination controls - clearly visible at bottom
                if (_paymentTotalPages > 1)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _paymentPage > 1 ? _previousPage : null,
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Previous'),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$_paymentPage / $_paymentTotalPages',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _paymentPage < _paymentTotalPages ? _nextPage : null,
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Next'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
