import 'dart:convert';

import 'package:http/http.dart' as http;

const String apiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'https://payment-notification-saas-server.onrender.com/api');

class ApiClient {
  ApiClient({
    required this.getAccessToken,
    required this.getRefreshToken,
    required this.saveTokens,
    this.onRefreshFailed,
  });

  final Future<String?> Function() getAccessToken;
  final Future<String?> Function() getRefreshToken;
  final Future<void> Function(String accessToken, String refreshToken) saveTokens;
  final void Function()? onRefreshFailed;

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _requestWithOptionalRefresh(
      method: 'GET',
      path: path,
      headers: headers,
    );
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    // Auth endpoints should remain direct.
    if (path.startsWith('/auth/')) {
      final mergedHeaders = <String, String>{
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      };
      return http.post(
        Uri.parse('$apiBaseUrl$path'),
        headers: mergedHeaders,
        body: body == null ? null : jsonEncode(body),
      );
    }

    return _requestWithOptionalRefresh(
      method: 'POST',
      path: path,
      body: body,
      headers: headers,
    );
  }

  Future<http.Response> _requestWithOptionalRefresh({
    required String method,
    required String path,
    Object? body,
    Map<String, String>? headers,
  }) async {
    final token = await getAccessToken();
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (headers != null) ...headers,
    };

    http.Response response;
    if (method == 'GET') {
      response = await http.get(Uri.parse('$apiBaseUrl$path'), headers: mergedHeaders);
    } else if (method == 'PUT') {
      response = await http.put(
        Uri.parse('$apiBaseUrl$path'),
        headers: mergedHeaders,
        body: body == null ? null : jsonEncode(body),
      );
    } else if (method == 'PATCH') {
      response = await http.patch(
        Uri.parse('$apiBaseUrl$path'),
        headers: mergedHeaders,
        body: body == null ? null : jsonEncode(body),
      );
    } else {
      response = await http.post(
        Uri.parse('$apiBaseUrl$path'),
        headers: mergedHeaders,
        body: body == null ? null : jsonEncode(body),
      );
    }

    if (response.statusCode != 401) return response;

    final refreshed = await _tryRefreshToken();
    if (!refreshed) return response;

    final retryToken = await getAccessToken();
    final retryHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (retryToken != null && retryToken.isNotEmpty) 'Authorization': 'Bearer $retryToken',
      if (headers != null) ...headers,
    };

    if (method == 'GET') {
      return http.get(Uri.parse('$apiBaseUrl$path'), headers: retryHeaders);
    }
    if (method == 'PUT') {
      return http.put(
        Uri.parse('$apiBaseUrl$path'),
        headers: retryHeaders,
        body: body == null ? null : jsonEncode(body),
      );
    }
    if (method == 'PATCH') {
      return http.patch(
        Uri.parse('$apiBaseUrl$path'),
        headers: retryHeaders,
        body: body == null ? null : jsonEncode(body),
      );
    }
    return http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: retryHeaders,
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      onRefreshFailed?.call();
      return false;
    }

    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/auth/refresh'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        // Refresh token is invalid or expired - user needs to login again
        onRefreshFailed?.call();
        return false;
      }
      
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final accessToken = data['accessToken']?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString() ?? refresh;
      if (accessToken.isEmpty) {
        onRefreshFailed?.call();
        return false;
      }
      await saveTokens(accessToken, refreshToken);
      return true;
    } catch (_) {
      // Network error - don't trigger logout, let user retry
      return false;
    }
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _requestWithOptionalRefresh(
      method: 'PUT',
      path: path,
      body: body,
      headers: headers,
    );
  }

  Future<http.Response> patch(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _requestWithOptionalRefresh(
      method: 'PATCH',
      path: path,
      body: body,
      headers: headers,
    );
  }

  Future<http.Response> delete(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final token = await getAccessToken();
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (headers != null) ...headers,
    };

    http.Response response = await http.delete(
      Uri.parse('$apiBaseUrl$path'),
      headers: mergedHeaders,
      body: body == null ? null : jsonEncode(body),
    );

    if (response.statusCode != 401) return response;
    final refreshed = await _tryRefreshToken();
    if (!refreshed) return response;

    final retryToken = await getAccessToken();
    final retryHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (retryToken != null && retryToken.isNotEmpty) 'Authorization': 'Bearer $retryToken',
      if (headers != null) ...headers,
    };

    return http.delete(
      Uri.parse('$apiBaseUrl$path'),
      headers: retryHeaders,
      body: body == null ? null : jsonEncode(body),
    );
  }
}

