package com.example.mobile_app

import android.app.Notification
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

import org.json.JSONObject

import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

class PaymentNotifyNotificationListenerService : NotificationListenerService() {
    private val TAG = "PaymentNotifyListener"

    // Must match Flutter's shared_preferences default file name.
    private fun prefs(context: Context): SharedPreferences {
        return context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }

    private fun getAccessToken(context: Context): String? {
        // shared_preferences stores keys with "flutter." prefix internally.
        return prefs(context).getString("flutter.access_token", null)
            ?: prefs(context).getString("access_token", null)
    }

    private fun getRefreshToken(context: Context): String? {
        return prefs(context).getString("flutter.refresh_token", null)
            ?: prefs(context).getString("refresh_token", null)
    }

    private fun setTokens(context: Context, accessToken: String, refreshToken: String) {
        val editor = prefs(context).edit()
        editor.putString("flutter.access_token", accessToken)
        editor.putString("flutter.refresh_token", refreshToken)
        editor.apply()
    }

    private fun sha256Hex(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val bytes = digest.digest(input.toByteArray(Charsets.UTF_8))
        val sb = StringBuilder()
        for (b in bytes) sb.append(String.format("%02x", b))
        return sb.toString()
    }

    private fun isDuplicate(context: Context, key: String, ttlMs: Long = 10 * 60 * 1000): Boolean {
        val now = System.currentTimeMillis()
        val p = prefs(context)
        val last = p.getLong("dedupe_$key", -1L)
        if (last > 0 && now - last < ttlMs) return true
        p.edit().putLong("dedupe_$key", now).apply()
        return false
    }

    private fun getTitleText(notification: Notification): String {
        val extras = notification.extras
        return extras?.getString(Notification.EXTRA_TITLE) ?: ""
    }

    private fun getMessageText(notification: Notification): String {
        val extras = notification.extras
        val text = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        if (text.isNotBlank()) return text
        val bigText = extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        if (bigText.isNotBlank()) return bigText
        val summary = extras?.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.toString() ?: ""
        return summary
    }

    private fun shouldRoughlyLookLikePayment(title: String, message: String, packageName: String): Boolean {
        val text = (title + " " + message).lowercase()
        
        // Quick skip for common false positives (OTP, verification codes, etc.)
        val falsePositives = listOf(
            "otp", "verification code", "confirm code", "password reset", "login code", "code:",
            "رمز التحقق", "رمز التأكيد"
        )
        if (falsePositives.any { text.contains(it) }) return false

        // Skip OUTGOING / SENT payments - we only want RECEIVED
        val sentIndicators = listOf(
            "you sent", "you transferred", "you paid", "sent to", "payment to",
            "transfer to", "paid to", "deducted for", "debited for",
            "تم ارسال", "ارسلت", "تم الدفع لـ", "دفعت", "تم خصم لـ", "تم التحويل الى",
            "حولت", "ارسال الى"
        )
        if (sentIndicators.any { text.contains(it) }) return false

        // Payment RECEIVED hints - what we want to capture
        val receivedHints = listOf(
            // English
            "received", "credited", "deposited", "you received", "payment received",
            "transfer received", "incoming", "you got",
            // Arabic
            "تم استلام", "تم ايداع", "استلمت", "وصلك", "تم تحويل لك", "تم الايداع",
            "وردت", "تم استقبال", "حوالة واردة",
            // General payment terms (can be received or sent - allow if no sent indicator)
            "payment", "transfer", "deposit", "credited",
            "تحويل", "ايداع", "حوالة", "دفعة"
        )

        // Check for recognized payment sources
        val packageLower = packageName.lowercase()
        val isKnownPaymentApp = listOf(
            "palpay", "jawwal", "bankofpalestine", "bop", "com.bop",
            "com.palpay", "com.jawwal", "ps.jawwal"
        ).any { packageLower.contains(it) }

        // Check for SMS apps (for Iburaq and bank SMS)
        val isSmsApp = listOf(
            "com.google.android.apps.messaging",
            "com.samsung.android.messaging",
            "com.android.mms",
            "com.android.messaging",
            "com.miui.mms",
            "com.huawei.message"
        ).any { packageLower.contains(it) }

        // Check for Iburaq transfer via SMS
        val isIburaqTransfer = isSmsApp && (
            text.contains("iburaq") || text.contains("ايبرق") || text.contains("البراق")
        )

        // Check for bank SMS with payment keywords
        val hasBankKeywords = text.contains("bank") || text.contains("بنك") || 
                              text.contains("bop") || text.contains("palestine")

        // Accept if: known payment app OR (SMS with Iburaq) OR (SMS with bank keywords and received hints)
        val hasReceivedHint = receivedHints.any { text.contains(it) }
        
        return when {
            isKnownPaymentApp && hasReceivedHint -> true
            isIburaqTransfer && hasReceivedHint -> true
            isSmsApp && hasBankKeywords && hasReceivedHint -> true
            else -> false
        }
    }

