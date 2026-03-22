// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'إشعار الدفع';

  @override
  String get loading => 'جاري التحميل…';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get settings => 'الإعدادات';

  @override
  String get subscription => 'الاشتراك';

  @override
  String get notificationCenter => 'مركز الإشعارات';

  @override
  String get emailOrPhone => 'البريد أو الجوال';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signInSubtitle => 'سجّل الدخول بالبريد الإلكتروني أو رقم الجوال.';

  @override
  String get loggingIn => 'جاري الدخول…';

  @override
  String get createNewAccount => 'إنشاء حساب جديد';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get phoneNumber => 'رقم الجوال';

  @override
  String get phoneHint => 'مثال: +9665…';

  @override
  String get createAccount => 'إنشاء الحساب';

  @override
  String get creatingAccount => 'جاري إنشاء الحساب…';

  @override
  String get registerTitle => 'تسجيل';

  @override
  String get registrationSuccess =>
      'تم التسجيل بنجاح. تحقق من بريدك لتأكيد الحساب.';

  @override
  String get verificationEmailNotSent =>
      'تعذّر إرسال بريد التحقق من الخادم. جرّب «إعادة إرسال البريد». تأكد من ضبط Brevo على الخادم (BREVO_API_KEY والمرسل المعتمد).';

  @override
  String get verifyEmailTitle => 'تأكيد البريد الإلكتروني';

  @override
  String get verifyEmailSubtitle =>
      'أرسلنا رمزاً مكوّناً من 6 أرقام إلى بريدك. أدخله أدناه (صالح لمدة 24 ساعة). الرسالة تحتوي تعليمات ورابطاً للتحقق أو إعادة الإرسال من الموقع.';

  @override
  String get verifyCodeLabel => 'أدخل الرمز';

  @override
  String get verifyTokenHint =>
      'اكتب الأرقام الستة من البريد. صلاحية الرمز 24 ساعة.';

  @override
  String get verifyStepsTitle => 'طريقة التحقق';

  @override
  String get verifyStep1 => 'افتح بريدك وابحث عن رسالة «Payment Notify».';

  @override
  String get verifyStep2 =>
      'أدخل الرمز أدناه، أو افتح صفحة التحقق من الرابط في البريد.';

  @override
  String get verifyStep3 =>
      'إذا انتهت صلاحية الرمز، اضغط إعادة الإرسال لرسالة جديدة.';

  @override
  String get verifyOpenInBrowser => 'فتح صفحة التحقق في المتصفح';

  @override
  String get verifyOpenInBrowserHint =>
      'نفس الصفحة الموجودة في البريد — يمكنك إدخال الرمز أو إعادة الإرسال من هناك.';

  @override
  String get verifyButton => 'تأكيد البريد';

  @override
  String get resendVerification => 'إعادة إرسال البريد';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get verifySuccess => 'تم تأكيد البريد. يمكنك تسجيل الدخول الآن.';

  @override
  String get verifyFailed =>
      'الرمز غير صالح أو منتهٍ. حاول مرة أخرى أو أعد إرسال البريد.';

  @override
  String get resendSent => 'إذا كان الحساب يحتاج تأكيداً، أُرسل بريد جديد.';

  @override
  String get resending => 'جاري الإرسال…';

  @override
  String get registrationFailed => 'فشل التسجيل.';

  @override
  String get validationEmailOrPhoneRequired => 'البريد أو الجوال مطلوب';

  @override
  String get validationPasswordRequired => 'كلمة المرور مطلوبة';

  @override
  String get validationFullNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get validationEmailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get validationPhoneRequired => 'رقم الجوال مطلوب';

  @override
  String get accountAndSecurity => 'الحساب والأمان';

  @override
  String get profileSection => 'الملف الشخصي';

  @override
  String get profileSectionDesc =>
      'اسمك ورقم جوالك. يمكنك تسجيل الدخول بالبريد أو الجوال.';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get changePasswordSection => 'تغيير كلمة المرور';

  @override
  String get changePasswordDesc =>
      'استخدم كلمة مرور قوية ولا تعيد استخدامها في مواقع أخرى.';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get saveProfile => 'حفظ الملف';

  @override
  String get saving => 'جاري الحفظ…';

  @override
  String get profileUpdated => 'تم تحديث الملف';

  @override
  String get updatePassword => 'تحديث كلمة المرور';

  @override
  String get updatingPassword => 'جاري التحديث…';

  @override
  String get passwordUpdated => 'تم تحديث كلمة المرور';

  @override
  String get fillPasswordFields => 'أدخل كلمة المرور الحالية والجديدة';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور الجديدتان غير متطابقتين';

  @override
  String get passwordTooShort => 'كلمة المرور الجديدة قصيرة جداً';

  @override
  String get passwordPolicyError =>
      'يجب أن تكون كلمة المرور 8 أحرف على الأقل وتتضمن حرفاً ورقماً ورمزاً خاصاً (مثال: example2026\$).';

  @override
  String get language => 'اللغة';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get reload => 'تحديث';

  @override
  String get paymentCaptureService => 'خدمة التقاط المدفوعات';

  @override
  String get captureInactiveSubscription =>
      'الاشتراك غير فعّال — جدّد الاشتراك للتقاط المدفوعات ومزامنتها.';

  @override
  String get captureRunning => 'يعمل: يستمع لإشعارات المحافظ والبنوك';

  @override
  String get captureStarting => 'جاري البدء…';

  @override
  String get captureNeedPermission =>
      'يلزم السماح بالإشعارات لالتقاط المدفوعات';

  @override
  String get enable => 'تفعيل';

  @override
  String get refreshStatus => 'تحديث الحالة';

  @override
  String get systemNotifications => 'إشعارات النظام';

  @override
  String get subscriptionTileSubtitle => 'عرض الحالة وتاريخ الانتهاء';

  @override
  String get notificationCenterTileSubtitle =>
      'إشعارات الدفع المرسلة إلى البريد المستهدف';

  @override
  String get settingsTileSubtitle => 'الملف والجوال وكلمة المرور واللغة';

  @override
  String get offlineQueueHint =>
      'تُفرغ قائمة الانتظار تلقائياً عند عودة الإنترنت وكل 30 ثانية.';

  @override
  String get subscriptionTitle => 'الاشتراك';

  @override
  String get subscriptionStatusHeading => 'حالة الاشتراك';

  @override
  String statusLabel(String status) {
    return 'الحالة: $status';
  }

  @override
  String startDate(String date) {
    return 'تاريخ البدء: $date';
  }

  @override
  String expirationDate(String date) {
    return 'تاريخ الانتهاء: $date';
  }

  @override
  String get subscriptionFooterNote =>
      'عند الانتهاء، يتوقف إعادة توجيه إشعارات الدفع على الخادم.';

  @override
  String get statusActive => 'فعّال';

  @override
  String get statusInactive => 'غير فعّال';

  @override
  String get statusNoSubscription => 'لا يوجد اشتراك';

  @override
  String get statusExpired => 'منتهٍ';

  @override
  String get failedLoadSubscription => 'تعذّر تحميل بيانات الاشتراك';

  @override
  String get networkErrorSubscription => 'خطأ في الشبكة أثناء تحميل الاشتراك';

  @override
  String get notificationCenterAppBar => 'مركز الإشعارات';

  @override
  String get paymentNotificationsHeading => 'إشعارات الدفع';

  @override
  String get showNotificationsFrom => 'عرض الإشعارات من';

  @override
  String get filterToday => 'اليوم';

  @override
  String get filterYesterday => 'أمس';

  @override
  String get filterLast7 => 'آخر 7 أيام';

  @override
  String get filterLast30 => 'آخر 30 يوماً';

  @override
  String get filterAll => 'الكل';

  @override
  String paginationSummary(int total, int page, int pages) {
    return '$total إجمالي · صفحة $page من $pages';
  }

  @override
  String get deleteAll => 'حذف الكل';

  @override
  String get deleting => 'جاري الحذف…';

  @override
  String get deleteAllPaymentsTitle => 'حذف جميع إشعارات الدفع؟';

  @override
  String get deleteAllPaymentsBody =>
      'سيُزال كل إشعارات الدفع من حسابك نهائياً.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get deleteSingleTitle => 'حذف هذا الإشعار؟';

  @override
  String get deleteSingleBody => 'سيُزال إشعار الدفع هذا نهائياً.';

  @override
  String get delete => 'حذف';

  @override
  String get failedDeleteNotification => 'فشل حذف الإشعار';

  @override
  String get previous => 'السابق';

  @override
  String get next => 'التالي';

  @override
  String get directionSent => 'صادر';

  @override
  String get directionReceived => 'وارد';

  @override
  String get directionUnknown => 'غير معروف';

  @override
  String get markAsReceived => 'تعيين كوارد';

  @override
  String get markAsSent => 'تعيين كصادر';

  @override
  String get paymentMessageFallback => 'رسالة دفع';

  @override
  String sourceAmountLine(
    String source,
    String direction,
    String amount,
    String currency,
  ) {
    return 'المصدر: $source · $direction\nالمبلغ: $amount $currency\n';
  }

  @override
  String timeLine(String time) {
    return 'الوقت: $time\n';
  }

  @override
  String messageLine(String message) {
    return 'الرسالة: $message';
  }

  @override
  String get noPaymentNotifications => 'لا توجد إشعارات دفع';

  @override
  String get noPaymentNotificationsHint => 'ستظهر هنا إشعارات الفترة المحددة.';

  @override
  String failedLoadPayments(int code) {
    return 'فشل تحميل إشعارات الدفع ($code). أعد نشر الخادم وحاول مرة أخرى.';
  }

  @override
  String get networkErrorPayments => 'خطأ في الشبكة أثناء تحميل إشعارات الدفع.';

  @override
  String updateFailed(int code) {
    return 'فشل التحديث ($code)';
  }

  @override
  String get networkError => 'خطأ في الشبكة';

  @override
  String get failedLoadProfile => 'فشل تحميل الملف الشخصي';

  @override
  String get networkErrorProfile => 'خطأ في الشبكة أثناء تحميل الملف';

  @override
  String get couldNotUpdateProfile => 'تعذّر تحديث الملف';

  @override
  String get couldNotChangePassword => 'تعذّر تغيير كلمة المرور';

  @override
  String get systemNotificationsTitle => 'إشعارات النظام';

  @override
  String get noSystemNotifications => 'لا توجد إشعارات نظام';

  @override
  String get markRead => 'تعليم كمقروء';

  @override
  String failedToLoadWithCode(int code) {
    return 'فشل التحميل ($code)';
  }
}
