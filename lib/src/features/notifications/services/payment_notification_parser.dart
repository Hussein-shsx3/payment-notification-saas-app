class ParsedPaymentNotification {
  ParsedPaymentNotification({
    required this.source,
    required this.title,
    required this.message,
    required this.receivedAt,
    required this.amount,
    required this.currency,
    required this.sender,
    required this.transactionId,
    this.direction = 'unknown',
  });

  final String source;
  final String title;
  final String message;
  final DateTime receivedAt;
  final double? amount;
  final String? currency;
  final String? sender;
  final String? transactionId;
  /// `incoming` = money in; `outgoing` = money out; `unknown` = fix in app.
  final String direction;
}

class PaymentNotificationParser {
  /// Greedy \\d+ so 1200.00 is not parsed as 120 (align with server).
  static const String _amountToken =
      r'(?:(?:\d{1,3}(?:[,\s]\d{3})+|\d+)(?:[.,]\d{1,2})?)';

  /// Amount + optional currency (Gaza/Palestine: ₪ / NIS / شيكل / شيقل).
  static final RegExp _amountRegex = RegExp(
    '(?<!\\d)($_amountToken)\\s*(USD|US\$|ILS|NIS|JOD|JDS|\\\$|₪|شيكل|شيقل|دولار)?',
    caseSensitive: false,
  );
  static final RegExp _amountAfterMablagRegex = RegExp(
    'مبلغ[\\s:]*($_amountToken)',
    caseSensitive: false,
  );
  static final RegExp _amountAfterBimablagRegex = RegExp(
    'بمبلغ[\\s:]*($_amountToken)\\s*(USD|US\$|ILS|NIS|JOD|JDS|\\\$|₪|شيكل|شيقل|دولار)?',
    caseSensitive: false,
  );
  static final RegExp _transactionIdRegex = RegExp(
    r'(?:tx(?:n)?|transaction|ref|reference|رقم العملية|رقم المرجع)[\s:#-]*([A-Za-z0-9\-]{4,})',
    caseSensitive: false,
  );
  static final RegExp _senderRegex = RegExp(
    r'(?:from|sender|from account|مرسل|من)[\s:]*([A-Za-z0-9 _\-]{3,30})',
    caseSensitive: false,
  );

  static ParsedPaymentNotification? parse({
    required String packageName,
    required String title,
    required String message,
    required DateTime receivedAt,
  }) {
    final normalizedMessage =
        _stripTrailingAvailableBalanceLine(_normalizeDigits(message));
    final packageLower = packageName.toLowerCase();
    final titleLower = title.toLowerCase();
    final messageLower = normalizedMessage.toLowerCase();
    final haystack = '$packageLower $titleLower $messageLower';

    if (_isExcludedPackage(packageLower)) {
      return null;
    }

    if (_isFalsePositive(haystack)) {
      return null;
    }
    if (_isOtpOrStepUpVerificationMessage(haystack.toLowerCase())) {
      return null;
    }

    if (_isLikelyNonPaymentJunk(haystack.toLowerCase())) {
      return null;
    }

    final combinedForAmount =
        _normalizeDigits('$title\n$normalizedMessage').trim();
    final combinedLower = combinedForAmount.toLowerCase();
    if (_isInternalAccountTransferOnly(combinedLower)) {
      return null;
    }
    if (_isCardMovementExcluded(combinedLower)) {
      return null;
    }

    RegExpMatch? amountMatch =
        _amountAfterBimablagRegex.firstMatch(combinedForAmount) ??
            _amountAfterBimablagRegex.firstMatch(normalizedMessage);
    amountMatch ??= _amountAfterMablagRegex.firstMatch(combinedForAmount) ??
        _amountAfterMablagRegex.firstMatch(normalizedMessage);
    amountMatch ??= _amountRegex.firstMatch(combinedForAmount) ?? _amountRegex.firstMatch(normalizedMessage);

    double? amount;
    String? currency;
    String? sender;
    String? transactionId;
    if (amountMatch != null) {
      amount = _parseAmount(amountMatch.group(1));
      final cur = amountMatch.group(2);
      if (cur != null && cur.isNotEmpty) {
        var c = cur.toUpperCase();
        if (c == r'$' || c == 'US\$') c = 'USD';
        if (c == 'JDS') c = 'JOD';
        currency = c;
      }
    }

    final txMatch = _transactionIdRegex.firstMatch(combinedForAmount) ??
        _transactionIdRegex.firstMatch(normalizedMessage);
    transactionId = txMatch?.group(1);

    final senderMatch = _senderRegex.firstMatch(combinedForAmount.toLowerCase()) ??
        _senderRegex.firstMatch(normalizedMessage);
    sender = senderMatch?.group(1)?.trim();

    final fullText = '$titleLower $messageLower';
    final hasValidAmount = amount != null && amount > 0;

    if (!hasValidAmount) {
      return null;
    }

    if (!_passesCaptureFilter(
          packageLower: packageLower,
          titleLower: titleLower,
          messageLower: messageLower,
        )) {
      return null;
    }

    final direction = _inferPaymentDirection(fullText);

    final source = _detectSource(
          packageName: packageLower,
          title: titleLower,
          message: messageLower,
          input: haystack,
        ) ??
        _inferSourceFallback(packageNameLower: packageLower, messageLower: messageLower);

    return ParsedPaymentNotification(
      source: source,
      title: title,
      message: normalizedMessage,
      receivedAt: receivedAt,
      amount: amount,
      currency: currency,
      sender: sender,
      transactionId: transactionId,
      direction: direction,
    );
  }

