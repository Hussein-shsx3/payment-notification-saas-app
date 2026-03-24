import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api_client.dart';
import 'auth_storage.dart';
import 'register_outcome.dart';
import '../../features/notifications/services/android_notification_capture_service.dart';
import '../../features/notifications/services/system_inbox_tray_notifier.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider()
      : _storage = AuthStorage(),
        _isLoading = true,
        _isAuthenticated = false,
        _isViewerMode = false {
    _api = ApiClient(
      getAccessToken: _storage.getAccessToken,
      getRefreshToken: _storage.getRefreshToken,
      saveTokens: (accessToken, refreshToken) =>
          _storage.saveTokensPreservingMode(accessToken: accessToken, refreshToken: refreshToken),
      onRefreshFailed: _handleRefreshFailed,
    );
    _init();
  }

  void _handleRefreshFailed() {
    if (_isAuthenticated) {
      logout();
    }
  }

  final AuthStorage _storage;
  late final ApiClient _api;
  final AndroidNotificationCaptureService _captureService =
      AndroidNotificationCaptureService();

  bool _isLoading;
  bool _isAuthenticated;
  bool _isViewerMode;
  String? _errorMessage;
  bool? _subscriptionActive;
  Timer? _subscriptionPollTimer;

  /// Poll server so admin changes (e.g. clear subscription) apply without restart.
  static const Duration _subscriptionPollInterval = Duration(seconds: 30);

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isViewerMode => _isViewerMode;
  String? get errorMessage => _errorMessage;
  bool get isSubscriptionActive => _subscriptionActive == true;
  ApiClient get api => _api;

  Future<void> refreshSubscription() async {
    if (!_isAuthenticated) {
      _subscriptionActive = null;
      notifyListeners();
      return;
    }
    if (_isViewerMode) {
      _subscriptionActive = null;
      notifyListeners();
      return;
    }
    try {
      final res = await _api.get('/users/profile');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        _subscriptionActive = data?['isSubscriptionActive'] == true;
      }
    } catch (_) {
      // leave previous value
    }
    if (_subscriptionActive == true) {
      await _captureService.start();
    } else {
      await _captureService.stop();
    }
    notifyListeners();
  }

  void _startSubscriptionPolling() {
    _subscriptionPollTimer?.cancel();
    if (!_isAuthenticated) return;
    _subscriptionPollTimer = Timer.periodic(_subscriptionPollInterval, (_) {
      if (_isAuthenticated) {
        unawaited(refreshSubscription());
      }
    });
  }

  void _stopSubscriptionPolling() {
    _subscriptionPollTimer?.cancel();
    _subscriptionPollTimer = null;
  }

  @override
  void dispose() {
    _stopSubscriptionPolling();
    SystemInboxTrayNotifier.instance.stop();
    super.dispose();
  }

  Future<void> _init() async {
    final accessToken = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();
    _isViewerMode = (await _storage.getAccessMode()) == AuthStorage.accessModeViewer;
    _isAuthenticated = accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
    if (_isAuthenticated) {
      if (!_isViewerMode) {
        await _storage.mirrorSecureTokensToSharedPreferences();
        await refreshSubscription();
        _startSubscriptionPolling();
        unawaited(SystemInboxTrayNotifier.instance.start(_api));
      } else {
        _subscriptionActive = null;
        SystemInboxTrayNotifier.instance.stop();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.post('/auth/login', body: {
        'email': emailOrPhone.trim(),
        'password': password,
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String? ?? '';
        final refreshToken = data['refreshToken'] as String? ?? '';

        await _storage.saveSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          accessMode: AuthStorage.accessModeFull,
        );
        _isAuthenticated = true;
        _isViewerMode = false;
        await refreshSubscription();
        _startSubscriptionPolling();
        unawaited(SystemInboxTrayNotifier.instance.start(_api));
        notifyListeners();
        return true;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      _errorMessage = body['message']?.toString() ?? 'Login failed';
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginViewer({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.post('/auth/login-viewer', body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String? ?? '';
        final refreshToken = data['refreshToken'] as String? ?? '';

        await _storage.saveSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          accessMode: AuthStorage.accessModeViewer,
        );
        _isAuthenticated = true;
        _isViewerMode = true;
        _subscriptionActive = null;
        _stopSubscriptionPolling();
        SystemInboxTrayNotifier.instance.stop();
        notifyListeners();
        return true;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      _errorMessage = body['message']?.toString() ?? 'Login failed';
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<RegisterOutcome> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String locale = 'en',
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.post('/auth/register', body: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phoneNumber': phoneNumber.trim(),
        'password': password,
        'locale': locale,
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final needs = body['requiresEmailVerification'] == true;
        final explicitFailed = body['verificationEmailSent'] == false;
        return RegisterOutcome(
          success: true,
          needsEmailVerification: needs,
          verificationEmailSent: !explicitFailed,
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      _errorMessage = body['message']?.toString() ?? 'Registration failed';
      notifyListeners();
      return RegisterOutcome(success: false, errorMessage: _errorMessage);
    } catch (_) {
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return RegisterOutcome(success: false, errorMessage: _errorMessage);
    }
  }

  /// Confirms email using the 6-digit code (or legacy token).
  Future<bool> verifyEmail(String code) async {
    try {
      final response = await _api.post('/auth/verify-email', body: {
        'code': code.trim(),
      });
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// [emailSent] is null when the API omits `verificationEmailSent` (unknown email or already verified — privacy).
  Future<({bool httpOk, bool? emailSent})> resendVerificationEmail(
    String email, {
    String locale = 'en',
  }) async {
    try {
      final response = await _api.post('/auth/resend-verification', body: {
        'email': email.trim(),
        'locale': locale,
      });
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      if (!ok) {
        return (httpOk: false, emailSent: null);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (!body.containsKey('verificationEmailSent')) {
        return (httpOk: true, emailSent: null);
      }
      final ve = body['verificationEmailSent'];
      if (ve is bool) {
        return (httpOk: true, emailSent: ve);
      }
      return (httpOk: true, emailSent: null);
    } catch (_) {
      return (httpOk: false, emailSent: null);
    }
  }

  /// Sends password reset email (24h link). Does not require authentication.
  Future<({bool success, String? errorMessage})> requestPasswordReset({
    required String email,
    required String locale,
  }) async {
    try {
      final response = await _api.post('/auth/forgot-password', body: {
        'email': email.trim().toLowerCase(),
        'locale': locale == 'ar' ? 'ar' : 'en',
      });
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (success: true, errorMessage: null);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (
        success: false,
        errorMessage: body['message']?.toString() ?? 'Request failed',
      );
    } catch (_) {
      return (success: false, errorMessage: 'Network error. Please try again.');
    }
  }

  Future<({bool ok, String? message})> setViewerPassword(String password) async {
    try {
      final response = await _api.put('/users/viewer-password', body: {'password': password});
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (ok: true, message: null);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (ok: false, message: body['message']?.toString() ?? 'Failed');
    } catch (_) {
      return (ok: false, message: 'Network error. Please try again.');
    }
  }

  Future<void> logout() async {
    _stopSubscriptionPolling();
    SystemInboxTrayNotifier.instance.stop();
    await _storage.clearTokens();
    _isAuthenticated = false;
    _isViewerMode = false;
    _subscriptionActive = null;
    notifyListeners();
    // Do not block the UI on notification listener teardown (can stall on some devices).
    unawaited(
      _captureService.stop().timeout(
            const Duration(seconds: 3),
            onTimeout: () {},
          ),
    );
  }
}
