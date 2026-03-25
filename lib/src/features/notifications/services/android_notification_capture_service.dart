import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'capture_settings_service.dart';
import 'payment_notification_forwarder.dart';
import 'payment_notification_parser.dart';

class AndroidNotificationCaptureService {
  factory AndroidNotificationCaptureService() => _instance;
  AndroidNotificationCaptureService._internal()
      : _forwarder = PaymentNotificationForwarder(),
        _settings = CaptureSettingsService();

  static final AndroidNotificationCaptureService _instance =
      AndroidNotificationCaptureService._internal();

  final PaymentNotificationForwarder _forwarder;
  final CaptureSettingsService _settings;

  StreamSubscription<dynamic>? _notificationSub;
  StreamSubscription<dynamic>? _connectivitySub;
  Timer? _periodicFlushTimer;
  bool _started = false;
  final ValueNotifier<List<Map<String, dynamic>>> debugEvents =
      ValueNotifier<List<Map<String, dynamic>>>(const []);

  bool get isStarted => _started;

  Future<bool> hasPermission() async {
    final granted = await NotificationListenerService.isPermissionGranted();
    return granted == true;
  }

  Future<void> openPermissionSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS',
    );
    await intent.launch();
  }

  /// Battery / MIUI autostart live under per-app system settings on many OEMs.
  Future<void> openAppDetailsSettings() async {
    final info = await PackageInfo.fromPlatform();
    final intent = AndroidIntent(
      action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
      data: 'package:${info.packageName}',
    );
    await intent.launch();
  }

  Future<void> start() async {
    if (_started) return;

    final ok = await hasPermission();
    if (!ok) {
      return;
    }

    _notificationSub = NotificationListenerService.notificationsStream.listen(
      (dynamic event) async {
        await _handleEvent(event);
      },
      onError: (Object error) {
        // Keep app stable even if listener plugin emits an error.
        // ignore: avoid_print
        print('Notification listener error: $error');
      },
    );

    // Warm-up pass: check active notifications when service starts
    final active = await NotificationListenerService.getActiveNotifications();
    for (final n in active) {
      await _handleEvent(n);
    }

    _connectivitySub = Connectivity().onConnectivityChanged.listen((dynamic result) async {
      if (_hasInternet(result)) {
        await _forwarder.flushQueue();
      }
    });

    _periodicFlushTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _forwarder.flushQueue();
    });

    _started = true;
  }

  Future<void> stop() async {
    await _notificationSub?.cancel();
    await _connectivitySub?.cancel();
    _periodicFlushTimer?.cancel();
    _started = false;
  }

  bool _hasInternet(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    if (result is List<ConnectivityResult>) {
      return result.any((r) => r != ConnectivityResult.none);
    }
    return false;
  }

  // Manual testing helper
  Future<void> simulateCapture() async {
    await _forwarder.sendOrQueue(
      source: 'PalPay',
      title: 'Payment received',
      message: 'You received 10 USD',
      receivedAt: DateTime.now(),
      amount: 10,
      currency: 'USD',
      transactionId: null,
    );
    _pushDebug({
      'time': DateTime.now().toIso8601String(),
      'status': 'manual_test',
      'source': 'PalPay',
      'title': 'Payment received',
      'message': 'You received 10 USD',
    });
  }

  void _pushDebug(Map<String, dynamic> event) {
    final current = List<Map<String, dynamic>>.from(debugEvents.value);
    current.insert(0, event);
    if (current.length > 200) {
      current.removeRange(200, current.length);
    }
    debugEvents.value = current;
  }

  Future<void> _handleEvent(dynamic event) async {
    final packageName = (event.packageName ?? '').toString();
    final title = (event.title ?? '').toString();
    final content = (event.content ?? '').toString();
    if (title.isEmpty && content.isEmpty) return;

    final parsed = PaymentNotificationParser.parse(
      packageName: packageName,
      title: title,
      message: content,
      receivedAt: DateTime.now(),
    );

    if (parsed == null) {
      _pushDebug({
        'time': DateTime.now().toIso8601String(),
        'status': 'ignored',
        'packageName': packageName,
        'title': title,
        'message': content,
        'reason': 'Not recognized as payment notification',
      });
      return;
    }

    final sourceEnabled = await _settings.isEnabled(parsed.source);
    if (!sourceEnabled) {
      _pushDebug({
        'time': DateTime.now().toIso8601String(),
        'status': 'ignored',
        'source': parsed.source,
        'title': parsed.title,
        'message': parsed.message,
        'reason': 'Source disabled in settings',
      });
      return;
    }

    // Server sync is handled by native PaymentNotifyNotificationListenerService (POST
    // /notifications/capture) so capture works when the app is backgrounded. Dart only mirrors
    // parsed results for the in-app debug stream.
    _pushDebug({
      'time': DateTime.now().toIso8601String(),
      'status': 'recognized_native_sync',
      'source': parsed.source,
      'direction': parsed.direction,
      'title': parsed.title,
      'message': parsed.message,
      'amount': parsed.amount,
      'currency': parsed.currency,
      'sender': parsed.sender,
      'transactionId': parsed.transactionId,
      'packageName': packageName,
    });
  }
}

