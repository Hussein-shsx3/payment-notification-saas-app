import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../core/api_client.dart';
import '../../../core/auth/auth_storage.dart';
import 'offline_queue_service.dart';

class PaymentNotificationForwarder {
  PaymentNotificationForwarder()
      : _storage = AuthStorage(),
        _queue = OfflineQueueService();

  final AuthStorage _storage;
  final OfflineQueueService _queue;

  // Avoid forwarding the same Android notification multiple times (listener stream
  // + "warm-up" active notifications can overlap).
  static const String _dedupeBoxName = 'payment_notification_dedupe';
  static const int _dedupeTtlMs = 10 * 60 * 1000; // 10 minutes
  final Map<String, int> _recentKeys = <String, int>{};

  Future<Box<dynamic>> _openDedupeBox() async {
    return Hive.openBox<dynamic>(_dedupeBoxName);
  }

  int _stableHash(String s) {
    // Simple deterministic hash for dedupe key creation (no extra dependencies).
    var h = 0;
    for (final cu in s.codeUnits) {
      h = (h * 31 + cu) & 0x7fffffff;
    }
    return h;
  }

  String _makeDedupeKey({
    required String source,
    required String title,
    required String message,
    double? amount,
    String? currency,
    String? transactionId,
  }) {
    if (transactionId != null && transactionId.trim().isNotEmpty) {
      return 'tx:${transactionId.trim().toLowerCase()}';
    }
    final amt = amount?.toString() ?? 'na';
    final cur = currency?.toUpperCase().trim() ?? 'na';
    final mh = _stableHash(message);
    return 'msg:${source.toLowerCase()}|$title|$amt|$cur|$mh';
  }

  Future<bool> _isDuplicate(String dedupeKey) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final memLast = _recentKeys[dedupeKey];
    if (memLast != null && now - memLast < _dedupeTtlMs) return true;

    final box = await _openDedupeBox();
    final boxLast = box.get(dedupeKey);
    if (boxLast is int && now - boxLast < _dedupeTtlMs) {
      _recentKeys[dedupeKey] = boxLast;
      return true;
    }

    await box.put(dedupeKey, now);
    _recentKeys[dedupeKey] = now;
    return false;
  }

  Future<ApiClient> _client() async {
    return ApiClient(
      getAccessToken: _storage.getAccessToken,
      getRefreshToken: _storage.getRefreshToken,
      saveTokens: (accessToken, refreshToken) =>
          _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken),
    );
  }

  Future<void> sendOrQueue({
    required String source,
    required String title,
    required String message,
    required DateTime receivedAt,
    double? amount,
    String? currency,
    String? transactionId,
  }) async {
    final payload = <String, dynamic>{
      'source': source,
      'title': title,
      'message': message,
      'receivedAt': receivedAt.toIso8601String(),
      if (amount != null) 'amount': amount,
      if (currency != null && currency.isNotEmpty) 'currency': currency,
      if (transactionId != null && transactionId.trim().isNotEmpty)
        'transactionId': transactionId.trim(),
    };

    try {
      final dedupeKey = _makeDedupeKey(
        source: source,
        title: title,
        message: message,
        amount: amount,
        currency: currency,
        transactionId: transactionId,
      );
      if (await _isDuplicate(dedupeKey)) return;

      final client = await _client();
      final response = await client.post('/notifications', body: payload);
      if (response.statusCode >= 500) {
        await _queue.enqueue(payload);
      } else if (response.statusCode < 200 || response.statusCode >= 300) {
        // Do not queue client errors (e.g. invalid payload), they will never succeed on retry.
        // ignore: avoid_print
        print('Dropping notification payload due to non-retryable status ${response.statusCode}');
      }
    } catch (_) {
      final dedupeKey = _makeDedupeKey(
        source: source,
        title: title,
        message: message,
        amount: amount,
        currency: currency,
        transactionId: transactionId,
      );
      if (await _isDuplicate(dedupeKey)) return;
      await _queue.enqueue(payload);
    }
  }

  Future<void> flushQueue() async {
    final pending = await _queue.all();
    if (pending.isEmpty) return;

    final client = await _client();
    final failed = <Map<String, dynamic>>[];

    for (final item in pending) {
      try {
        final response = await client.post('/notifications', body: item);
        if (response.statusCode >= 500) {
          failed.add(item);
        }
      } catch (_) {
        failed.add(item);
      }
    }

    await _queue.clear();
    for (final item in failed) {
      await _queue.enqueue(item);
    }
  }

  String pretty(Map<String, dynamic> item) => jsonEncode(item);
}

