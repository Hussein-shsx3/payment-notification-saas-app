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
  /// Amount + optional currency (Gaza/Palestine: ₪ / NIS / شيكل / شيقل).
  static final RegExp _amountRegex = RegExp(
    r'(?<!\d)(\d{1,3}(?:[,\s]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)\s*(USD|US\$|ILS|NIS|JOD|JDS|\$|₪|شيكل|شيقل|دولار)?',
    caseSensitive: false,
  );
  static final RegExp _amountAfterMablagRegex = RegExp(
    r'مبلغ[\s:]*(\d{1,3}(?:[,\s]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)',
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
    final normalizedMessage = _normalizeDigits(message);
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

    final combinedForAmount = _normalizeDigits('$title\n$message').trim();
    final combinedLower = combinedForAmount.toLowerCase();
    if (_isInternalAccountTransferOnly(combinedLower)) {
      return null;
    }
    if (_isCardMovementExcluded(combinedLower)) {
      return null;
    }

    RegExpMatch? amountMatch =
        _amountRegex.firstMatch(combinedForAmount) ?? _amountRegex.firstMatch(normalizedMessage);
    amountMatch ??= _amountAfterMablagRegex.firstMatch(combinedForAmount) ??
        _amountAfterMablagRegex.firstMatch(normalizedMessage);

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
    final hasPaymentIntent = _isPaymentIntent(fullText);
    final hasValidAmount = amount != null && amount > 0;

    // Keep only real payment/transfer notifications with a positive amount.
    if (!hasPaymentIntent || !hasValidAmount) {
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

    final isSmsApp = _containsAny(packageName, [
      'com.google.android.apps.messaging',
      'com.samsung.android.messaging',
      'com.android.mms',
      'com.android.messaging',
      'com.miui.mms',
      'com.huawei.message',
    ]);

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
      '- wallet',
      'wallet',
      'محفظة',
      'وارد',
      'واردة',
      'للمحفظة',
      'إلى محفظتك',
    ]);
  }

  static String _inferPaymentDirection(String fullTextLower) {
    final sent = _isSentPayment(fullTextLower);
    final inc = _isIncomingIndicators(fullTextLower);
    if (sent && inc) return 'unknown';
    if (sent) return 'outgoing';
    if (inc) return 'incoming';
    return 'unknown';
  }

  /// Incoming + outgoing + neutral (we only exclude internal account↔account above).
  static bool _isPaymentIntent(String input) {
    return _containsAny(input, [
      // English — received
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
      // English — sent
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
      // English — common bank templates (short / currency-led)
      'transaction',
      'purchase',
      'spent',
      'amount',
      'debit',
      'nis',
      'ils',
      'jod',
      'usd',
      'gbp',
      'eur',
      // Arabic — received
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
      // Arabic — sent
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
      // Palestine Bank / local
      'تحويل بنكي',
      'تحويل دفع لصديق',
      'تم بنجاح',
      'بنجاح',
      'عملية ناجحة',
      'إشعار عملية',
      'اشعار عملية',
      'عملية مالية',
      'شيكل',
      'شيقل',
      'نيس',
      'موبايل',
      'بمبلغ',
      // General
      'payment',
      'transfer',
      'deposit',
      'credited',
      'تحويل',
      'ايداع',
      'حوالة',
      'دفعة',
      'مبلغ',
      'عملية',
      'wallet',
      'محفظة',
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
    ]);
  }

  static bool _isFalsePositive(String input) {
    return _containsAny(input, [
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

    final isSmsApp = _containsAny(packageNameLower, [
      'com.google.android.apps.messaging',
      'com.samsung.android.messaging',
      'com.android.mms',
      'com.android.messaging',
      'com.miui.mms',
      'com.huawei.message',
    ]);
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

