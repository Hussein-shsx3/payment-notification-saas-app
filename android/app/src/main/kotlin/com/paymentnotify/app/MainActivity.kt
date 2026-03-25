package com.paymentnotify.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.paymentnotify/native_capture",
        ).setMethodCallHandler { call, result ->
            if (call.method == "flushQueue") {
                Thread {
                    try {
                        PaymentCaptureQueue.flushQueue(applicationContext)
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "flushQueue", e)
                    }
                }.start()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
