package com.example.nhamhealth_flutter

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private var notificationsChannel: MethodChannel? = null
    private val notificationExecutor = Executors.newSingleThreadExecutor()

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
                        val avatarUrl = call.argument<String>("avatarUrl")
                            ?: call.argument<String>("imageUrl")
                        val subText = call.argument<String>("subText")
                        showNotification(
                            title = title,
                            body = body,
                            notificationId = call.argument<String>("notificationId"),
                            referenceType = call.argument<String>("referenceType"),
                            referenceId = call.argument<String>("referenceId"),
                            avatarUrl = avatarUrl,
                            subText = subText,
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
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            setShowBadge(true)
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
        avatarUrl: String? = null,
        subText: String? = null,
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

        notificationExecutor.execute {
            val largeIconBitmap = loadBitmap(avatarUrl) ?: getDefaultAvatarBitmap()
            val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)

            if (!subText.isNullOrBlank()) {
                builder.setSubText(subText)
            }

            if (largeIconBitmap != null) {
                builder.setLargeIcon(largeIconBitmap)
            }

            getSystemService(NotificationManager::class.java)?.notify(
                systemNotificationId,
                builder.build(),
            )
        }
    }

    private fun loadBitmap(imageUrl: String?): Bitmap? {
        if (imageUrl.isNullOrBlank()) return null
        return try {
            val raw = imageUrl.trim()
            val bitmap = if (raw.startsWith("http://") || raw.startsWith("https://")) {
                val url = URL(raw)
                val connection = url.openConnection() as HttpURLConnection
                connection.doInput = true
                connection.connectTimeout = 4000
                connection.readTimeout = 4000
                connection.connect()
                val input = connection.inputStream
                val decoded = BitmapFactory.decodeStream(input)
                input.close()
                connection.disconnect()
                decoded
            } else if (raw.startsWith("file://")) {
                BitmapFactory.decodeFile(raw.removePrefix("file://"))
            } else if (File(raw).exists()) {
                BitmapFactory.decodeFile(raw)
            } else {
                null
            }
            if (bitmap != null) toCircleBitmap(bitmap) else null
        } catch (_: Exception) {
            null
        }
    }

    private fun getDefaultAvatarBitmap(): Bitmap? {
        return try {
            val drawable = ContextCompat.getDrawable(this, R.mipmap.ic_launcher) ?: return null
            val width = drawable.intrinsicWidth.coerceAtLeast(128)
            val height = drawable.intrinsicHeight.coerceAtLeast(128)
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            toCircleBitmap(bitmap)
        } catch (_: Exception) {
            null
        }
    }

    private fun toCircleBitmap(bitmap: Bitmap): Bitmap {
        val size = Math.min(bitmap.width, bitmap.height)
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint().apply {
            isAntiAlias = true
            isFilterBitmap = true
        }
        val rect = Rect(0, 0, size, size)
        val rectF = RectF(rect)
        canvas.drawARGB(0, 0, 0, 0)
        canvas.drawOval(rectF, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        val left = (bitmap.width - size) / 2
        val top = (bitmap.height - size) / 2
        val srcRect = Rect(left, top, left + size, top + size)
        canvas.drawBitmap(bitmap, srcRect, rect, paint)
        return output
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
