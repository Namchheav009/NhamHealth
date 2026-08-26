package com.example.nhamhealth_flutter

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GOOGLE_OAUTH_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getServerClientId" -> result.success(BuildConfig.GOOGLE_SERVER_CLIENT_ID)
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "NhamHealth notifications",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Community activity and health reminders"
            enableVibration(true)
        }
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    private companion object {
        const val GOOGLE_OAUTH_CHANNEL =
            "com.example.nhamhealth_flutter/google_oauth_config"
        const val NOTIFICATION_CHANNEL_ID = "nhamhealth_notifications"
    }
}
