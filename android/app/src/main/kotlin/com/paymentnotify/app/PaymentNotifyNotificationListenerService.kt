package com.paymentnotify.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.Network
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import java.util.concurrent.Executors

/**
 * Must not perform network I/O on the listener callback thread (main thread) — Android blocks it
 * ([NetworkOnMainThreadException]), so all capture work runs on [ioExecutor].
 */
class PaymentNotifyNotificationListenerService : NotificationListenerService() {
    private val TAG = "PaymentNotifyListener"

    /** Keeps the listener process in a foreground state so OEMs are less likely to kill capture when the UI is closed. */
    private val fgNotificationId = 71001
    private val fgChannelId = "payment_capture_listener"

    private val ioExecutor = Executors.newSingleThreadExecutor()

    private val mainHandler = Handler(Looper.getMainLooper())
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var legacyConnectivityReceiver: BroadcastReceiver? = null

    private val debouncedFlushRunnable = Runnable {
        ioExecutor.execute {
            try {
                PaymentCaptureQueue.flushQueue(applicationContext)
            } catch (e: Exception) {
                Log.e(TAG, "debouncedFlush error", e)
            }
        }
    }

    private val flutterBroadcastAction = "slayer.notification.listener.service.intent"

    private fun getTitleText(notification: Notification): String {
        val extras = notification.extras ?: return ""
        val cs = extras.getCharSequence(Notification.EXTRA_TITLE)
            ?: extras.getCharSequence("android.title")
        return cs?.toString()?.trim() ?: ""
    }

    /**
     * Banks often put the real body in [Notification.EXTRA_TEXT_LINES] / [Notification.EXTRA_SUB_TEXT];
     * [Notification.EXTRA_TITLE] may be [Spannable] — use [getCharSequence], not [getString].
     */
    private fun getMessageText(notification: Notification): String {
        val extras = notification.extras ?: return ""
        val chunks = LinkedHashSet<String>()
        fun add(s: CharSequence?) {
            val t = s?.toString()?.trim() ?: return
            if (t.isNotEmpty()) chunks.add(t)
        }
        add(extras.getCharSequence(Notification.EXTRA_TEXT))
        add(extras.getCharSequence(Notification.EXTRA_BIG_TEXT))
        extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)?.forEach { add(it) }
        add(extras.getCharSequence(Notification.EXTRA_SUB_TEXT))
        add(extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT))
        add(extras.getCharSequence(Notification.EXTRA_INFO_TEXT))
        add(extras.getCharSequence("android.text"))
        add(extras.getCharSequence("android.bigText"))
        add(extras.getCharSequence("android.title"))
        return chunks.joinToString("\n")
    }

    private fun normalizeDigits(s: String): String {
        if (s.isEmpty()) return s
        val map = mapOf(
            '٠' to '0', '١' to '1', '٢' to '2', '٣' to '3', '٤' to '4',
            '٥' to '5', '٦' to '6', '٧' to '7', '٨' to '8', '٩' to '9',
        )
        return s.map { map[it] ?: it }.joinToString("")
    }

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

    private fun scheduleDebouncedFlush() {
        mainHandler.removeCallbacks(debouncedFlushRunnable)
        mainHandler.postDelayed(debouncedFlushRunnable, 450L)
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
                    networkCapabilities: android.net.NetworkCapabilities,
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

    private fun ensureCaptureForeground() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val nm = getSystemService(NotificationManager::class.java)!!
                val ch = NotificationChannel(
                    fgChannelId,
                    getString(R.string.payment_capture_channel_name),
                    NotificationManager.IMPORTANCE_LOW,
                )
                ch.setShowBadge(false)
                nm.createNotificationChannel(ch)
            }
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, fgChannelId)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
            }
            builder.setContentTitle(getString(R.string.payment_capture_fg_title))
                .setContentText(getString(R.string.payment_capture_fg_text))
                .setSmallIcon(android.R.drawable.stat_notify_sync)
                .setOngoing(true)
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                @Suppress("DEPRECATION")
                builder.setPriority(Notification.PRIORITY_LOW)
            }
            val notification = builder.build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    fgNotificationId,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
                )
            } else {
                @Suppress("DEPRECATION")
                startForeground(fgNotificationId, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "startForeground failed — capture may still work until process is killed", e)
        }
    }

    private fun stopCaptureForeground() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(Service.STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (_: Exception) {
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
        ensureCaptureForeground()
        registerConnectivityFlush()
        scheduleDebouncedFlush()
    }

    override fun onListenerDisconnected() {
        unregisterConnectivityFlush()
        stopCaptureForeground()
        super.onListenerDisconnected()
    }

    override fun onDestroy() {
        unregisterConnectivityFlush()
        stopCaptureForeground()
        ioExecutor.shutdown()
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val packageName = sbn.packageName ?: return
            val notification = sbn.notification ?: return
            val title = getTitleText(notification)
            val message = getMessageText(notification)

            // Quick structured debug: package, id, channel, title, message (truncated), extras keys
            try {
                val ch = notification.channelId ?: ""
                val extras = notification.extras
                val keys = extras?.keySet()?.joinToString(",") ?: ""
                Log.d(TAG, "POST pkg=$packageName id=${sbn.id} tag=${sbn.tag} time=${sbn.postTime} ch=$ch title=${title.take(80)} message=${message.take(160)} extras=$keys")
                val normalized = normalizeDigits(message)
                if (normalized != message) {
                    Log.d(TAG, "Normalized digits: ${normalized.take(120)}")
                }
            } catch (e: Exception) {
                Log.w(TAG, "debug log extras failed", e)
            }

            sendFlutterBroadcast(sbn, title, message)

            val instanceKey = sbn.key?.takeIf { it.isNotBlank() }
                ?: "$packageName|${sbn.id}|${sbn.tag ?: ""}"
            val receivedAt = System.currentTimeMillis()

            ioExecutor.execute {
                try {
                    PaymentCaptureQueue.processPostedNotification(
                        applicationContext,
                        packageName,
                        title,
                        message,
                        instanceKey,
                        receivedAt,
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "processPostedNotification error", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "onNotificationPosted error", e)
        }
    }
}
