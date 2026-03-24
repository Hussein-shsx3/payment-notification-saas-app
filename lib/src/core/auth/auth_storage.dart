import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWTs and whether the session is [full] (main account) or [viewer] (read-only).
class AuthStorage {
  AuthStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessModeKey = 'access_mode';

  static const String accessModeFull = 'full';
  static const String accessModeViewer = 'viewer';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String accessMode,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _accessModeKey, value: accessMode);

    final prefs = await SharedPreferences.getInstance();
    if (accessMode == accessModeFull) {
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
    } else {
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
    }
  }

  /// Used after token refresh — keeps the same access mode as the current session.
  Future<void> saveTokensPreservingMode({
    required String accessToken,
    required String refreshToken,
  }) async {
    final mode = await getAccessMode() ?? accessModeFull;
    await saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessMode: mode,
    );
  }

  Future<String?> getAccessMode() => _storage.read(key: _accessModeKey);

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> mirrorSecureTokensToSharedPreferences() async {
    final mode = await getAccessMode();
    if (mode != accessModeFull) return;

    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    if (accessToken == null || accessToken.isEmpty) return;
    if (refreshToken == null || refreshToken.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _accessModeKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
