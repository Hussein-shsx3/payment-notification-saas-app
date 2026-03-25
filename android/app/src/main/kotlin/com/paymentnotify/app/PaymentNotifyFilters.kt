package com.paymentnotify.app

/**
 * Payment vs junk heuristics (kept in sync with server + Dart parser intent).
 */
object PaymentNotifyFilters {

    fun shouldRoughlyLookLikePayment(title: String, message: String, packageName: String): Boolean {
        val text = (title + " " + message).lowercase()

        if (isInternalAccountTransferOnly(text)) return false
        if (isCardMovementExcluded(text)) return false
        if (isLikelyNonPaymentJunk(text)) return false

        val falsePositives = listOf(
            "otp", "one-time", "verification code", "confirm code", "password reset", "login code", "code:",
            "activation code", "security code", "two-factor", "2fa", "authenticator",
            "رمز التحقق", "رمز التأكيد", "رمز الدخول", "تأكيد الهوية", "تحقق من", "ادخل الرمز",
            "new login", "signed in from", "new device",
            "captcha", "recaptcha",
        )
        if (falsePositives.any { text.contains(it) }) return false

        val packageLower = packageName.lowercase()

        val knownPaymentPackages = listOf(
            "palpay", "com.palpay", "net.palpay", "ps.palpay",
            "jawwal", "jawwalpay", "ps.jawwal", "com.jawwal",
            "bankofpalestine", "bank of palestine", "com.bop", "bop.mobile", "bop.ps", "ps.bop",
            "albop", "efinance", "palestinebank", "palestine.bank", "cash.pal", "wallet.ps",
        )
        val isKnownPaymentApp = knownPaymentPackages.any { packageLower.contains(it) }

        val smsPackages = listOf(
            "com.google.android.apps.messaging",
            "com.samsung.android.messaging",
            "com.android.mms",
            "com.android.messaging",
            "com.miui.mms",
            "com.huawei.message",
            "com.oneplus.mms",
            "com.coloros.mms",
        )
        // Include generic "messaging" / mms so OEM SMS apps not in the list still count (Iburaq SMS tray).
        val isSmsApp =
            smsPackages.any { packageLower.contains(it) } ||
                packageLower.contains("messaging") ||
                packageLower.contains("mms") ||
                (packageLower.contains("sms") && packageLower.contains("android"))

        val strongPaymentHints = listOf(
            "received", "credited", "deposited", "payment received", "transfer received",
            "you received", "account credited", "credit alert", "cash in",
            "you sent", "you transferred", "you paid", "sent to", "payment to", "transfer to",
            "paid to", "outgoing transfer", "money sent", "transaction sent",
            "deducted", "debited", "withdrawal", "cash out",
            "تم استلام", "تم ايداع", "تم إيداع", "استلمت", "وصلك", "وردت", "تم استقبال",
            "حوالة واردة", "واردة لحسابك", "واردة الى حسابك", "واردة إلى حسابك",
            "تم تحويل لك", "تم الايداع", "تم الإيداع",
            "تمت إضافة", "تم اضافه", "اضافة الى حسابك", "إضافة إلى حسابك", "تم اضافه", "تم إضافة",
            "إشعار إيداع", "اشعار ايداع",
            "تم ارسال", "ارسلت", "تم الدفع لـ", "تم الدفع إلى", "تم الدفع ل", "دفعت",
            "تم خصم", "تم التحويل الى", "تم التحويل إلى", "حولت", "حوالة صادرة", "صادرة من حسابك",
            "تم سحب", "شراء",
            "تحويل بنكي", "تحويل دفع لصديق", "عملية ناجحة", "إشعار عملية", "اشعار عملية", "عملية مالية",
            "تم بنجاح", "بنجاح", "تمت العملية", "دفعة", "إيداع", "ايداع",
            "حسابك", "لحسابك", "بمبلغ", "مبلغ", "رصيد",
            "payment", "transfer", "deposit", "wallet", "محفظة",
            "شحن", "شحن محفظة", "حساب جاري", "بقيمة", "من جوال", "jawwal pay", "جوال باي",
            "has been accepted", "has been credited", "transaction",
        )
        val hasStrongHint = strongPaymentHints.any { text.contains(it) }

        val bankOperationHints = listOf(
            "تحويل بنكي", "بنك فلسطين", "شيكل", "شيقل", "نيس", "₪",
            "ils", "nis", "jod", "usd",
        )
        val hasBankOp = bankOperationHints.any { text.contains(it) }

        val isIburaq = isSmsApp && (
            text.contains("iburaq") || text.contains("ايبرق") || text.contains("البراق")
            )

        if (isKnownPaymentApp) {
            return hasStrongHint || hasBankOp || looksLikeMoneyFingerprintFromKnownBankApp(text)
        }

        if (isIburaq && hasStrongHint) return true

        // Iburaq / SMS rail: "حوالة واردة لحسابك بمبلغ … شيكل. رصيدكم المتوفر …" (no "bank" keyword in body).
        if (isSmsApp && isSmsIburaqIncomingWireLine(text)) return true

        if (isSmsApp && bankKeywordsMatch(text) && (hasStrongHint || looksLikeMoneyFingerprintFromKnownBankApp(text))) {
            return true
        }

        val isPalestineBankTransferLine = text.contains("تحويل بنكي") &&
            (text.contains("بمبلغ") || text.contains("مبلغ"))
        if (isPalestineBankTransferLine && (hasStrongHint || hasBankOp)) return true

        // BOP "Pay to friend" — title/body use تحويل دفع / الدفع لصديق, not "تحويل بنكي" (package may be unknown).
        val isPalestineBankFriendPaymentLine =
            (text.contains("تحويل دفع") || text.contains("الدفع لصديق") || text.contains("دفع لصديق")) &&
                (text.contains("بمبلغ") || text.contains("مبلغ") || text.contains("ils") || text.contains("nis"))
        if (isPalestineBankFriendPaymentLine) return true

        // Incoming to BOP account/wallet (receive from Jawwal Pay etc.) — wording differs from outgoing.
        if (isPalestineBankIncomingAccountLine(text)) return true

        return false
    }

