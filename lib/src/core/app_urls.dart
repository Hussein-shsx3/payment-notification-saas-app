/// Web client base URL (Vercel). Override at build: `--dart-define=WEB_APP_URL=https://your-app.vercel.app`
class AppUrls {
  AppUrls._();

  static const String webAppBase = String.fromEnvironment(
    'WEB_APP_URL',
    defaultValue: 'https://payment-notification-saas-client.vercel.app',
  );

  /// Public verify page — matches server `FRONTEND_URL` + `/app/verify-email`.
  static Uri verifyEmailInBrowser(String email) {
    final base = webAppBase.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base/app/verify-email').replace(
      queryParameters: {'email': email.trim()},
    );
  }
}