  static String? _detectSource({
    required String packageName,
    required String title,
    required String message,
    required String input,
  }) {
    // Direct app detection
    if (_containsAny(input, ['palpay', 'pal pay', 'بال باي', 'بالباي'])) return 'PalPay';
    if (_containsAny(input, ['jawwal', 'jawwalpay', 'jawwal pay', 'جوال باي', 'جوال'])) return 'Jawwal Pay';
    if (_containsAny(input, [
          'palestine bank',
          'bank of palestine',
          'bop',
          'بنك فلسطين',
          'تحويل بنكي',
          'تحويل لصديق',
          'bankofpalestine',
        ])) {
      return 'Palestine Bank';
    }

    final isSmsApp = _isSmsAppPackage(packageName);

    // Check for Iburaq transfer via SMS
    if (isSmsApp && _containsAny(input, ['iburaq', 'ايبرق', 'البراق'])) {
      return 'Iburaq';
    }

    // Check for bank/payment SMS
    final hasBankHint = _containsAny('$title $message', [
      'bank',
      'bop',
      'palestine bank',
      'bank of palestine',
      'bankofpalestine',
      'palpay',
      'jawwal',
      'بنك',
      'فلسطين',
      'مبلغ',
      'حساب',
      'حسابك',
      'رصيد',
      'تحويل',
      'تحويل بنكي',
      'تحويل لصديق',
      'دفعة',
      'ايداع',
      'إيداع',
      'استلام',
      'استقبال',
      'حوالة',
      'استلام',
      'عملية',
      'إشعار',
      'received',
      'credited',
      'deposit',
    ]);

    if (isSmsApp && hasBankHint) {
      return 'SMS Payment';
    }

    return null;
  }

  static bool _containsAny(String input, List<String> terms) {
    for (final t in terms) {
      if (input.contains(t)) return true;
    }
    return false;
  }

  /// Internal moves between the user's own accounts only (not stored).
  static bool _isInternalAccountTransferOnly(String combinedLower) {
    final t = combinedLower;
    if (t.contains('بين الحسابات') || t.contains('between accounts')) return true;
    if (t.contains('تحويل بنكي بين الحسابات') || t.contains('تحويل بين الحسابات')) {
      return true;
    }
    return false;
  }

  /// Card purchase/ATM style alerts (e.g. حركة على بطاقة رقم … بقيمة) — not stored.
  static bool _isCardMovementExcluded(String combinedLower) {
    return combinedLower.contains('حركة على بطاقة');
  }

