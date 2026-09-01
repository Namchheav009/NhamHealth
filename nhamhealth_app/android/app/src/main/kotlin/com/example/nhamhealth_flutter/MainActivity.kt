package com.example.nhamhealth_flutter

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var notificationsChannel: MethodChannel? = null

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

        notificationsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATIONS_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "showNotification" -> {
                        val title = call.argument<String>("title") ?: "NhamHealth"
                        val body = call.argument<String>("body") ?: ""
                        showNotification(
                            title = title,
                            body = body,
                            notificationId = call.argument<String>("notificationId"),
                            referenceType = call.argument<String>("referenceType"),
                            referenceId = call.argument<String>("referenceId"),
                        )
                        result.success(null)
                    }
                    "getInitialNotificationTap" -> {
                        val data = notificationData(intent)
                        intent?.action = null
                        result.success(data)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        deliverNotificationTap(intent)
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

    private fun showNotification(
        title: String,
        body: String,
        notificationId: String?,
        referenceType: String?,
        referenceId: String?,
    ) {
        val systemNotificationId = notificationId?.toIntOrNull()
            ?: (System.currentTimeMillis() and 0x7FFFFFFF).toInt()
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            action = ACTION_OPEN_NOTIFICATION
            putExtra(EXTRA_NOTIFICATION_ID, notificationId.orEmpty())
            putExtra(EXTRA_REFERENCE_TYPE, referenceType.orEmpty())
            putExtra(EXTRA_REFERENCE_ID, referenceId.orEmpty())
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            systemNotificationId,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        getSystemService(NotificationManager::class.java).notify(
            systemNotificationId,
            notification,
        )
    }

    private fun deliverNotificationTap(intent: Intent?) {
        val data = notificationData(intent) ?: return
        notificationsChannel?.invokeMethod(
            "notificationTapped",
            data,
        )
        intent?.action = null
    }

    private fun notificationData(intent: Intent?): Map<String, String>? {
        if (intent?.action != ACTION_OPEN_NOTIFICATION) return null
        return mapOf(
            "notificationId" to intent.getStringExtra(EXTRA_NOTIFICATION_ID).orEmpty(),
            "referenceType" to intent.getStringExtra(EXTRA_REFERENCE_TYPE).orEmpty(),
            "referenceId" to intent.getStringExtra(EXTRA_REFERENCE_ID).orEmpty(),
        )
    }

    private companion object {
        const val GOOGLE_OAUTH_CHANNEL =
            "com.example.nhamhealth_flutter/google_oauth_config"
        const val NOTIFICATIONS_CHANNEL =
            "com.example.nhamhealth_flutter/notifications"
        const val NOTIFICATION_CHANNEL_ID = "nhamhealth_notifications"
        const val ACTION_OPEN_NOTIFICATION =
            "com.example.nhamhealth_flutter.OPEN_NOTIFICATION"
        const val EXTRA_NOTIFICATION_ID = "notificationId"
        const val EXTRA_REFERENCE_TYPE = "referenceType"
        const val EXTRA_REFERENCE_ID = "referenceId"
    }
}
