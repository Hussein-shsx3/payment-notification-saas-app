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
  String get bottomNavHome => 'الرئيسية';

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
  String get loginModeMain => 'الحساب الرئيسي';

  @override
  String get loginModeViewer => 'عارض';

  @override
  String get viewerLoginSubtitle =>
      'نفس البريد كالحساب الرئيسي. استخدم كلمة مرور العارض من الإعدادات (الحساب الرئيسي). للعرض فقط: قائمة المدفوعات واللغة.';

  @override
  String get viewerLoginButton => 'دخول كعارض';

  @override
  String get viewerReadOnlyBadge => 'جلسة للعرض فقط';

  @override
  String get bottomNavPayments => 'المدفوعات';

  @override
  String get viewerPasswordSection => 'كلمة مرور دخول العارض';

  @override
  String get viewerPasswordSectionDesc =>
      'تسمح لشخص آخر بفتح التطبيق بنفس البريد وكلمة مرور منفصلة لمشاهدة إشعارات الدفع فقط (دون تعديل أو التقاط أو اشتراك).';

  @override
  String get viewerPasswordField => 'كلمة مرور العارض الجديدة';

  @override
  String get viewerPasswordConfirm => 'تأكيد كلمة مرور العارض';

  @override
  String get viewerPasswordSave => 'حفظ كلمة مرور العارض';

  @override
  String get viewerPasswordUpdated => 'تم حفظ كلمة مرور العارض';

  @override
  String get viewerPasswordMustMatch => 'كلمتا مرور العارض غير متطابقتين';

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
      'تعذّر إرسال البريد (الخادم أو مزود البريد). أعد المحاولة لاحقاً أو تواصل مع الدعم إذا استمرّ الأمر.';

  @override
  String get verifyEmailTitle => 'تأكيد البريد الإلكتروني';

  @override
  String get verifyEmailSubtitle =>
      'أرسلنا رمزاً من 6 أرقام إلى البريد أدناه. أدخله هنا — صالح لمدة 24 ساعة.';

  @override
  String get verifyCodeLabel => 'الرمز المكوّن من 6 أرقام';

  @override
  String get verifyCodeHint =>
      'استخدم الأرقام الستة من الرسالة. يمكنك لصق رابط من البريد وسنقرأ الرمز تلقائياً.';

  @override
  String get verifyStepsTitle => 'خطوات سريعة';

  @override
  String get verifyStep1 =>
      'افتح البريد من «Payment Notify» (تحقق من الرسائل غير المرغوبة).';

  @override
  String get verifyStep2 =>
      'أدخل الرمز هنا، أو افتح الرابط في المتصفح من البريد.';

  @override
  String get verifyStep3 => 'تحتاج رمزاً جديداً؟ اضغط إعادة إرسال البريد.';

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
      'الرمز غير صالح أو منتهٍ. اطلب رمزاً جديداً بإعادة إرسال البريد.';

  @override
  String get resendSentSuccess =>
      'أُرسل بريد تحقق جديد. راجع الوارد والرسائل غير المرغوبة — الرمز صالح 24 ساعة.';

  @override
  String get resendNeutral =>
      'إذا كان هذا البريد مسجّلاً ولم يُؤكَّد بعد، ستصلك رسالة قريباً. وإلا تأكد أنه نفس البريد المستخدم عند التسجيل.';

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
  String get validationEmailInvalid => 'أدخل بريداً إلكترونياً صالحاً';

  @override
  String get validationEmailOrPhoneInvalid =>
      'أدخل بريداً صالحاً (يحتوي @) أو رقم جوال لا يقل عن 7 أرقام';

  @override
  String get forgotPasswordLink => 'نسيت كلمة المرور؟';

  @override
  String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotPasswordSubtitle =>
      'أدخل بريد حسابك. سنرسل رابطاً صالحاً لمدة 24 ساعة. ستُعيّن كلمة المرور الجديدة على الموقع وليس داخل التطبيق.';

  @override
  String get forgotPasswordSubmit => 'إرسال رابط الاستعادة';

  @override
  String get forgotPasswordSending => 'جاري الإرسال…';

  @override
  String get forgotPasswordSuccess =>
      'إذا وُجد حساب لهذا البريد، تحقق من الوارد (والبريد غير المرغوب). افتح الرابط في البريد من المتصفح لتعيين كلمة مرور جديدة. ينتهي الرابط خلال 24 ساعة. ثم عد هنا وسجّل الدخول.';

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
  String get captureAndroidReliabilityHint =>
      'قد تمنع بعض الهواتف (شاومي / ريدمي / بوكو) التقاط الخلفية. فعّل التشغيل التلقائي، وضع البطارية بدون قيود، قفل التطبيق في التطبيقات الأخيرة، وتأكد من السماح بإشعارات النظام (بما فيها الإعدادات المقيدة إذا ثبّتت التطبيق خارج المتجر).';

  @override
  String get openAppSettings => 'إعدادات التطبيق';

  @override
  String get subscriptionTitle => 'الاشتراك';

  @override
  String get subscriptionPaymentProcessHeading => 'آلية الدفع';

  @override
  String get subscriptionPaymentProcessIntro =>
      'يُفعّل الاشتراك بعد التحقق من الدفع. يُرجى اتباع الخطوات التالية بالترتيب.';

  @override
  String get subscriptionPaymentProcessStep1 =>
      'اطلع على رسوم الاشتراك أدناه. جميع المبالغ بالشيكل الجديد (₪). الخياران المتاحان: أسبوع أو شهر فقط.';

  @override
  String get subscriptionPaymentProcessStep2 =>
      'حوّل المبلغ الصحيح إلى رقم الحساب البنكي الفلسطيني الموضّح في تفاصيل الدفع أعلاه. يمكنك استخدام تطبيق البنك أو الفرع.';

  @override
  String get subscriptionPaymentProcessStep3 =>
      'حدّد ما إذا كنت تدفع عن أسبوع أو شهر، ثم ارفع لقطة شاشة واضحة للتحويل في قسم إثبات الدفع ليتمكن فريقنا من التحقق وتفعيل اشتراكك.';

  @override
  String get subscriptionBankPaymentHeading => 'تفاصيل الدفع';

  @override
  String get subscriptionBankPaymentBody =>
      'استخدم رقم الحساب البنكي الفلسطيني التالي عند إرسال دفعة الاشتراك. تأكد أن المبلغ يطابق الخطة التي اخترتها (أسبوع أو شهر).';

  @override
  String get subscriptionBankCopyCta => 'نسخ';

  @override
  String get subscriptionBankCopied => 'تم نسخ الرقم';

  @override
  String get subscriptionPlanSelectLabel => 'ما الخطة التي تدفع عنها؟';

  @override
  String get subscriptionPlanSelectPrompt => 'اختر أسبوعاً أو شهراً';

  @override
  String get subscriptionPlanSelectWeek => 'أسبوع';

  @override
  String get subscriptionPlanSelectMonth => 'شهر';

  @override
  String get subscriptionPlanRequiredBeforeUpload =>
      'يُرجى اختيار أسبوع أو شهر قبل رفع لقطة الدفع.';

  @override
  String get subscriptionAmountDueLabel => 'المبلغ المستحق';

  @override
  String get subscriptionProofToggleShow => 'عرض لقطات دفعي';

  @override
  String get subscriptionProofToggleHide => 'إخفاء لقطات الدفع';

  @override
  String get subscriptionPlansHeading => 'رسوم الاشتراك';

  @override
  String get subscriptionPlansSubheading =>
      'خياران فقط — أسبوع أو شهر. الأسعار بالشيكل الجديد (₪).';

  @override
  String get subscriptionPlanWeekTitle => 'أسبوع';

  @override
  String get subscriptionPlanWeekSubtitle => 'وصول لمدة 7 أيام';

  @override
  String get subscriptionPlanMonthTitle => 'شهر';

  @override
  String get subscriptionPlanMonthSubtitle => 'مرن — يمكن الإلغاء لاحقاً';

  @override
  String get subscriptionPlanMonthBadge => 'الأكثر شيوعاً';

  @override
  String get subscriptionPlanYearTitle => 'سنة';

  @override
  String get subscriptionPlanYearSubtitle => 'أفضل قيمة للاستخدام الطويل';

  @override
  String get subscriptionPlanPerWeek => 'في الأسبوع';

  @override
  String get subscriptionPlanPerMonth => 'في الشهر';

  @override
  String get subscriptionPlanPerYear => 'في السنة';

  @override
  String get subscriptionPlanSaved => 'تم حفظ الخطة';

  @override
  String get subscriptionPlanSaveFailed => 'تعذّر حفظ الخطة';

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
  String get subscriptionProofGalleryHeading => 'لقطات الدفع';

  @override
  String get subscriptionProofGalleryHint =>
      'الأحدث أولاً. اضغط البطاقة لإظهار الصورة كاملة أو إخفائها.';

  @override
  String get subscriptionProofItemShowFull => 'عرض الصورة كاملة';

  @override
  String get subscriptionProofItemHideFull => 'إخفاء الصورة الكاملة';

  @override
  String get subscriptionProofSectionTitle => 'إثبات الدفع';

  @override
  String get subscriptionProofSectionHint =>
      'أولاً اختر أسبوعاً أو شهراً أعلاه ليعرف المسؤول ما الذي دفعت عنه. ثم ارفع لقطة شاشة للتحويل. بحد أقصى 5 ميجابايت (JPEG أو PNG أو WebP).';

  @override
  String get subscriptionProofUploadCta => 'رفع لقطة الدفع';

  @override
  String get subscriptionProofUploading => 'جاري الرفع…';

  @override
  String get subscriptionProofUploadSuccess => 'تم رفع إثبات الدفع.';

  @override
  String subscriptionProofUploadFailed(int code) {
    return 'فشل الرفع ($code)';
  }

  @override
  String get subscriptionProofTooLarge =>
      'الصورة كبيرة جداً (الحد 5 ميجابايت).';

  @override
  String get subscriptionProofPickGallery => 'اختيار من المعرض';

  @override
  String get subscriptionProofPickCamera => 'التقاط صورة';

  @override
  String get subscriptionProofImageError => 'تعذّر تحميل الصورة';

  @override
  String subscriptionProofUploadedLabel(String time) {
    return 'تاريخ الرفع: $time';
  }

  @override
  String get subscriptionProofAwaitingAdmin =>
      'في انتظار مراجعة المسؤول للقطة.';

  @override
  String subscriptionProofReviewedByAdmin(String time) {
    return 'راجعها المسؤول: $time';
  }

  @override
  String get subscriptionProofShowScreenshot => 'إظهار لقطة الدفع';

  @override
  String get subscriptionProofHideScreenshot => 'إخفاء لقطة الدفع';

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
  String get paymentDirectionLabel => 'اتجاه الدفع';

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
  String get supportScreenTitle => 'الدعم';

  @override
  String get supportHelpText =>
      'راسل فريقنا. تظهر الردود هنا؛ راقب إشعارات النظام للتنبيهات.';

  @override
  String get supportWhatsAppHint => 'واتساب (إذا لم يصل رد سريع في التطبيق):';

  @override
  String get supportTypeMessage => 'رسالتك…';

  @override
  String get supportSend => 'إرسال';

  @override
  String get supportNav => 'الدعم';

  @override
  String get supportEmptyThread => 'لا رسائل بعد.';

  @override
  String get supportLoadError => 'تعذّر تحميل الدعم.';

  @override
  String get supportConversation => 'المحادثة';

  @override
  String get supportYou => 'أنت';

  @override
  String get supportTeam => 'فريق الدعم';

  @override
  String get supportRefresh => 'تحديث';

  @override
  String get supportSendFailed => 'تعذّر الإرسال. حاول مرة أخرى.';

  @override
  String get supportWhatsAppIntro => 'للرد الأسرع، تواصل معنا عبر واتساب.';

  @override
  String get supportTileSubtitle => 'راسل الفريق أو افتح واتساب';

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
