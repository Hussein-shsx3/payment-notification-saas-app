import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api_client.dart';
import 'auth_storage.dart';
import 'register_outcome.dart';
import '../../features/notifications/services/android_notification_capture_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider()
      : _storage = AuthStorage(),
        _isLoading = true,
        _isAuthenticated = false {
    _api = ApiClient(
      getAccessToken: _storage.getAccessToken,
      getRefreshToken: _storage.getRefreshToken,
      saveTokens: (accessToken, refreshToken) =>
          _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken),
      onRefreshFailed: _handleRefreshFailed,
    );
    _init();
  }

  void _handleRefreshFailed() {
    // Refresh token is invalid/expired - user must login again
    // Only logout if we were authenticated (avoid loop during initial load)
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
  String? _errorMessage;
  bool? _subscriptionActive;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  /// Loaded from `GET /users/profile` — capture runs only when `true`.
  bool get isSubscriptionActive => _subscriptionActive == true;
  ApiClient get api => _api;

  /// Refreshes subscription from the server and starts/stops capture accordingly.
  Future<void> refreshSubscription() async {
    if (!_isAuthenticated) {
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

  Future<void> _init() async {
    final accessToken = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();
    _isAuthenticated = accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
    if (_isAuthenticated) {
      await _storage.mirrorSecureTokensToSharedPreferences();
      await refreshSubscription();
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

        await _storage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        _isAuthenticated = true;
        await refreshSubscription();
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
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.post('/auth/register', body: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phoneNumber': phoneNumber.trim(),
        'password': password,
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final needs = body['requiresEmailVerification'] == true;
        final sent = body['verificationEmailSent'] != false;
        return RegisterOutcome(
          success: true,
          needsEmailVerification: needs,
          verificationEmailSent: sent,
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


  /// Confirms email using the token from the verification email (or pasted link query).
  Future<bool> verifyEmail(String token) async {
    try {
      final response = await _api.post('/auth/verify-email', body: {
        'token': token.trim(),
      });
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// [emailSent] is false when the server accepted the request but could not send mail.
  Future<({bool httpOk, bool emailSent})> resendVerificationEmail(String email) async {
    try {
      final response = await _api.post('/auth/resend-verification', body: {
        'email': email.trim(),
      });
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      if (!ok) {
        return (httpOk: false, emailSent: false);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final sent = body['verificationEmailSent'] != false;
      return (httpOk: true, emailSent: sent);
    } catch (_) {
      return (httpOk: false, emailSent: false);
    }
  }

  Future<void> logout() async {
    await _captureService.stop();
    await _storage.clearTokens();
    _isAuthenticated = false;
    _subscriptionActive = null;
    notifyListeners();
  }
}

