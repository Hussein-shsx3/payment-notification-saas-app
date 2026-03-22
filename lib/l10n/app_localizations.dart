import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Notify'**
  String get appTitle;

  /// No description provided for @bottomNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get bottomNavHome;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @notificationCenter.
  ///
  /// In en, this message translates to:
  /// **'Notification Center'**
  String get notificationCenter;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or phone'**
  String get emailOrPhone;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your email or phone number.'**
  String get signInSubtitle;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in…'**
  String get loggingIn;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get createNewAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. +9665…'**
  String get phoneHint;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account…'**
  String get creatingAccount;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// No description provided for @registrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful. Check your email to verify your account.'**
  String get registrationSuccess;

  /// No description provided for @verificationEmailNotSent.
  ///
  /// In en, this message translates to:
  /// **'Could not send the email (server or mail provider). Try again in a moment or contact support if this continues.'**
  String get verificationEmailNotSent;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We emailed a 6-digit code to the address below. Enter it here — it is valid for 24 hours.'**
  String get verifyEmailSubtitle;

  /// No description provided for @verifyCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get verifyCodeLabel;

  /// No description provided for @verifyCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Use the six numbers from the message. You can also paste a link from the email; we will read the code.'**
  String get verifyCodeHint;

  /// No description provided for @verifyStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick steps'**
  String get verifyStepsTitle;

  /// No description provided for @verifyStep1.
  ///
  /// In en, this message translates to:
  /// **'Open the email from Payment Notify (check spam).'**
  String get verifyStep1;

  /// No description provided for @verifyStep2.
  ///
  /// In en, this message translates to:
  /// **'Enter the code here, or open the link in the email in a browser.'**
  String get verifyStep2;

  /// No description provided for @verifyStep3.
  ///
  /// In en, this message translates to:
  /// **'Need a new code? Tap Resend email.'**
  String get verifyStep3;

  /// No description provided for @verifyOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open verification page in browser'**
  String get verifyOpenInBrowser;

  /// No description provided for @verifyOpenInBrowserHint.
  ///
  /// In en, this message translates to:
  /// **'Same page as in your email — enter the code or resend there too.'**
  String get verifyOpenInBrowserHint;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get verifyButton;

  /// No description provided for @resendVerification.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resendVerification;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @verifySuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified. You can sign in now.'**
  String get verifySuccess;

  /// No description provided for @verifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code. Request a new code with Resend email.'**
  String get verifyFailed;

  /// No description provided for @resendSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'A new verification email was sent. Check inbox and spam — code valid 24 hours.'**
  String get resendSentSuccess;

  /// No description provided for @resendNeutral.
  ///
  /// In en, this message translates to:
  /// **'If this email is registered and still unverified, you should get a message soon. Otherwise confirm it matches the address you used to sign up.'**
  String get resendNeutral;

  /// No description provided for @resending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get resending;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed.'**
  String get registrationFailed;

  /// No description provided for @validationEmailOrPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Email or phone is required'**
  String get validationEmailOrPhoneRequired;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get validationFullNameRequired;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get validationPhoneRequired;

  /// No description provided for @accountAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account & security'**
  String get accountAndSecurity;

  /// No description provided for @profileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSection;

  /// No description provided for @profileSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Your name and phone. Sign in with email or phone.'**
  String get profileSectionDesc;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @changePasswordSection.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordSection;

  /// No description provided for @changePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Use a strong password you do not reuse elsewhere.'**
  String get changePasswordDesc;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmPassword;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @updatingPassword.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updatingPassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdated;

  /// No description provided for @fillPasswordFields.
  ///
  /// In en, this message translates to:
  /// **'Fill current and new password'**
  String get fillPasswordFields;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'New password is too short'**
  String get passwordTooShort;

  /// No description provided for @passwordPolicyError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters and include a letter, a number, and a special character (e.g. example2026\$).'**
  String get passwordPolicyError;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @paymentCaptureService.
  ///
  /// In en, this message translates to:
  /// **'Payment capture service'**
  String get paymentCaptureService;

  /// No description provided for @captureInactiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription inactive — renew to capture and sync payments.'**
  String get captureInactiveSubscription;

  /// No description provided for @captureRunning.
  ///
  /// In en, this message translates to:
  /// **'Running: listening for wallets & bank notifications'**
  String get captureRunning;

  /// No description provided for @captureStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get captureStarting;

  /// No description provided for @captureNeedPermission.
  ///
  /// In en, this message translates to:
  /// **'Notification access is required to capture payments'**
  String get captureNeedPermission;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatus;

  /// No description provided for @systemNotifications.
  ///
  /// In en, this message translates to:
  /// **'System notifications'**
  String get systemNotifications;

  /// No description provided for @subscriptionTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View status and expiry date'**
  String get subscriptionTileSubtitle;

  /// No description provided for @notificationCenterTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payment notifications sent to target email'**
  String get notificationCenterTileSubtitle;

  /// No description provided for @settingsTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile, phone, password, and language'**
  String get settingsTileSubtitle;

  /// No description provided for @offlineQueueHint.
  ///
  /// In en, this message translates to:
  /// **'Offline queue auto-flushes when internet returns and every 30s.'**
  String get offlineQueueHint;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionStatusHeading.
  ///
  /// In en, this message translates to:
  /// **'Subscription status'**
  String get subscriptionStatusHeading;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusLabel(String status);

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date: {date}'**
  String startDate(String date);

  /// No description provided for @expirationDate.
  ///
  /// In en, this message translates to:
  /// **'Expiration date: {date}'**
  String expirationDate(String date);

  /// No description provided for @subscriptionFooterNote.
  ///
  /// In en, this message translates to:
  /// **'If expired, payment notification forwarding is disabled on server.'**
  String get subscriptionFooterNote;

  /// No description provided for @subscriptionProofSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment proof'**
  String get subscriptionProofSectionTitle;

  /// No description provided for @subscriptionProofSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a screenshot of your subscription payment so your administrator can verify it. Max 5 MB (JPEG, PNG, WebP).'**
  String get subscriptionProofSectionHint;

  /// No description provided for @subscriptionProofUploadCta.
  ///
  /// In en, this message translates to:
  /// **'Upload payment screenshot'**
  String get subscriptionProofUploadCta;

  /// No description provided for @subscriptionProofUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get subscriptionProofUploading;

  /// No description provided for @subscriptionProofUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment proof uploaded.'**
  String get subscriptionProofUploadSuccess;

  /// No description provided for @subscriptionProofUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed ({code})'**
  String subscriptionProofUploadFailed(int code);

  /// No description provided for @subscriptionProofTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large (max 5 MB).'**
  String get subscriptionProofTooLarge;

  /// No description provided for @subscriptionProofPickGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get subscriptionProofPickGallery;

  /// No description provided for @subscriptionProofPickCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get subscriptionProofPickCamera;

  /// No description provided for @subscriptionProofImageError.
  ///
  /// In en, this message translates to:
  /// **'Could not load image'**
  String get subscriptionProofImageError;

  /// No description provided for @subscriptionProofUploadedLabel.
  ///
  /// In en, this message translates to:
  /// **'Uploaded: {time}'**
  String subscriptionProofUploadedLabel(String time);

  /// No description provided for @subscriptionProofAwaitingAdmin.
  ///
  /// In en, this message translates to:
  /// **'Waiting for admin review of your screenshot.'**
  String get subscriptionProofAwaitingAdmin;

  /// No description provided for @subscriptionProofReviewedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by admin: {time}'**
  String subscriptionProofReviewedByAdmin(String time);

  /// No description provided for @subscriptionProofShowScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Show payment screenshot'**
  String get subscriptionProofShowScreenshot;

  /// No description provided for @subscriptionProofHideScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Hide payment screenshot'**
  String get subscriptionProofHideScreenshot;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @statusNoSubscription.
  ///
  /// In en, this message translates to:
  /// **'No subscription'**
  String get statusNoSubscription;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @failedLoadSubscription.
  ///
  /// In en, this message translates to:
  /// **'Failed to load subscription data'**
  String get failedLoadSubscription;

  /// No description provided for @networkErrorSubscription.
  ///
  /// In en, this message translates to:
  /// **'Network error while loading subscription'**
  String get networkErrorSubscription;

  /// No description provided for @notificationCenterAppBar.
  ///
  /// In en, this message translates to:
  /// **'Notification Center'**
  String get notificationCenterAppBar;

  /// No description provided for @paymentNotificationsHeading.
  ///
  /// In en, this message translates to:
  /// **'Payment notifications'**
  String get paymentNotificationsHeading;

  /// No description provided for @showNotificationsFrom.
  ///
  /// In en, this message translates to:
  /// **'Show notifications from'**
  String get showNotificationsFrom;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get filterYesterday;

  /// No description provided for @filterLast7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get filterLast7;

  /// No description provided for @filterLast30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get filterLast30;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @paginationSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} total · Page {page} of {pages}'**
  String paginationSummary(int total, int page, int pages);

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get deleting;

  /// No description provided for @deleteAllPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all payment notifications?'**
  String get deleteAllPaymentsTitle;

  /// No description provided for @deleteAllPaymentsBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove all payment notifications from your account.'**
  String get deleteAllPaymentsBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteSingleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this notification?'**
  String get deleteSingleTitle;

  /// No description provided for @deleteSingleBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this payment notification.'**
  String get deleteSingleBody;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @failedDeleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete notification'**
  String get failedDeleteNotification;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @directionSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get directionSent;

  /// No description provided for @directionReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get directionReceived;

  /// No description provided for @directionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get directionUnknown;

  /// No description provided for @paymentDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment direction'**
  String get paymentDirectionLabel;

  /// No description provided for @markAsReceived.
  ///
  /// In en, this message translates to:
  /// **'Mark as received'**
  String get markAsReceived;

  /// No description provided for @markAsSent.
  ///
  /// In en, this message translates to:
  /// **'Mark as sent'**
  String get markAsSent;

  /// No description provided for @paymentMessageFallback.
  ///
  /// In en, this message translates to:
  /// **'Payment message'**
  String get paymentMessageFallback;

  /// No description provided for @sourceAmountLine.
  ///
  /// In en, this message translates to:
  /// **'Source: {source} · {direction}\nAmount: {amount} {currency}\n'**
  String sourceAmountLine(
    String source,
    String direction,
    String amount,
    String currency,
  );

  /// No description provided for @timeLine.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}\n'**
  String timeLine(String time);

  /// No description provided for @messageLine.
  ///
  /// In en, this message translates to:
  /// **'Message: {message}'**
  String messageLine(String message);

  /// No description provided for @noPaymentNotifications.
  ///
  /// In en, this message translates to:
  /// **'No payment notifications'**
  String get noPaymentNotifications;

  /// No description provided for @noPaymentNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Notifications from the selected period will appear here.'**
  String get noPaymentNotificationsHint;

  /// No description provided for @failedLoadPayments.
  ///
  /// In en, this message translates to:
  /// **'Failed to load payment notifications ({code}). Please redeploy backend and try again.'**
  String failedLoadPayments(int code);

  /// No description provided for @networkErrorPayments.
  ///
  /// In en, this message translates to:
  /// **'Network error while loading payment notifications.'**
  String get networkErrorPayments;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed ({code})'**
  String updateFailed(int code);

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @supportScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportScreenTitle;

  /// No description provided for @supportHelpText.
  ///
  /// In en, this message translates to:
  /// **'Message our team. Replies appear here; check system notifications for alerts.'**
  String get supportHelpText;

  /// No description provided for @supportWhatsAppHint.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp (if no quick reply in the app):'**
  String get supportWhatsAppHint;

  /// No description provided for @supportTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message…'**
  String get supportTypeMessage;

  /// No description provided for @supportSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get supportSend;

  /// No description provided for @supportNav.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportNav;

  /// No description provided for @supportEmptyThread.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get supportEmptyThread;

  /// No description provided for @supportLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load support.'**
  String get supportLoadError;

  /// No description provided for @supportConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get supportConversation;

  /// No description provided for @supportYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get supportYou;

  /// No description provided for @supportTeam.
  ///
  /// In en, this message translates to:
  /// **'Support team'**
  String get supportTeam;

  /// No description provided for @supportRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get supportRefresh;

  /// No description provided for @supportSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send. Try again.'**
  String get supportSendFailed;

  /// No description provided for @supportWhatsAppIntro.
  ///
  /// In en, this message translates to:
  /// **'For a quicker reply, contact us on WhatsApp.'**
  String get supportWhatsAppIntro;

  /// No description provided for @supportTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Message the team or open WhatsApp'**
  String get supportTileSubtitle;

  /// No description provided for @failedLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get failedLoadProfile;

  /// No description provided for @networkErrorProfile.
  ///
  /// In en, this message translates to:
  /// **'Network error while loading profile'**
  String get networkErrorProfile;

  /// No description provided for @couldNotUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not update profile'**
  String get couldNotUpdateProfile;

  /// No description provided for @couldNotChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Could not change password'**
  String get couldNotChangePassword;

  /// No description provided for @systemNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'System notifications'**
  String get systemNotificationsTitle;

  /// No description provided for @noSystemNotifications.
  ///
  /// In en, this message translates to:
  /// **'No system notifications'**
  String get noSystemNotifications;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get markRead;

  /// No description provided for @failedToLoadWithCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ({code})'**
  String failedToLoadWithCode(int code);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