  static bool _isIncomingIndicators(String input) {
    return _containsAny(input, [
      'received',
      'credited',
      'deposited',
      'you received',
      'payment received',
      'transfer received',
      'incoming',
      'you got',
      'account credited',
      'credit alert',
      'cash in',
      'تم استلام',
      'تم ايداع',
      'تم إيداع',
      'استلمت',
      'وصلك',
      'تم تحويل لك',
      'تم الايداع',
      'تم الإيداع',
      'وردت',
      'تم استقبال',
      'حوالة واردة',
      'حوالة واردة لحسابك',
      'واردة لحسابك',
      'واردة الى حسابك',
      'واردة إلى حسابك',
      'تمت إضافة',
      'تم اضافه',
      'اضافة الى حسابك',
      'إضافة إلى حسابك',
      'تم اضافة',
      'تم إضافة',
      'إشعار إيداع',
      'اشعار ايداع',
      'وارد',
      'واردة',
      'has been accepted',
      'has been credited',
      'accepted with',
      'money transfer',
    ]);
  }

  static String _inferPaymentDirection(String fullTextLower) {
    final t = fullTextLower;
    if (t.contains('حوالة واردة') ||
        t.contains('واردة لحسابك') ||
        (t.contains('واردة') && t.contains('لحسابك'))) {
      return 'incoming';
    }
    if (t.contains('حوالة صادرة') ||
        t.contains('صادرة من حسابك') ||
        t.contains('تحويل دفع لصديق') ||
        (t.contains('الدفع لصديق') && t.contains('بمبلغ')) ||
        t.contains('موبايل: تحويل بنكي:') ||
        t.contains('transfer to beneficiary') ||
        t.contains('شحن محفظة') ||
        (t.contains('شحن') && t.contains('محفظة')) ||
        t.contains('تم إعادة شحن رصيدك') ||
        t.contains('تم إعادة شحن') ||
        (t.contains('شراء') && (t.contains('بمبلغ') || t.contains('ils')))) {
      return 'outgoing';
    }
    final sent = _isSentPayment(t);
    final inc = _isIncomingIndicators(t);
    if (sent && inc) return 'unknown';
    if (sent) return 'outgoing';
    if (inc) return 'incoming';
    return 'unknown';
  }

  /// Same gate as native [PaymentNotifyNotificationListenerService.shouldRoughlyLookLikePayment].
  static bool _passesCaptureFilter({
    required String packageLower,
    required String titleLower,
    required String messageLower,
  }) {
    final textLower = '$titleLower $messageLower';
    final haystack = '$packageLower $titleLower $messageLower';

    final isKnown = _isKnownPaymentAppPackage(packageLower);
    final isSms = _isSmsAppPackage(packageLower);
    final strong = _hasStrongPaymentHint(textLower);
    final bankOp = _hasBankOperationHints(textLower);
    final bankKw = _hasBankKeywords(textLower);
    final isIburaq = isSms && _containsAny(haystack, ['iburaq', 'ايبرق', 'البراق']);

    if (isKnown) {
      return strong || bankOp || _looksLikeMoneyFingerprintFromKnownBankApp(textLower);
    }
    if (isSms && !_smsHasRecognizedPaymentBrand(textLower)) {
      return false;
    }
    if (isIburaq && strong) return true;
    if (isSms && _isSmsIburaqIncomingWireLine(textLower)) return true;
    if (isSms && RegExp(r'\d').hasMatch(textLower) && strong) return true;
    if (isSms &&
        bankKw &&
        (strong || _looksLikeMoneyFingerprintFromKnownBankApp(textLower))) {
      return true;
    }
    final palestineLine = textLower.contains('تحويل بنكي') &&
        (textLower.contains('بمبلغ') || textLower.contains('مبلغ'));
    if (palestineLine && (strong || bankOp)) return true;
    if (_isPalestineBankFriendPaymentLine(textLower)) return true;
    if (_isPalestineBankIncomingAccountLine(textLower)) return true;
    return false;
  }

  /// BOP friend payment tray — "تحويل دفع لصديق" not "تحويل بنكي".
  static bool _isPalestineBankFriendPaymentLine(String textLower) {
    final friend = textLower.contains('تحويل دفع') ||
        textLower.contains('الدفع لصديق') ||
        textLower.contains('دفع لصديق');
    final money = textLower.contains('بمبلغ') ||
        textLower.contains('مبلغ') ||
        textLower.contains('ils') ||
        textLower.contains('nis') ||
        textLower.contains('₪');
    return friend && money;
  }

