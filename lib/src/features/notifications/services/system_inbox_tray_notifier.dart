import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api_client.dart';

/// Polls [GET /notifications] and shows **Android tray** notifications for new
/// admin/system inbox messages (same data as the in-app bell).
///
/// Does not use Firebase — works with the existing REST API while the app runs
/// (foreground/background). Clears baseline on first run so old messages don't flood.
class SystemInboxTrayNotifier {
  SystemInboxTrayNotifier._();
  static final SystemInboxTrayNotifier instance = SystemInboxTrayNotifier._();

  static const _prefsKey = 'system_inbox_tray_cursor_iso';
  static const _channelId = 'app_system_inbox';
  static const _pollInterval = Duration(seconds: 45);

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  Timer? _timer;
  ApiClient? _api;
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _fln.initialize(const InitializationSettings(android: android, iOS: ios));

    const channel = AndroidNotificationChannel(
      _channelId,
      'Account messages',
      description: 'Alerts for admin and system messages in the app',
      importance: Importance.high,
    );
    final androidPlugin = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.requestNotificationsPermission();
    _initialized = true;
  }

  /// Starts periodic polling. No-op for viewer sessions (caller should not pass viewer api usage).
  Future<void> start(ApiClient api) async {
    await ensureInitialized();
    _api = api;
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => unawaited(_poll()));
    await _poll();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _api = null;
    unawaited(_resetCursor());
  }

  Future<void> _resetCursor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// One-shot poll (e.g. app resumed).
  Future<void> pollNow() async {
    final api = _api;
    if (api == null) return;
    await ensureInitialized();
    await _poll();
  }

  Future<void> _poll() async {
    final api = _api;
    if (api == null) return;
    try {
      final res = await api.get('/notifications?limit=40');
      if (res.statusCode < 200 || res.statusCode >= 300) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final container = body['data'] as Map<String, dynamic>?;
      if (container == null) return;
      final raw = container['data'];
      if (raw is! List || raw.isEmpty) return;

      final items = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      DateTime? maxDt;
      for (final m in items) {
        final c = m['createdAt']?.toString();
        if (c == null) continue;
        final dt = DateTime.tryParse(c);
        if (dt != null && (maxDt == null || dt.isAfter(maxDt))) maxDt = dt;
      }
      if (maxDt == null) return;

      final prefs = await SharedPreferences.getInstance();
      final cursorStr = prefs.getString(_prefsKey);

      if (cursorStr == null) {
        await prefs.setString(_prefsKey, maxDt.toIso8601String());
        return;
      }

      final cursor = DateTime.tryParse(cursorStr);
      if (cursor == null) {
        await prefs.setString(_prefsKey, maxDt.toIso8601String());
        return;
      }

      final fresh = items.where((m) {
        final c = m['createdAt']?.toString();
        final dt = c == null ? null : DateTime.tryParse(c);
        return dt != null && dt.isAfter(cursor);
      }).toList()
        ..sort((a, b) {
          final da = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return da.compareTo(db);
        });

      for (final m in fresh) {
        final title = (m['title'] ?? 'Message').toString();
        final msg = (m['message'] ?? '').toString();
        final id = (m['_id'] ?? '').toString();
        final nid = id.isEmpty ? DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff) : id.hashCode & 0x7fffffff;
        await _showTray(title: title, body: msg, notificationId: nid);
      }

      if (maxDt.isAfter(cursor)) {
        await prefs.setString(_prefsKey, maxDt.toIso8601String());
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _showTray({
    required String title,
    required String body,
    required int notificationId,
  }) async {
    final text = body.length > 300 ? '${body.substring(0, 297)}…' : body;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Account messages',
        channelDescription: 'Alerts for admin and system messages in the app',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _fln.show(notificationId, title, text, details);
  }
}