    /**
     * Known bank/wallet apps: digits + money/bank cue — catches incoming templates that omit our "strong" phrases.
     * Still blocked by falsePositives / junk / internal-transfer rules above.
     */
    private fun looksLikeMoneyFingerprintFromKnownBankApp(text: String): Boolean {
        if (!text.any { it.isDigit() }) return false
        val cues = listOf(
            "مبلغ", "بمبلغ", "رصيد", "حساب", "حوالة", "عملية", "شيكل", "شيقل", "نيس",
            "₪", "ils", "nis", "jod", "usd", "eur", "gbp",
            "transfer", "payment", "deposit", "credit", "debit", "amount", "balance",
            "بنك", "bank", "bop", "palestine", "فلسطين", "تحويل بنكي", "إشعار", "اشعار",
            "إيداع", "ايداع", "استلام", "استقبال", "واردة", "وارد", "صادرة",
            "شحن", "بقيمة", "جاري", "transaction", "jawwal pay", "جوال باي",
        )
        return cues.any { text.contains(it) }
    }

    private fun isSmsIburaqIncomingWireLine(text: String): Boolean {
        if (!text.any { it.isDigit() }) return false
        val wire =
            text.contains("حوالة واردة") ||
                text.contains("واردة لحسابك") ||
                text.contains("واردة إلى حسابك") ||
                text.contains("واردة الى حسابك")
        val money =
            text.contains("بمبلغ") ||
                text.contains("مبلغ") ||
                text.contains("شيكل") ||
                text.contains("شيقل") ||
                text.contains("رصيد") ||
                text.contains("رصيدكم") ||
                text.contains("المتوفر")
        return wire && money
    }

    private fun isPalestineBankIncomingAccountLine(text: String): Boolean {
        if (!text.any { it.isDigit() }) return false
        val incomingCue =
            text.contains("شحن") ||
                text.contains("حوالة واردة") ||
                text.contains("واردة لحسابك") ||
                text.contains("واردة إلى حسابك") ||
                text.contains("واردة الى حسابك") ||
                text.contains("إيداع") ||
                text.contains("ايداع") ||
                text.contains("استلام") ||
                text.contains("استقبال") ||
                text.contains("من جوال") ||
                text.contains("jawwal pay") ||
                text.contains("جوال باي") ||
                text.contains("credited") ||
                text.contains("deposited") ||
                text.contains("has been credited") ||
                text.contains("has been accepted") ||
                text.contains("تم إضافة") ||
                text.contains("تم اضافة") ||
                text.contains("قيد إيداع") ||
                text.contains("اضافة مبلغ") ||
                text.contains("رصيدكم") ||
                text.contains("المتوفر") ||
                text.contains("iburaq") ||
                text.contains("ايبرق") ||
                text.contains("البراق")
        val bankOrMoney =
            text.contains("bop") ||
                text.contains("بنك") ||
                text.contains("bank") ||
                text.contains("فلسطين") ||
                text.contains("palestine") ||
                text.contains("ils") ||
                text.contains("nis") ||
                text.contains("₪") ||
                text.contains("مبلغ") ||
                text.contains("بمبلغ") ||
                text.contains("بقيمة") ||
                text.contains("شيكل") ||
                text.contains("شيقل") ||
                text.contains("رصيد")
        return incomingCue && bankOrMoney
    }

    private fun bankKeywordsMatch(text: String): Boolean {
        return text.contains("bank") || text.contains("بنك") ||
            text.contains("bop") || text.contains("palestine") || text.contains("فلسطين") ||
            text.contains("jawwal") || text.contains("palpay") || text.contains("جوال") ||
            text.contains("بالباي") || text.contains("بال باي") || text.contains("ايبرق")
    }

    private fun isInternalAccountTransferOnly(text: String): Boolean {
        if (text.contains("بين الحسابات") || text.contains("between accounts")) return true
        if (text.contains("تحويل بنكي بين الحسابات") || text.contains("تحويل بين الحسابات")) {
            return true
        }
        return false
    }

    private fun isCardMovementExcluded(text: String): Boolean {
        return text.contains("حركة على بطاقة")
    }

    private fun isLikelyNonPaymentJunk(text: String): Boolean {
        val junk = listOf(
            "steps", "calories", "km walked", "followers", "following", "likes", "views", "new followers",
            "level ", "score", "points", "achievement", "game", "match", "goal",
            "weather", "°c", "°f", "humidity", "wind",
            "youtube", "subscribe", "uploaded", "instagram", "facebook", "tiktok", "snapchat",
            "delivery", "your order", "tracking", "shipped",
            "promo code", "discount", "sale ends", "خصم", "عرض", "تخفيضات", "تسوق",
            "new email", "inbox", "mailbox",
            "battery", "charging", "wifi", "bluetooth connected",
            "missed call", "incoming call", "voice message",
            "طقس", "درجة الحرارة", "متابع", "إعجاب", "مشاهدة", "لعبة", "مستوى", "نقاط",
            "خطوات", "سعرات", "إعلان", "فيديو", "ستوري",
        )
        if (junk.any { text.contains(it) }) return true
        return false
    }
}