  /// Incoming to BOP account/wallet (align with server [_isPalestineBankIncomingAccountLine]).
  static bool _isPalestineBankIncomingAccountLine(String textLower) {
    if (!RegExp(r'\d').hasMatch(textLower)) return false;
    final incomingCue = textLower.contains('حوالة واردة') ||
        textLower.contains('واردة لحسابك') ||
        textLower.contains('واردة إلى حسابك') ||
        textLower.contains('واردة الى حسابك') ||
        textLower.contains('إيداع') ||
        textLower.contains('ايداع') ||
        textLower.contains('استلام') ||
        textLower.contains('استقبال') ||
        textLower.contains('من جوال') ||
        textLower.contains('jawwal pay') ||
        textLower.contains('جوال باي') ||
        textLower.contains('credited') ||
        textLower.contains('deposited') ||
        textLower.contains('has been credited') ||
        textLower.contains('has been accepted') ||
        textLower.contains('تم إضافة') ||
        textLower.contains('تم اضافة') ||
        textLower.contains('قيد إيداع') ||
        textLower.contains('اضافة مبلغ') ||
        textLower.contains('رصيدكم') ||
        textLower.contains('المتوفر') ||
        textLower.contains('iburaq') ||
        textLower.contains('ايبرق') ||
        textLower.contains('البراق');
    final bankOrMoney = textLower.contains('bop') ||
        textLower.contains('بنك') ||
        textLower.contains('bank') ||
        textLower.contains('فلسطين') ||
        textLower.contains('palestine') ||
        textLower.contains('ils') ||
        textLower.contains('nis') ||
        textLower.contains('₪') ||
        textLower.contains('مبلغ') ||
        textLower.contains('بمبلغ') ||
        textLower.contains('بقيمة') ||
        textLower.contains('شيكل') ||
        textLower.contains('شيقل') ||
        textLower.contains('رصيد');
    return incomingCue && bankOrMoney;
  }

  /// Iburaq SMS (align with server [_isSmsIburaqIncomingWireLine]).
  static bool _isSmsIburaqIncomingWireLine(String textLower) {
    if (!RegExp(r'\d').hasMatch(textLower)) return false;
    final wire = textLower.contains('حوالة واردة') ||
        textLower.contains('واردة لحسابك') ||
        textLower.contains('واردة إلى حسابك') ||
        textLower.contains('واردة الى حسابك');
    final money = textLower.contains('بمبلغ') ||
        textLower.contains('مبلغ') ||
        textLower.contains('شيكل') ||
        textLower.contains('شيقل') ||
        textLower.contains('رصيد') ||
        textLower.contains('رصيدكم') ||
        textLower.contains('المتوفر');
    return wire && money;
  }

  /// Align with Android [looksLikeMoneyFingerprintFromKnownBankApp].
  static bool _looksLikeMoneyFingerprintFromKnownBankApp(String textLower) {
    if (!RegExp(r'\d').hasMatch(textLower)) return false;
    return _containsAny(textLower, [
      'مبلغ',
      'بمبلغ',
      'رصيد',
      'حساب',
      'حوالة',
      'عملية',
      'شيكل',
      'شيقل',
      'نيس',
      '₪',
      'ils',
      'nis',
      'jod',
      'usd',
      'eur',
      'gbp',
      'transfer',
      'payment',
      'deposit',
      'credit',
      'debit',
      'amount',
      'balance',
      'بنك',
      'bank',
      'bop',
      'palestine',
      'فلسطين',
      'تحويل بنكي',
      'إشعار',
      'اشعار',
      'إيداع',
      'ايداع',
      'استلام',
      'استقبال',
      'واردة',
      'وارد',
      'صادرة',
      'شحن',
      'بقيمة',
      'جاري',
      'transaction',
      'jawwal pay',
      'جوال باي',
      'iburaq',
      'البراق',
      'ايبرق',
    ]);
  }

