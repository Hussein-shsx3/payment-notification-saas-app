import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/format/app_date_format.dart';
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

  String _getFilterLabel(AppLocalizations l10n, _DateFilter f) {
    switch (f) {
      case _DateFilter.today:
        return l10n.filterToday;
      case _DateFilter.yesterday:
        return l10n.filterYesterday;
      case _DateFilter.last7Days:
        return l10n.filterLast7;
      case _DateFilter.last30Days:
        return l10n.filterLast30;
      case _DateFilter.all:
        return l10n.filterAll;
    }
  }

  String _directionLabel(AppLocalizations l10n, String? d) {
    if (d == 'outgoing') return l10n.directionSent;
    if (d == 'incoming') return l10n.directionReceived;
    return l10n.directionUnknown;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
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
        _error = l10n.failedLoadPayments(paymentsRes.statusCode);
      }

      setState(() {
        _paymentItems = paymentList;
      });
    } catch (_) {
      setState(() {
        _error = l10n.networkErrorPayments;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAllPayments() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllPaymentsTitle),
        content: Text(l10n.deleteAllPaymentsBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.deleteAll)),
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
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSingleTitle),
        content: Text(l10n.deleteSingleBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.delete)),
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
          SnackBar(content: Text(l10n.failedDeleteNotification)),
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

  Future<void> _setPaymentDirection(String id, String direction) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.patch(
        '/notifications/payments/$id/direction',
        body: {'direction': direction},
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await _load();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.updateFailed(res.statusCode))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.networkError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationCenterAppBar)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.paymentNotificationsHeading,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<_DateFilter>(
                  value: _dateFilter,
                  decoration: InputDecoration(
                    labelText: l10n.showNotificationsFrom,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _DateFilter.values
                      .map((f) => DropdownMenuItem(value: f, child: Text(_getFilterLabel(l10n, f))))
                      .toList(),
                  onChanged: _onFilterChanged,
                ),
                const SizedBox(height: 16),
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
                          l10n.paginationSummary(_paymentTotal, _paymentPage, _paymentTotalPages),
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: _deletingPayments ? null : _deleteAllPayments,
                        child: Text(_deletingPayments ? l10n.deleting : l10n.deleteAll),
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
                  Card(
                    child: ListTile(
                      title: Text(l10n.noPaymentNotifications),
                      subtitle: Text(l10n.noPaymentNotificationsHint),
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
                    final direction = (p['direction'] ?? 'unknown').toString();
                    final dirLabel = _directionLabel(l10n, direction);
                    final receivedAtRaw = (p['receivedAt'] ?? '').toString();
                    final receivedAtParsed = DateTime.tryParse(receivedAtRaw);
                    final receivedAtLabel = receivedAtParsed == null
                        ? ''
                        : formatDateTimeDmyFromIso(receivedAtRaw);
                    final amountStr = amount?.toString() ?? '--';
                    final bodyText = StringBuffer()
                      ..write(l10n.sourceAmountLine(src, dirLabel, amountStr, currency))
                      ..write(
                        receivedAtLabel.isNotEmpty ? l10n.timeLine(receivedAtLabel) : '',
                      )
                      ..write(l10n.messageLine(msg));
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title.isEmpty ? l10n.paymentMessageFallback : title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _deleteSingle(id),
                                  tooltip: l10n.delete,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              bodyText.toString(),
                              style: const TextStyle(fontSize: 13, height: 1.35),
                            ),
                            if (direction == 'unknown') ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  TextButton(
                                    onPressed: id.isEmpty ? null : () => _setPaymentDirection(id, 'incoming'),
                                    child: Text(l10n.markAsReceived),
                                  ),
                                  TextButton(
                                    onPressed: id.isEmpty ? null : () => _setPaymentDirection(id, 'outgoing'),
                                    child: Text(l10n.markAsSent),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
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
                          label: Text(l10n.previous),
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
                          label: Text(l10n.next),
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
