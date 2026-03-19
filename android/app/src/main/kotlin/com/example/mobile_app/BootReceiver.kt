package com.example.mobile_app

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    private val TAG = "PaymentNotifyBoot"

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            Log.d(TAG, "Boot completed - ensuring notification listener is active")
            
            // Check if notification listener permission is granted
            val flat = Settings.Secure.getString(
                context.contentResolver,
                "enabled_notification_listeners"
            )
            val componentName = ComponentName(context, PaymentNotifyNotificationListenerService::class.java)
            val isEnabled = flat?.contains(componentName.flattenToString()) == true
            
            if (isEnabled) {
                Log.d(TAG, "Notification listener permission is granted - service will be started by system")
            } else {
                Log.d(TAG, "Notification listener permission not granted - user needs to enable it")
            }
        }
    }
}