  static bool _isKnownPaymentAppPackage(String packageLower) {
    return _containsAny(packageLower, [
      'palpay',
      'com.palpay',
      'net.palpay',
      'ps.palpay',
      'jawwal',
      'jawwalpay',
      'ps.jawwal',
      'com.jawwal',
      'bankofpalestine',
      'com.bop',
      'bop.mobile',
      'albop',
      'efinance',
      'palestinebank',
      'palestine.bank',
      'bop.ps',
      'ps.bop',
      'cash.pal',
      'wallet.ps',
    ]);
  }

  static bool _isSmsAppPackage(String packageLower) {
    if (_containsAny(packageLower, [
          'com.google.android.apps.messaging',
          'com.samsung.android.messaging',
          'com.android.mms',
          'com.android.messaging',
          'com.miui.mms',
          'com.huawei.message',
          'com.oneplus.mms',
          'com.coloros.mms',
        ])) {
      return true;
    }
    return packageLower.contains('messaging') ||
        packageLower.contains('mms') ||
        (packageLower.contains('sms') && packageLower.contains('android')) ||
        packageLower.contains('telephony');
  }

  /// Title + body must name a real bank/wallet (SMS-only; align with Kotlin [smsHasRecognizedPaymentBrand]).
  static bool _smsHasRecognizedPaymentBrand(String textLower) {
    return _containsAny(textLower, [
      'bop',
      'bank of palestine',
      'بنك فلسطين',
      'palestine bank',
      'bankofpalestine',
      'jawwal',
      'jawwal pay',
      'palpay',
      'pal pay',
      'بالباي',
      'بال باي',
      'جوال باي',
      'paypal',
      'pay pal',
      'iburaq',
      'البراق',
      'ايبرق',
      'stripe',
      'wise',
      'transferwise',
      'western union',
      'moneygram',
      'arab bank',
      'البنك العربي',
      'cairo amman',
      'القاهرة عمان',
      'qnb',
      'fab',
      'zain cash',
      'orange money',
      'cliq',
      'تحويل بنكي',
      'تحويل دفع',
      'الدفع لصديق',
      'دفع لصديق',
      'مصرف فلسطين',
      'efinance',
      'cash.pal',
      'wallet.ps',
    ]);
  }

  static bool _hasBankKeywords(String textLower) {
    return textLower.contains('bank') ||
        textLower.contains('بنك') ||
        textLower.contains('bop') ||
        textLower.contains('palestine') ||
        textLower.contains('فلسطين') ||
        textLower.contains('jawwal') ||
        textLower.contains('palpay') ||
        textLower.contains('جوال') ||
        textLower.contains('بالباي') ||
        textLower.contains('بال باي') ||
        textLower.contains('ايبرق') ||
        textLower.contains('البراق') ||
        textLower.contains('iburaq') ||
        textLower.contains('بنك فلسطين') ||
        textLower.contains('pal pay') ||
        textLower.contains('محفظة');
  }

  static bool _hasBankOperationHints(String textLower) {
    return _containsAny(textLower, [
      'تحويل بنكي',
      'بنك فلسطين',
      'شيكل',
      'شيقل',
      'نيس',
      '₪',
      'ils',
      'nis',
      'jod',
      'usd',
    ]);
  }

