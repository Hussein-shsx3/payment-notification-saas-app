package com.paymentnotify.app

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.Executors

/**
 * Background capture + offline queue. Must not run network on the main thread
 * ([NotificationListenerService] callbacks are on the main thread).
 */
object PaymentCaptureQueue {
    private const val TAG = "PaymentCaptureQueue"
    const val API_BASE_URL = "https://payment-notification-saas-server.onrender.com/api"
    private const val QUEUE_KEY = "pending_payment_queue"
    private const val QUEUE_MAX_ITEMS = 300

    /** Drains the offline queue without blocking the current capture POST on the listener executor. */
    private val queueFlushExecutor = Executors.newSingleThreadExecutor()

    private fun prefs(context: Context): SharedPreferences {
        return context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }

    private fun getAccessToken(context: Context): String? {
        return prefs(context).getString("flutter.access_token", null)
            ?: prefs(context).getString("access_token", null)
    }

    private fun getRefreshToken(context: Context): String? {
        return prefs(context).getString("flutter.refresh_token", null)
            ?: prefs(context).getString("refresh_token", null)
    }

    private fun setTokens(context: Context, accessToken: String, refreshToken: String) {
        prefs(context).edit()
            .putString("flutter.access_token", accessToken)
            .putString("flutter.refresh_token", refreshToken)
            .apply()
    }

    private fun sha256Hex(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val bytes = digest.digest(input.toByteArray(Charsets.UTF_8))
        val sb = StringBuilder()
        for (b in bytes) sb.append(String.format("%02x", b))
        return sb.toString()
    }

    private fun normalizeDigits(s: String): String {
        if (s.isEmpty()) return s
        val map = mapOf(
            '٠' to '0', '١' to '1', '٢' to '2', '٣' to '3', '٤' to '4',
            '٥' to '5', '٦' to '6', '٧' to '7', '٨' to '8', '٩' to '9',
        )
        return s.map { map[it] ?: it }.joinToString("")
    }

    /** Align with server: drop "رصيدكم المتوفر هو …" from SMS body before send/store. */
    private fun stripTrailingAvailableBalanceLine(s: String): String {
        var t = normalizeDigits(s.trim()).replace("\r\n", "\n")
        val re = Regex("""[\s.،\n]+رصيد(?:كم|ك)\s+المتوفر(?:\s+هو)?\s*[\d.,\s]+$""", RegexOption.IGNORE_CASE)
        t = re.replace(t, "").trim()
        return t.trimEnd('.', '،', ' ')
    }

    /** Short window: suppress only rapid re-posts of the exact same tray slot + same text (OEM spam). */
    private fun isDuplicate(context: Context, key: String, ttlMs: Long = 90_000L): Boolean {
        val now = System.currentTimeMillis()
        val p = prefs(context)
        val last = p.getLong("dedupe_$key", -1L)
        if (last > 0 && now - last < ttlMs) return true
        p.edit().putLong("dedupe_$key", now).apply()
        return false
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

    private fun postJson(url: String, body: JSONObject, headers: Map<String, String>): Pair<Int, String> {
        val conn = URL(url).openConnection() as HttpURLConnection
        conn.requestMethod = "POST"
        conn.connectTimeout = 10000
        conn.readTimeout = 10000
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

    /** True when the capture should stay queued for retry (auth, rate limit, server errors). */
    private fun shouldQueueRetryForCapture(code: Int): Boolean =
        code == 401 || code == 403 || code >= 500 || code == 429 || code == 408

    private fun sendPayloadWithRefresh(
        context: Context,
        baseUrl: String,
        payload: JSONObject,
        accessToken: String,
        refreshToken: String,
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
                        if (retryCode in 200..299) return true
                        if (shouldQueueRetryForCapture(retryCode)) return false
                        return true
                    }
                } else {
                    Log.e(TAG, "Refresh failed: $rCode $rBody")
                }
                return false
            }

