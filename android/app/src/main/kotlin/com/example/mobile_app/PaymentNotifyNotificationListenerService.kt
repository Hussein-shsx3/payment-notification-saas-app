package com.example.mobile_app

import android.app.Notification
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.net.ConnectivityManager
import android.net.Network
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

import org.json.JSONArray
import org.json.JSONObject

import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.Executors

class PaymentNotifyNotificationListenerService : NotificationListenerService() {
    private val TAG = "PaymentNotifyListener"

    private val apiBaseUrl = "https://payment-notification-saas-server.onrender.com/api"

    /** Serializes HTTP work so we never block the main thread or the listener callback. */
    private val ioExecutor = Executors.newSingleThreadExecutor()

    private val mainHandler = Handler(Looper.getMainLooper())
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var legacyConnectivityReceiver: BroadcastReceiver? = null

    private val debouncedFlushRunnable = Runnable {
        ioExecutor.execute {
            try {
                flushQueue(applicationContext, apiBaseUrl)
            } catch (e: Exception) {
                Log.e(TAG, "debouncedFlush error", e)
            }
        }
    }

    // Same action/extras as notification_listener_service's NotificationListener → Flutter EventChannel.
    private val flutterBroadcastAction = "slayer.notification.listener.service.intent"
    private val QUEUE_KEY = "pending_payment_queue"
    private val QUEUE_MAX_ITEMS = 300

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
            "transfer to", "paid to", "outgoing transfer", "money sent", "transaction sent",
            "deducted for", "debited for", "debited", "withdrawal", "cash out",
            "تم ارسال", "ارسلت", "تم الدفع لـ", "دفعت", "تم خصم لـ", "تم التحويل الى",
            "حولت", "ارسال الى", "حوالة صادرة", "صادرة من حسابك", "قمت بارسال",
            "تم سحب", "سحب", "شراء", "تم الدفع"
        )
        if (sentIndicators.any { text.contains(it) }) return false

        // Payment RECEIVED hints - what we want to capture
        val receivedHints = listOf(
            // English
            "received", "credited", "deposited", "you received", "payment received",
            "transfer received", "incoming", "you got", "account credited", "credit alert", "cash in",
            // Arabic
            "تم استلام", "تم ايداع", "استلمت", "وصلك", "تم تحويل لك", "تم الايداع",
            "تم إيداع", "تم الإيداع", "وردت", "تم استقبال", "حوالة واردة", "حوالة واردة لحسابك",
            "واردة الى حسابك", "واردة إلى حسابك", "واردة لحسابك",
            "تمت إضافة", "تم اضافه", "اضافة الى حسابك", "إضافة إلى حسابك", "تم اضافة", "تم إضافة",
            "إشعار إيداع", "اشعار ايداع",
            // General payment terms (can be received or sent - allow if no sent indicator)
            "payment", "transfer", "deposit", "credited",
            "تحويل", "ايداع", "حوالة", "دفعة"
        )

        // Check for recognized payment sources
        val packageLower = packageName.lowercase()
        val isKnownPaymentApp = listOf(
            "palpay", "jawwal", "bankofpalestine", "bop", "com.bop",
            "com.palpay", "com.jawwal", "ps.jawwal", "bank of palestine",
            "بال باي", "بالباي", "جوال باي", "بنك فلسطين"
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

    private fun readQueue(context: Context): MutableList<JSONObject> {
        val raw = prefs(context).getString(QUEUE_KEY, "[]") ?: "[]"
        return try {
            val arr = JSONArray(raw)
            val out = mutableListOf<JSONObject>()
            for (i in 0 until arr.length()) {
                val item = arr.optJSONObject(i)
                if (item != null) out.add(item)
            }
            out
        } catch (_: Exception) {
            mutableListOf()
        }
    }

    private fun writeQueue(context: Context, queue: List<JSONObject>) {
        val arr = JSONArray()
        queue.forEach { arr.put(it) }
        prefs(context).edit().putString(QUEUE_KEY, arr.toString()).apply()
    }

    private fun enqueuePayload(context: Context, payload: JSONObject) {
        val queue = readQueue(context)
        queue.add(payload)
        if (queue.size > QUEUE_MAX_ITEMS) {
            val extra = queue.size - QUEUE_MAX_ITEMS
            repeat(extra) { queue.removeAt(0) }
        }
        writeQueue(context, queue)
        Log.d(TAG, "Queued payload. Pending=${queue.size}")
    }

    private fun sendPayloadWithRefresh(
        context: Context,
        baseUrl: String,
        payload: JSONObject,
        accessToken: String,
        refreshToken: String
    ): Boolean {
        return try {
            val headers = mapOf("Authorization" to "Bearer $accessToken")
            val (code, responseBody) = postJson("$baseUrl/notifications/capture", payload, headers)
            Log.d(TAG, "Capture response: $code $responseBody")

            if (code in 200..299) {
                return true
            }

            if (code == 401) {
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
                        setTokens(context, newAccessToken, newRefreshToken)
                        val retryHeaders = mapOf("Authorization" to "Bearer $newAccessToken")
                        val (retryCode, retryBody) = postJson("$baseUrl/notifications/capture", payload, retryHeaders)
                        Log.d(TAG, "Capture retry response: $retryCode $retryBody")
                        return retryCode in 200..299
                    }
                } else {
                    Log.e(TAG, "Refresh failed: $rCode $rBody")
                }
            }

            // 5xx / 429: not delivered — caller should queue for retry.
            if (code >= 500 || code == 429) return false
            // Other 4xx: treat as non-retryable; do not queue (avoid infinite bad retries).
            return true
        } catch (e: Exception) {
            Log.e(TAG, "sendPayloadWithRefresh error", e)
            false
        }
    }

    private fun flushQueue(context: Context, baseUrl: String) {
        val accessToken = getAccessToken(context)
        val refreshToken = getRefreshToken(context)
        if (accessToken.isNullOrBlank() || refreshToken.isNullOrBlank()) return

        val queue = readQueue(context)
        if (queue.isEmpty()) return

        val remaining = mutableListOf<JSONObject>()
        for (item in queue) {
            val ok = sendPayloadWithRefresh(context, baseUrl, item, getAccessToken(context) ?: accessToken, getRefreshToken(context) ?: refreshToken)
            if (!ok) remaining.add(item)
        }
        writeQueue(context, remaining)
        Log.d(TAG, "Queue flush done. Remaining=${remaining.size}")
    }

    /**
     * When the app process is not running, [NotificationListenerService] is still bound by the
     * system for new notifications. When the user only loses network, we must flush the offline
     * queue as soon as connectivity returns — without waiting for another notification.
     */
    private fun scheduleDebouncedFlush() {
        mainHandler.removeCallbacks(debouncedFlushRunnable)
        mainHandler.postDelayed(debouncedFlushRunnable, 1200L)
    }

    private fun registerConnectivityFlush() {
        unregisterConnectivityFlush()
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val cb = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    scheduleDebouncedFlush()
                }

                override fun onCapabilitiesChanged(
                    network: Network,
                    networkCapabilities: android.net.NetworkCapabilities
                ) {
                    if (networkCapabilities.hasCapability(android.net.NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
                        scheduleDebouncedFlush()
                    }
                }
            }
            networkCallback = cb
            try {
                cm.registerDefaultNetworkCallback(cb)
            } catch (e: Exception) {
                Log.e(TAG, "registerDefaultNetworkCallback failed", e)
            }
        } else {
            @Suppress("DEPRECATION")
            val filter = IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION)
            val receiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    scheduleDebouncedFlush()
                }
            }
            legacyConnectivityReceiver = receiver
            registerReceiver(receiver, filter)
        }
    }

    private fun unregisterConnectivityFlush() {
        mainHandler.removeCallbacks(debouncedFlushRunnable)
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        networkCallback?.let {
            try {
                cm.unregisterNetworkCallback(it)
            } catch (_: Exception) {
            }
            networkCallback = null
        }
        legacyConnectivityReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) {
            }
            legacyConnectivityReceiver = null
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        registerConnectivityFlush()
        // Catch-up after reboot / listener rebind while items were queued offline.
        scheduleDebouncedFlush()
    }

    override fun onListenerDisconnected() {
        unregisterConnectivityFlush()
        super.onListenerDisconnected()
    }

    override fun onDestroy() {
        unregisterConnectivityFlush()
        ioExecutor.shutdown()
        super.onDestroy()
    }

    /**
     * Forwards notification text to Flutter (notification_listener_service) using the same
     * broadcast contract as the plugin. Includes EXTRA_BIG_TEXT via [getMessageText], which the
     * plugin's bundled listener does not expose — without this, the Dart stream never receives
     * events (our manifest only registers this service, not the plugin class).
     */
    private fun sendFlutterBroadcast(sbn: StatusBarNotification, title: String, message: String) {
        try {
            val notification = sbn.notification ?: return
            val isOngoing = (notification.flags and Notification.FLAG_ONGOING_EVENT) != 0
            val intent = Intent(flutterBroadcastAction)
            intent.putExtra("package_name", sbn.packageName)
            intent.putExtra("notification_id", sbn.id)
            intent.putExtra("title", title)
            intent.putExtra("message", message)
            intent.putExtra("is_ongoing", isOngoing)
            intent.putExtra("is_removed", false)
            intent.putExtra("can_reply_to_it", false)
            intent.putExtra("contain_image", false)
            sendBroadcast(intent)
        } catch (e: Exception) {
            Log.e(TAG, "sendFlutterBroadcast error", e)
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

            sendFlutterBroadcast(sbn, title, message)

            if (title.isBlank() && message.isBlank()) return
            if (!shouldRoughlyLookLikePayment(title, message, packageName)) {
                Log.d(TAG, "Ignored non-payment: pkg=$packageName title=$title")
                return
            }

            val receivedAt = System.currentTimeMillis()

            val dedupeKeyRaw = "$packageName|$title|$message"
            val dedupeKey = sha256Hex(dedupeKeyRaw).take(24)
            if (isDuplicate(this, dedupeKey)) {
                Log.d(TAG, "Duplicate detected: $dedupeKey")
                return
            }

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

            val sent = sendPayloadWithRefresh(this, apiBaseUrl, payload, accessToken, refreshToken)
            if (!sent) {
                enqueuePayload(this, payload)
            }
            flushQueue(this, apiBaseUrl)
        } catch (e: Exception) {
            Log.e(TAG, "onNotificationPosted error", e)
        }
    }
}