  static bool _hasStrongPaymentHint(String textLower) {
    return _containsAny(textLower, [
      'received',
      'credited',
      'deposited',
      'payment received',
      'transfer received',
      'you received',
      'account credited',
      'credit alert',
      'cash in',
      'you sent',
      'you transferred',
      'you paid',
      'sent to',
      'payment to',
      'transfer to',
      'paid to',
      'outgoing transfer',
      'money sent',
      'transaction sent',
      'deducted',
      'debited',
      'withdrawal',
      'cash out',
      'تم استلام',
      'تم ايداع',
      'تم إيداع',
      'استلمت',
      'وصلك',
      'وردت',
      'تم استقبال',
      'حوالة واردة',
      'واردة لحسابك',
      'واردة الى حسابك',
      'واردة إلى حسابك',
      'تم تحويل لك',
      'تم الايداع',
      'تم الإيداع',
      'تمت إضافة',
      'تم اضافه',
      'اضافة الى حسابك',
      'إضافة إلى حسابك',
      'تم اضافة',
      'تم إضافة',
      'إشعار إيداع',
      'اشعار ايداع',
      'تم ارسال',
      'ارسلت',
      'تم الدفع لـ',
      'تم الدفع إلى',
      'تم الدفع ل',
      'دفعت',
      'تم خصم',
      'تم التحويل الى',
      'تم التحويل إلى',
      'حولت',
      'حوالة صادرة',
      'صادرة من حسابك',
      'تم سحب',
      'شراء',
      'تحويل بنكي',
      'تحويل دفع لصديق',
      'عملية ناجحة',
      'إشعار عملية',
      'اشعار عملية',
      'عملية مالية',
      'تم بنجاح',
      'بنجاح',
      'تمت العملية',
      'دفعة',
      'إيداع',
      'ايداع',
      'حسابك',
      'لحسابك',
      'بمبلغ',
      'مبلغ',
      'رصيد',
      'شيكل',
      'شيقل',
      'نيس',
      'payment',
      'transfer',
      'deposit',
      'wallet',
      'محفظة',
      'شحن',
      'شحن محفظة',
      'حساب جاري',
      'بقيمة',
      'من جوال',
      'jawwal pay',
      'جوال باي',
      'has been accepted',
      'has been credited',
      'transaction',
    ]);
  }

  static bool _isSentPayment(String input) {
    return _containsAny(input, [
      // English - sent/outgoing
      'you sent',
      'you transferred',
      'you paid',
      'sent to',
      'payment to',
      'transfer to',
      'paid to',
      'outgoing transfer',
      'money sent',
      'transaction sent',
      'deducted for',
      'debited for',
      'debited',
      'withdrawal',
      'cash out',
      // Arabic - sent/outgoing (avoid bare "تم الدفع" — banks use it for credits too)
      'تم ارسال',
      'ارسلت',
      'قمت بارسال',
      'تم الدفع لـ',
      'تم الدفع إلى',
      'تم الدفع ل',
      'دفعت',
      'تم خصم لـ',
      'تم التحويل الى',
      'تم التحويل إلى',
      'حولت',
      'ارسال الى',
      'إرسال إلى',
      'حوالة صادرة',
      'صادرة من حسابك',
      'تم سحب',
      'سحب',
      'شراء',
      'تحويل دفع لصديق',
      'شحن محفظة',
      'موبايل: تحويل بنكي:',
      'تم إعادة شحن رصيدك',
      'تم إعادة شحن',
      'transfer to beneficiary',
    ]);
  }

  static bool _isFalsePositive(String input) {
    final lower = input.toLowerCase();
    return _containsAny(lower, [
      'otp',
      'one-time password',
      'verification code',
      'verify',
      'confirm code',
      'activation code',
      'security code',
      'password reset',
      'login code',
      'رمز التحقق',
      'رمز التأكيد',
      'code:',
      'code :',
      'two-factor',
      'authenticator',
      'signed in from',
      'new device',
      'كلمة السر المؤقتة',
      'كلمه السر المؤقتة',
      'السر المؤقتة',
      'يرجى استخدام كلمة السر',
      'استخدم كلمة السر',
      'temporary password',
      'temp password',
      'one time password',
    ]);
  }

  /// Bank step-up SMS — not a payment (align with Android [isOtpOrStepUpVerificationMessage]).
  static bool _isOtpOrStepUpVerificationMessage(String lower) {
    if (lower.contains('كلمة السر المؤقتة') || lower.contains('كلمه السر المؤقتة')) {
      return true;
    }
    if (lower.contains('يرجى استخدام كلمة السر') || lower.contains('استخدم كلمة السر المؤقتة')) {
      return true;
    }
    if (lower.contains('لاستكمال الحركة') &&
        (lower.contains('مؤقت') || lower.contains('code') || lower.contains('رمز'))) {
      return true;
    }
    if (RegExp(r'code\s*:\s*\d', caseSensitive: false).hasMatch(lower) &&
        (lower.contains('مؤقت') || lower.contains('استكمال') || lower.contains('يرجى'))) {
      return true;
    }
    return false;
  }