            if (shouldQueueRetryForCapture(code)) return false
            return true
        } catch (e: Exception) {
            Log.e(TAG, "sendPayloadWithRefresh error", e)
            false
        }
    }

    /** Called from Flutter after login / token mirror — drains [pending_payment_queue]. */
    fun flushQueue(context: Context) {
        val accessToken = getAccessToken(context)
        val refreshToken = getRefreshToken(context)
        if (accessToken.isNullOrBlank() || refreshToken.isNullOrBlank()) {
            Log.d(TAG, "flushQueue: no tokens yet")
            return
        }

        val queue = readQueue(context)
        if (queue.isEmpty()) return

        val remaining = mutableListOf<JSONObject>()
        for (item in queue) {
            val ok = sendPayloadWithRefresh(
                context,
                API_BASE_URL,
                item,
                getAccessToken(context) ?: accessToken,
                getRefreshToken(context) ?: refreshToken,
            )
            if (!ok) remaining.add(item)
        }
        writeQueue(context, remaining)
        Log.d(TAG, "Queue flush done. Remaining=${remaining.size}")
    }

    /** Non-blocking: pending queue is drained on a separate thread so new captures are not delayed. */
    fun scheduleFlushQueue(context: Context) {
        val app = context.applicationContext
        queueFlushExecutor.execute {
            try {
                flushQueue(app)
            } catch (e: Exception) {
                Log.e(TAG, "scheduleFlushQueue error", e)
            }
        }
    }

    /**
     * Full pipeline: filter → dedupe → POST or enqueue (runs on background thread).
     */
    fun processPostedNotification(
        context: Context,
        packageName: String,
        title: String,
        message: String,
        instanceKey: String,
        receivedAt: Long,
    ) {
        if (title.isBlank() && message.isBlank()) return

        val messageStripped = stripTrailingAvailableBalanceLine(message)

        // Normalize digits for robust matching (Eastern Arabic numerals -> ASCII)
        val normalizedTitle = normalizeDigits(title)
        val normalizedMessage = normalizeDigits(messageStripped)

        if (!PaymentNotifyFilters.shouldRoughlyLookLikePayment(normalizedTitle, normalizedMessage, packageName)) {
            Log.d(TAG, "Ignored non-payment: pkg=$packageName title=${title.take(80)} message=${message.take(120)} normalized=${(normalizedTitle + " "+ normalizedMessage).take(120)}")
            return
        }

        // Include title+message so different transfers are not dropped when the OS reuses sbn.key.
        // Use normalized title/message in dedupe key so numerals variations don't bypass dedupe
        val dedupeRaw = "$instanceKey\u0000$normalizedTitle\u0000$normalizedMessage"
        val dedupeKey = sha256Hex(dedupeRaw)
        if (isDuplicate(context, dedupeKey)) {
            Log.d(TAG, "Duplicate post (same key+text within TTL): ${dedupeKey.take(12)}… pkg=$packageName")
            return
        }

        val payload = JSONObject()
        payload.put("packageName", packageName)
        payload.put("title", title)
        payload.put("message", messageStripped)
        payload.put("receivedAt", receivedAt)
        payload.put("notificationKey", instanceKey)

        Log.d(TAG, "Prepared payload summary pkg=$packageName dedupe=${dedupeKey.take(12)} title=${title.take(80)} message=${message.take(120)}")

        val accessToken = getAccessToken(context)
        val refreshToken = getRefreshToken(context)
        if (accessToken.isNullOrBlank() || refreshToken.isNullOrBlank()) {
            Log.w(TAG, "No tokens yet — queueing capture for when user is logged in (main account)")
            enqueuePayload(context, payload)
            return
        }

        val sent = sendPayloadWithRefresh(context, API_BASE_URL, payload, accessToken, refreshToken)
        if (!sent) {
            enqueuePayload(context, payload)
        }
        scheduleFlushQueue(context)
    }
}
