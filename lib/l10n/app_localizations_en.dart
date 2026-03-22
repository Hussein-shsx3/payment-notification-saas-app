// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Payment Notify';

  @override
  String get loading => 'Loading…';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get subscription => 'Subscription';

  @override
  String get notificationCenter => 'Notification Center';

  @override
  String get emailOrPhone => 'Email or phone';

  @override
  String get password => 'Password';

  @override
  String get signInSubtitle => 'Sign in with your email or phone number.';

  @override
  String get loggingIn => 'Logging in…';

  @override
  String get createNewAccount => 'Create new account';

  @override
  String get fullName => 'Full name';

  @override
  String get email => 'Email';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneHint => 'e.g. +9665…';

  @override
  String get createAccount => 'Create account';

  @override
  String get creatingAccount => 'Creating account…';

  @override
  String get registerTitle => 'Register';

  @override
  String get registrationSuccess =>
      'Registration successful. Check your email to verify your account.';

  @override
  String get verificationEmailNotSent =>
      'We could not send the verification email from the server. Try “Resend email” or paste the token if you have it. The server needs Brevo (BREVO_API_KEY and a verified sender) configured.';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String get verifyEmailSubtitle =>
      'We sent a 6-digit code to your address. Enter it below (valid 24 hours). The email also includes English and Arabic instructions and a web link to verify or resend.';

  @override
  String get verifyCodeLabel => 'Enter your code';

  @override
  String get verifyTokenHint =>
      'Type the 6 digits from the email. Codes expire after 24 hours.';

  @override
  String get verifyStepsTitle => 'How to verify';

  @override
  String get verifyStep1 =>
      'Check your inbox for our email from Payment Notify.';

  @override
  String get verifyStep2 =>
      'Enter the 6-digit code below, or open the web page from the email.';

  @override
  String get verifyStep3 =>
      'If the code expired, tap Resend to get a new email.';

  @override
  String get verifyOpenInBrowser => 'Open verification page in browser';

  @override
  String get verifyOpenInBrowserHint =>
      'Same page as in your email — enter the code or resend there too.';

  @override
  String get verifyButton => 'Verify email';

  @override
  String get resendVerification => 'Resend email';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get verifySuccess => 'Email verified. You can sign in now.';

  @override
  String get verifyFailed =>
      'Invalid or expired code. Try again or resend the email.';

  @override
  String get resendSent =>
      'If your account needs verification, a new email was sent.';

  @override
  String get resending => 'Sending…';

  @override
  String get registrationFailed => 'Registration failed.';

  @override
  String get validationEmailOrPhoneRequired => 'Email or phone is required';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get validationFullNameRequired => 'Full name is required';

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationPhoneRequired => 'Phone number is required';

  @override
  String get accountAndSecurity => 'Account & security';

  @override
  String get profileSection => 'Profile';

  @override
  String get profileSectionDesc =>
      'Your name and phone. Sign in with email or phone.';

  @override
  String get emailLabel => 'Email';

  @override
  String get changePasswordSection => 'Change password';

  @override
  String get changePasswordDesc =>
      'Use a strong password you do not reuse elsewhere.';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm new password';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get saving => 'Saving…';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get updatePassword => 'Update password';

  @override
  String get updatingPassword => 'Updating…';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String get fillPasswordFields => 'Fill current and new password';

  @override
  String get passwordsDoNotMatch => 'New passwords do not match';

  @override
  String get passwordTooShort => 'New password is too short';

  @override
  String get passwordPolicyError =>
      'Password must be at least 8 characters and include a letter, a number, and a special character (e.g. example2026\$).';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get reload => 'Reload';

  @override
  String get paymentCaptureService => 'Payment capture service';

  @override
  String get captureInactiveSubscription =>
      'Subscription inactive — renew to capture and sync payments.';

  @override
  String get captureRunning =>
      'Running: listening for wallets & bank notifications';

  @override
  String get captureStarting => 'Starting…';

  @override
  String get captureNeedPermission =>
      'Notification access is required to capture payments';

  @override
  String get enable => 'Enable';

  @override
  String get refreshStatus => 'Refresh status';

  @override
  String get systemNotifications => 'System notifications';

  @override
  String get subscriptionTileSubtitle => 'View status and expiry date';

  @override
  String get notificationCenterTileSubtitle =>
      'Payment notifications sent to target email';

  @override
  String get settingsTileSubtitle => 'Profile, phone, password, and language';

  @override
  String get offlineQueueHint =>
      'Offline queue auto-flushes when internet returns and every 30s.';

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get subscriptionStatusHeading => 'Subscription status';

  @override
  String statusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String startDate(String date) {
    return 'Start date: $date';
  }

  @override
  String expirationDate(String date) {
    return 'Expiration date: $date';
  }

  @override
  String get subscriptionFooterNote =>
      'If expired, payment notification forwarding is disabled on server.';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get statusNoSubscription => 'No subscription';

  @override
  String get statusExpired => 'Expired';

  @override
  String get failedLoadSubscription => 'Failed to load subscription data';

  @override
  String get networkErrorSubscription =>
      'Network error while loading subscription';

  @override
  String get notificationCenterAppBar => 'Notification Center';

  @override
  String get paymentNotificationsHeading => 'Payment notifications';

  @override
  String get showNotificationsFrom => 'Show notifications from';

  @override
  String get filterToday => 'Today';

  @override
  String get filterYesterday => 'Yesterday';

  @override
  String get filterLast7 => 'Last 7 days';

  @override
  String get filterLast30 => 'Last 30 days';

  @override
  String get filterAll => 'All';

  @override
  String paginationSummary(int total, int page, int pages) {
    return '$total total · Page $page of $pages';
  }

  @override
  String get deleteAll => 'Delete all';

  @override
  String get deleting => 'Deleting…';

  @override
  String get deleteAllPaymentsTitle => 'Delete all payment notifications?';

  @override
  String get deleteAllPaymentsBody =>
      'This will permanently remove all payment notifications from your account.';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteSingleTitle => 'Delete this notification?';

  @override
  String get deleteSingleBody =>
      'This will permanently remove this payment notification.';

  @override
  String get delete => 'Delete';

  @override
  String get failedDeleteNotification => 'Failed to delete notification';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get directionSent => 'Sent';

  @override
  String get directionReceived => 'Received';

  @override
  String get directionUnknown => 'Unknown';

  @override
  String get markAsReceived => 'Mark as received';

  @override
  String get markAsSent => 'Mark as sent';

  @override
  String get paymentMessageFallback => 'Payment message';

  @override
  String sourceAmountLine(
    String source,
    String direction,
    String amount,
    String currency,
  ) {
    return 'Source: $source · $direction\nAmount: $amount $currency\n';
  }

  @override
  String timeLine(String time) {
    return 'Time: $time\n';
  }

  @override
  String messageLine(String message) {
    return 'Message: $message';
  }

  @override
  String get noPaymentNotifications => 'No payment notifications';

  @override
  String get noPaymentNotificationsHint =>
      'Notifications from the selected period will appear here.';

  @override
  String failedLoadPayments(int code) {
    return 'Failed to load payment notifications ($code). Please redeploy backend and try again.';
  }

  @override
  String get networkErrorPayments =>
      'Network error while loading payment notifications.';

  @override
  String updateFailed(int code) {
    return 'Update failed ($code)';
  }

  @override
  String get networkError => 'Network error';

  @override
  String get failedLoadProfile => 'Failed to load profile';

  @override
  String get networkErrorProfile => 'Network error while loading profile';

  @override
  String get couldNotUpdateProfile => 'Could not update profile';

  @override
  String get couldNotChangePassword => 'Could not change password';

  @override
  String get systemNotificationsTitle => 'System notifications';

  @override
  String get noSystemNotifications => 'No system notifications';

  @override
  String get markRead => 'Mark read';

  @override
  String failedToLoadWithCode(int code) {
    return 'Failed to load ($code)';
  }
}