  /// Casual WhatsApp / chat — not a bank payment line.
  static bool _isCasualWhatsAppJunk(String lower) {
    if (lower.contains('whatsapp') || lower.contains('واتس')) return true;
    if (lower.contains('ع الواتس') || lower.contains('عالواتس')) return true;
    if (lower.contains('بعتلك الاشعار') || lower.contains('بعتلك الإشعار')) {
      return true;
    }
    if (lower.contains('بعتلك') &&
        (lower.contains('اشعار') || lower.contains('إشعار'))) {
      return true;
    }
    return false;
  }

  static String _stripTrailingAvailableBalanceLine(String normalized) {
    var s = normalized.trim().replaceAll(RegExp(r'\r\n'), '\n');
    s = s.replaceAll(
      RegExp(
        r'[\s.،\n]*رصيد(?:كم|ك)\s+المتوفر(?:\s+هو)?\s*[\d.,]+',
        caseSensitive: false,
      ),
      '',
    );
    final markStrip = RegExp(r'[\u200c-\u200f\u202a-\u202e\u2066-\u2069\ufeff]+');
    final lines = s
        .split('\n')
        .map((l) => l.trim())
        .where((line) {
          if (line.isEmpty) return false;
          final noMarks = line.replaceAll(markStrip, '').trim();
          return !RegExp(r'^BOP$', caseSensitive: false).hasMatch(noMarks);
        });
    s = lines.join('\n').trim();
    s = s.replaceAll(RegExp(r'[.،\s]+$'), '').trim();
    return s;
  }

  static bool _isLikelyNonPaymentJunk(String lower) {
    if (_isCasualWhatsAppJunk(lower)) return true;
    return _containsAny(lower, [
      'steps',
      'calories',
      'followers',
      'likes',
      'views',
      'score',
      'level ',
      'weather',
      'youtube',
      'tiktok',
      'instagram',
      'delivery',
      'tracking',
      'promo code',
      'خصم',
      'عرض',
      'طقس',
      'متابع',
      'لعبة',
      'نقاط',
    ]);
  }

  static bool _isExcludedPackage(String packageName) {
    return _containsAny(packageName, [
      'com.whatsapp',
      'org.telegram',
      'com.facebook.orca',
      'com.facebook.katana',
      'com.instagram.android',
      'com.snapchat.android',
      'com.google.android.gm',
      'com.linkedin.android',
    ]);
  }

  static String _inferSourceFallback({
    required String packageNameLower,
    required String messageLower,
  }) {
    if (_containsAny(packageNameLower, ['palpay'])) return 'PalPay';
    if (_containsAny(packageNameLower, ['jawwal', 'jawwalpay'])) return 'Jawwal Pay';
    if (_containsAny(packageNameLower, [
          'bank',
          'bop',
          'palestine',
          'bankofpalestine',
          'bop.mobile',
        ])) {
      return 'Palestine Bank';
    }

    final isSmsApp = _isSmsAppPackage(packageNameLower);
    if (isSmsApp && _containsAny(messageLower, ['iburaq', 'ايبرق', 'البراق'])) return 'Iburaq';
    if (isSmsApp) return 'SMS Payment';
    return 'Other';
  }

  static String _normalizeDigits(String input) {
    const arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const easternArabicIndic = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var out = input;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(arabicIndic[i], '$i');
      out = out.replaceAll(easternArabicIndic[i], '$i');
    }
    return out;
  }

  static double? _parseAmount(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var normalized = raw.replaceAll(' ', '');
    if (normalized.contains(',') && normalized.contains('.')) {
      if (normalized.lastIndexOf(',') > normalized.lastIndexOf('.')) {
        normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    } else if (normalized.contains(',')) {
      final commaCount = ','.allMatches(normalized).length;
      if (commaCount > 1) {
        normalized = normalized.replaceAll(',', '');
      } else {
        final decimalPart = normalized.split(',').last;
        normalized = decimalPart.length <= 2
            ? normalized.replaceAll(',', '.')
            : normalized.replaceAll(',', '');
      }
    }
    return double.tryParse(normalized);
  }
}

