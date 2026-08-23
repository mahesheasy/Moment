package app.moment.moment

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import app.moment.moment.widget.MomentWidgetDataStore
import app.moment.moment.widget.MomentWidgetUpdater
import app.moment.moment.widget.WidgetBitmap
import app.moment.moment.widget.WidgetMomentEntry
import app.moment.moment.widget.WidgetMomentQueue
import app.moment.moment.widget.WidgetRelativeTime
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.runBlocking

/**
 * Applies incoming moments to the home-screen widget without starting Flutter.
 *
 * FCM calls [onMessageReceived] on a background thread and only guarantees the
 * process stays alive until it returns, so all work here is deliberately
 * synchronous rather than dispatched to a coroutine scope that could be torn
 * down mid-download.
 */
class MomentFirebaseMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        // Dart reads this on next launch; the token would otherwise be lost if
        // it rotated while the app was killed.
        getSharedPreferences(PUSH_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_PENDING_TOKEN, token)
            .commit()
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        if (data["type"] != "moment") return

        // Always update the widget on push — server eligibility can lag local prefs.
        runCatching { applyToWidget(data) }
        if (NotificationPreferencesStore.shouldShowNotification(applicationContext, "moment")) {
            runCatching { postNotification(data) }
        }
    }

    private fun applyToWidget(data: Map<String, String>) {
        val existing = MomentWidgetDataStore.load(applicationContext)
        val createdAtMillis =
            WidgetRelativeTime.parseMillis(data["createdAtMillis"])
                ?: WidgetRelativeTime.parseMillis(data["createdAt"])
                ?: System.currentTimeMillis()
        val senderName = data["headerTitle"].orEmpty().ifBlank {
            data["senderName"].orEmpty()
        }

        fun persist(imagePath: String?, avatarPath: String?) {
            val entry =
                WidgetMomentEntry(
                    momentId = data["momentId"].orEmpty(),
                    senderName = senderName,
                    senderId = data["senderId"].orEmpty(),
                    imagePath = imagePath,
                    avatarPath = avatarPath,
                    caption = data["caption"].orEmpty(),
                    createdAtMillis = createdAtMillis,
                    relativeTime = WidgetRelativeTime.format(createdAtMillis),
                )
            WidgetMomentQueue.prependMoment(applicationContext, entry)
            MomentWidgetDataStore.save(
                context = applicationContext,
                senderName = senderName,
                momentId = data["momentId"].orEmpty(),
                imagePath = imagePath,
                caption = data["caption"],
                relativeTime = WidgetRelativeTime.format(createdAtMillis),
                createdAtMillis = createdAtMillis,
                widgetMode = existing.widgetMode,
                headerEmoji = data["headerEmoji"],
                avatarPath = avatarPath,
                senderId = data["senderId"],
            )
        }

        val momentId = data["momentId"].orEmpty().ifBlank { "latest" }
        persist(null, null)
        runBlocking { MomentWidgetUpdater.update(applicationContext) }

        val imagePath = download(data["imageUrl"], "moment_$momentId.jpg")
        val avatarPath = download(data["avatarUrl"], "avatar_$momentId.jpg")
        persist(imagePath, avatarPath)
        runBlocking { MomentWidgetUpdater.update(applicationContext) }
    }

    private fun download(url: String?, fileName: String): String? {
        if (url.isNullOrBlank()) return null
        return try {
            val connection = (URL(url).openConnection() as HttpURLConnection).apply {
                connectTimeout = 10_000
                readTimeout = 15_000
                requestMethod = "GET"
            }
            val bytes = connection.use { it.inputStream.readBytes() }
            if (bytes.isEmpty()) return null

            val dir = File(applicationContext.filesDir, "widget")
            if (!dir.exists()) dir.mkdirs()
            WidgetBitmap.writeDownsampled(bytes, File(dir, fileName))
        } catch (_: Exception) {
            null
        }
    }

    private fun postNotification(data: Map<String, String>) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    getString(R.string.moment_notification_channel),
                    NotificationManager.IMPORTANCE_HIGH,
                ),
            )
        }

        val momentId = data["momentId"].orEmpty()
        val intent = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("moment://moment/$momentId"),
        ).apply {
            setClassName(packageName, "$packageName.MainActivity")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            momentId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(data["notificationTitle"] ?: data["senderName"])
            .setContentText(data["notificationBody"] ?: "sent you a moment")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_SOCIAL)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        NotificationManagerCompat.from(this)
            .notify(momentId.hashCode(), notification)
    }

    private inline fun <T> HttpURLConnection.use(block: (HttpURLConnection) -> T): T {
        return try {
            block(this)
        } finally {
            disconnect()
        }
    }

    companion object {
        const val PUSH_PREFS = "moment_push_prefs"
        const val KEY_PENDING_TOKEN = "pending_token"
        private const val CHANNEL_ID = "moments"
    }
}