    private fun postJson(url: String, body: JSONObject, headers: Map<String, String>): Pair<Int, String> {
        val conn = URL(url).openConnection() as HttpURLConnection
        conn.requestMethod = "POST"
        conn.connectTimeout = 20000
        conn.readTimeout = 20000
        conn.doOutput = true
        headers.forEach { (k, v) -> conn.setRequestProperty(k, v) }
        conn.setRequestProperty("Content-Type", "application/json")

        val out = conn.outputStream
        out.write(body.toString().toByteArray(Charsets.UTF_8))
        out.flush()
        out.close()

        val code = conn.responseCode
        val inputStream = if (code in 200..299) conn.inputStream else conn.errorStream
        val reader = BufferedReader(InputStreamReader(inputStream))
        val response = reader.readText()
        reader.close()
        conn.disconnect()
        return Pair(code, response)
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val packageName = sbn.packageName ?: return
            val notification = sbn.notification ?: return
            val title = getTitleText(notification)
            val message = getMessageText(notification)

            if (title.isBlank() && message.isBlank()) return
            if (!shouldRoughlyLookLikePayment(title, message, packageName)) return

            val receivedAt = System.currentTimeMillis()

            val dedupeKeyRaw = "$packageName|$title|$message"
            val dedupeKey = sha256Hex(dedupeKeyRaw).take(24)
            if (isDuplicate(this, dedupeKey)) {
                Log.d(TAG, "Duplicate detected: $dedupeKey")
                return
            }

            val baseUrl = "https://payment-notification-saas-server.onrender.com/api"

            val accessToken = getAccessToken(this)
            val refreshToken = getRefreshToken(this)
            if (accessToken.isNullOrBlank() || refreshToken.isNullOrBlank()) {
                Log.d(TAG, "No tokens in SharedPreferences; skip forwarding.")
                return
            }

            val payload = JSONObject()
            payload.put("packageName", packageName)
            payload.put("title", title)
            payload.put("message", message)
            payload.put("receivedAt", receivedAt)

            val headers = mapOf("Authorization" to "Bearer $accessToken")
            val (code, responseBody) = postJson("$baseUrl/notifications/capture", payload, headers)
            Log.d(TAG, "Capture response: $code $responseBody")

            if (code == 401) {
                // Try refresh once, then retry.
                val refreshUrl = "$baseUrl/auth/refresh"
                val refreshBody = JSONObject()
                refreshBody.put("refreshToken", refreshToken)

                val refreshHeaders = mapOf("Content-Type" to "application/json")
                val (rCode, rBody) = postJson(refreshUrl, refreshBody, refreshHeaders)
                if (rCode in 200..299) {
                    val parsed = JSONObject(rBody)
                    val newAccessToken = parsed.optString("accessToken", "")
                    val newRefreshToken = parsed.optString("refreshToken", refreshToken)
                    if (newAccessToken.isNotBlank()) {
                        setTokens(this, newAccessToken, newRefreshToken)
                        val retryHeaders = mapOf("Authorization" to "Bearer $newAccessToken")
                        val (retryCode, retryBody) = postJson("$baseUrl/notifications/capture", payload, retryHeaders)
                        Log.d(TAG, "Capture retry response: $retryCode $retryBody")
                    }
                } else {
                    Log.e(TAG, "Refresh failed: $rCode $rBody")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "onNotificationPosted error", e)
        }
    }
}

