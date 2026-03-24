/// Parses token from pasted reset URL or raw token string.
String? extractPasswordResetToken(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;

  final direct = Uri.tryParse(s);
  if (direct != null && direct.hasQuery) {
    final t = direct.queryParameters['token'];
    if (t != null && t.isNotEmpty) return t;
  }

  final m = RegExp(r'[?&]token=([^&]+)').firstMatch(s);
  if (m != null) {
    try {
      return Uri.decodeComponent(m.group(1)!);
    } catch (_) {
      return m.group(1);
    }
  }

  final compact = s.replaceAll(RegExp(r'\s+'), '');
  if (compact.length >= 32 && !compact.contains('/') && !compact.contains('?')) {
    return compact;
  }
  return null;
}
