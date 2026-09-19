package com.example.nhamhealth_flutter

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.Person
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.IconCompat
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
            val isCommunity = isCommunityNotification(referenceType, subText, title, body)
            val isWellness = isWellnessNotification(referenceType, title, body)

            val loadedAvatar = loadBitmap(avatarUrl)
            val finalLargeIcon = when {
                loadedAvatar != null -> loadedAvatar
                isCommunity -> generateUserAvatarBitmap(title)
                isWellness -> generateWellnessIconBitmap(title)
                else -> null
            }

            val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setColor(ContextCompat.getColor(this, R.color.nhamhealth_notification_green))
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setCategory(if (isCommunity) NotificationCompat.CATEGORY_MESSAGE else NotificationCompat.CATEGORY_RECOMMENDATION)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)

            if (!subText.isNullOrBlank()) {
                builder.setSubText(subText)
            }

            if (finalLargeIcon != null) {
                builder.setLargeIcon(finalLargeIcon)
                if (isCommunity) {
                    val person = Person.Builder()
                        .setName(title)
                        .setIcon(IconCompat.createWithBitmap(finalLargeIcon))
                        .setKey(referenceId ?: title)
                        .build()
                    builder.addPerson(person)
                }
            }

            getSystemService(NotificationManager::class.java)?.notify(
                systemNotificationId,
                builder.build(),
            )
        }
    }

    private fun isCommunityNotification(
        referenceType: String?,
        subText: String?,
        title: String?,
        body: String?,
    ): Boolean {
        val ref = referenceType?.trim()?.uppercase().orEmpty()
        if (ref in setOf(
                "POST",
                "COMMENT",
                "USER",
                "COMMUNITY",
                "FOLLOW_CONNECTION",
                "FOLLOW_CONNECTION_ACCEPTED",
                "SOCIAL",
                "FRIEND"
            )
        ) {
            return true
        }

        val sub = subText?.trim()?.lowercase().orEmpty()
        if (sub in setOf(
                "like",
                "comment",
                "reply",
                "share",
                "follow",
                "friend",
                "invitation",
                "community",
                "social"
            )
        ) {
            return true
        }

        val b = body?.trim()?.lowercase().orEmpty()
        if (b.contains("liked") || b.contains("commented") || b.contains("replied") ||
            b.contains("shared") || b.contains("following") || b.contains("followed") ||
            b.contains("friend") || b.contains("invitation") ||
            b.contains("ចូលចិត្ត") || b.contains("មតិ") || b.contains("ចែករំលែក") ||
            b.contains("តាមដាន") || b.contains("មិត្តភក្តិ")
        ) {
            return true
        }

        return false
    }

    private fun isWellnessNotification(
        referenceType: String?,
        title: String?,
        body: String?,
    ): Boolean {
        val ref = referenceType?.trim()?.uppercase().orEmpty()
        if (ref in setOf("HEALTH", "REMINDER", "AI_FOOD", "WELLNESS")) {
            return true
        }
        val t = title?.trim()?.lowercase().orEmpty()
        val b = body?.trim()?.lowercase().orEmpty()
        return t.contains("water") || t.contains("hydration") || t.contains("meal") ||
                t.contains("drink") || t.contains("food") || t.contains("ទឹក") ||
                b.contains("water") || b.contains("hydration") || b.contains("drink")
    }

    private val AVATAR_PALETTE = intArrayOf(
        0xFF10B981.toInt(), // Emerald Green
        0xFF0D9488.toInt(), // Teal
        0xFF2563EB.toInt(), // Royal Blue
        0xFF4F46E5.toInt(), // Indigo
        0xFF7C3AED.toInt(), // Violet
        0xFFD946EF.toInt(), // Fuchsia
        0xFFE11D48.toInt(), // Rose
        0xFFEA580C.toInt(), // Warm Orange
        0xFF0284C7.toInt(), // Sky Blue
    )

    private fun generateUserAvatarBitmap(name: String?, size: Int = 192): Bitmap {
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)

        // Clip to circle
        val circlePath = Path().apply {
            addCircle(size / 2f, size / 2f, size / 2f, Path.Direction.CW)
        }
        canvas.clipPath(circlePath)

        val cleanName = name?.trim().orEmpty()
        val hash = if (cleanName.isNotEmpty()) Math.abs(cleanName.hashCode()) else 0
        val bgColor = AVATAR_PALETTE[hash % AVATAR_PALETTE.size]
        canvas.drawColor(bgColor)

        val initials = extractInitials(cleanName)
        val hasLettersOrDigits = initials.any { Character.isLetterOrDigit(it) }

        if (hasLettersOrDigits) {
            val textPaint = Paint().apply {
                isAntiAlias = true
                color = Color.WHITE
                textSize = size * 0.40f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                textAlign = Paint.Align.CENTER
            }
            val textBounds = Rect()
            textPaint.getTextBounds(initials, 0, initials.length, textBounds)
            val textY = (size / 2f) - textBounds.exactCenterY()
            canvas.drawText(initials, size / 2f, textY, textPaint)
        } else {
            // Crisp user silhouette (head + shoulders)
            val iconPaint = Paint().apply {
                isAntiAlias = true
                color = Color.WHITE
                style = Paint.Style.FILL
            }
            canvas.drawCircle(size * 0.5f, size * 0.36f, size * 0.17f, iconPaint)
            val bodyRect = RectF(size * 0.18f, size * 0.60f, size * 0.82f, size * 1.25f)
            canvas.drawOval(bodyRect, iconPaint)
        }

        return output
    }

    private fun extractInitials(name: String?): String {
        if (name.isNullOrBlank()) return ""
        var clean = name.trim()
        val actionSuffixes = listOf(" Like", " Comment", " Share", " Follow", " Reply", " ចូលចិត្ត")
        for (suffix in actionSuffixes) {
            if (clean.endsWith(suffix, ignoreCase = true)) {
                clean = clean.substring(0, clean.length - suffix.length).trim()
            }
        }
        val words = clean.split(Regex("\\s+")).filter { it.isNotBlank() }
        if (words.isEmpty()) return ""
        return if (words.size >= 2) {
            val first = getFirstCodePoint(words.first())
            val last = getFirstCodePoint(words.last())
            (first + last).uppercase()
        } else {
            val single = words[0]
            if (single.length >= 2 && single[0].isLetter() && single[1].isLetter()) {
                single.substring(0, 2).uppercase()
            } else {
                getFirstCodePoint(single).uppercase()
            }
        }
    }

    private fun getFirstCodePoint(text: String): String {
        if (text.isEmpty()) return ""
        val cp = text.codePointAt(0)
        return String(Character.toChars(cp))
    }

    private fun generateWellnessIconBitmap(title: String?, size: Int = 192): Bitmap {
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val path = Path().apply {
            addCircle(size / 2f, size / 2f, size / 2f, Path.Direction.CW)
        }
        canvas.clipPath(path)

        val t = title?.trim()?.lowercase().orEmpty()
        val isWater = t.contains("water") || t.contains("hydration") || t.contains("ទឹក")

        val bgColor = if (isWater) 0xFF0284C7.toInt() else 0xFF16875B.toInt()
        canvas.drawColor(bgColor)

        val iconPaint = Paint().apply {
            isAntiAlias = true
            color = Color.WHITE
            style = Paint.Style.FILL
        }

        if (isWater) {
            val dropPath = Path()
            val cx = size * 0.5f
            val topY = size * 0.25f
            val bottomY = size * 0.72f
            val r = size * 0.20f
            dropPath.moveTo(cx, topY)
            dropPath.quadTo(cx - r * 1.2f, size * 0.55f, cx - r, bottomY - r)
            dropPath.arcTo(RectF(cx - r, bottomY - 2 * r, cx + r, bottomY), 180f, -180f)
            dropPath.quadTo(cx + r * 1.2f, size * 0.55f, cx, topY)
            dropPath.close()
            canvas.drawPath(dropPath, iconPaint)
        } else {
            val heartPath = Path()
            val cx = size * 0.5f
            val cy = size * 0.5f
            val w = size * 0.22f
            val h = size * 0.22f
            heartPath.moveTo(cx, cy + h * 0.9f)
            heartPath.cubicTo(cx - w * 1.5f, cy - h * 0.3f, cx - w * 0.8f, cy - h * 1.3f, cx, cy - h * 0.5f)
            heartPath.cubicTo(cx + w * 0.8f, cy - h * 1.3f, cx + w * 1.5f, cy - h * 0.3f, cx, cy + h * 0.9f)
            heartPath.close()
            canvas.drawPath(heartPath, iconPaint)
        }

        return output
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

    private fun toCircleBitmap(bitmap: Bitmap, targetSize: Int = 192): Bitmap {
        val minDim = Math.min(bitmap.width, bitmap.height)
        val output = Bitmap.createBitmap(targetSize, targetSize, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint().apply {
            isAntiAlias = true
            isFilterBitmap = true
        }
        val rect = Rect(0, 0, targetSize, targetSize)
        val rectF = RectF(rect)
        canvas.drawARGB(0, 0, 0, 0)
        canvas.drawOval(rectF, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        val left = (bitmap.width - minDim) / 2
        val top = (bitmap.height - minDim) / 2
        val srcRect = Rect(left, top, left + minDim, top + minDim)
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
