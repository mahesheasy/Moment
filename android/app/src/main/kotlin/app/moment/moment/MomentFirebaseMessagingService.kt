package app.moment.moment



import android.app.NotificationChannel

import android.app.NotificationManager

import android.app.PendingIntent

import android.content.Context

import android.content.Intent

import android.content.pm.PackageManager

import android.graphics.Bitmap

import android.graphics.BitmapFactory

import android.graphics.Canvas

import android.graphics.Paint

import android.graphics.PorterDuff

import android.graphics.PorterDuffXfermode

import android.graphics.Rect

import android.graphics.drawable.BitmapDrawable

import android.graphics.drawable.Drawable

import android.net.Uri

import android.os.Build

import androidx.core.app.NotificationCompat

import androidx.core.app.Person

import androidx.core.app.NotificationManagerCompat

import androidx.core.graphics.drawable.IconCompat

import app.moment.moment.widget.MomentWidgetDataStore

import app.moment.moment.widget.MomentWidgetUpdater

import app.moment.moment.widget.WidgetFcmParser

import app.moment.moment.widget.WidgetMediaDownloader

import app.moment.moment.widget.WidgetMomentSyncLog

import app.moment.moment.widget.WidgetMomentQueue

import app.moment.moment.widget.WidgetSyncScheduler

import com.google.firebase.messaging.FirebaseMessagingService

import com.google.firebase.messaging.RemoteMessage

import android.os.PowerManager

import java.net.HttpURLConnection

import java.net.URL

import kotlinx.coroutines.runBlocking



/**

 * Applies incoming moments to the home-screen widget without starting Flutter.

 *

 * FCM calls [onMessageReceived] on a background thread and only guarantees the

 * process stays alive until it returns. Widget metadata is written synchronously;

 * image downloads run asynchronously after the first widget refresh.

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

        val type = data.fcmType()

        when (type) {

            "moment", "new_moment" -> {
                handleMomentMessage(data)
                return
            }

            "chat" -> handleChatMessage(data)

            "chat_reaction" -> handleChatReactionMessage(data)

            "friend_request" -> handleFriendRequestMessage(data)

            "reaction" -> handleReactionMessage(data)

        }

    }



    private fun handleMomentMessage(data: Map<String, String>) {
        val wakeLock =
            (getSystemService(POWER_SERVICE) as PowerManager)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "moment:widget_fcm")
                .apply { setReferenceCounted(false) }
        wakeLock.acquire(30_000L)
        try {
            runCatching { applyToWidget(data) }
            if (NotificationPreferencesStore.shouldShowNotification(applicationContext, "moment")) {
                runCatching { postMomentNotification(data) }
            }
            WidgetSyncScheduler.enqueueBackup(applicationContext)
        } finally {
            if (wakeLock.isHeld) wakeLock.release()
        }
    }



    private fun handleChatMessage(data: Map<String, String>) {

        if (!NotificationPreferencesStore.shouldShowNotification(applicationContext, "chat")) {

            return

        }

        runCatching { postChatNotification(data) }

    }



    private fun handleChatReactionMessage(data: Map<String, String>) {

        if (!NotificationPreferencesStore.shouldShowNotification(applicationContext, "chat")) {

            return

        }

        runCatching { postChatReactionNotification(data) }

    }



    private fun handleFriendRequestMessage(data: Map<String, String>) {

        if (!NotificationPreferencesStore.shouldShowNotification(applicationContext, "friend_request")) {

            return

        }

        runCatching { postFriendRequestNotification(data) }

    }



    private fun handleReactionMessage(data: Map<String, String>) {

        if (!NotificationPreferencesStore.shouldShowNotification(applicationContext, "reaction")) {

            return

        }

        runCatching { postReactionNotification(data) }

    }



    private fun postChatNotification(data: Map<String, String>) {

        if (!canPostNotifications()) return

        ensureChannel(CHAT_CHANNEL_ID, getString(R.string.chat_notification_channel))



        val senderId = data["senderId"].orEmpty()

        val senderName = data["notificationTitle"] ?: data["senderName"] ?: "Message"

        val body = data["notificationBody"] ?: "sent you a chat"

        val avatarBitmap = loadCircularAvatarBitmap(data["avatarUrl"])

        val timestamp = data["createdAtMillis"]?.toLongOrNull()

            ?: System.currentTimeMillis()



        val intent = Intent(

            Intent.ACTION_VIEW,

            Uri.parse("moment://chat/$senderId"),

        ).apply {

            setClassName(packageName, "$packageName.MainActivity")

            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)

        }



        val pendingIntent = PendingIntent.getActivity(

            this,

            senderId.hashCode(),

            intent,

            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,

        )



        val senderPersonBuilder = Person.Builder().setName(senderName)

        avatarBitmap?.let { bitmap ->

            senderPersonBuilder.setIcon(IconCompat.createWithBitmap(bitmap))

        }

        val senderPerson = senderPersonBuilder.build()



        val me = Person.Builder().setName("You").build()

        val style = NotificationCompat.MessagingStyle(me)

            .setConversationTitle(senderName)

            .addMessage(body, timestamp, senderPerson)



        val notification = baseNotificationBuilder(CHAT_CHANNEL_ID, avatarBitmap)

            .setContentTitle(senderName)

            .setContentText(body)

            .setStyle(style)

            .setCategory(NotificationCompat.CATEGORY_MESSAGE)

            .setContentIntent(pendingIntent)

            .build()



        NotificationManagerCompat.from(this)

            .notify("chat_$senderId".hashCode(), notification)

    }



    private fun postChatReactionNotification(data: Map<String, String>) {

        if (!canPostNotifications()) return

        ensureChannel(CHAT_CHANNEL_ID, getString(R.string.chat_notification_channel))



        val senderId = data["senderId"].orEmpty()

        val senderName = data["notificationTitle"] ?: data["senderName"] ?: "Message"

        val emoji = data["reactionEmoji"] ?: "❤️"

        val body = data["notificationBody"] ?: "reacted $emoji to your message"

        val avatarBitmap = loadCircularAvatarBitmap(data["avatarUrl"])

        val timestamp = data["createdAtMillis"]?.toLongOrNull()

            ?: System.currentTimeMillis()



        val intent = Intent(

            Intent.ACTION_VIEW,

            Uri.parse("moment://chat/$senderId"),

        ).apply {

            setClassName(packageName, "$packageName.MainActivity")

            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)

        }



        val pendingIntent = PendingIntent.getActivity(

            this,

            "chat_reaction_$senderId".hashCode(),

            intent,

            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,

        )



        val senderPersonBuilder = Person.Builder().setName(senderName)

        avatarBitmap?.let { bitmap ->

            senderPersonBuilder.setIcon(IconCompat.createWithBitmap(bitmap))

        }

        val senderPerson = senderPersonBuilder.build()



        val me = Person.Builder().setName("You").build()

        val style = NotificationCompat.MessagingStyle(me)

            .setConversationTitle(senderName)

            .addMessage(body, timestamp, senderPerson)



        val notification = baseNotificationBuilder(CHAT_CHANNEL_ID, avatarBitmap)

            .setContentTitle(senderName)

            .setContentText(body)

            .setStyle(style)

            .setCategory(NotificationCompat.CATEGORY_MESSAGE)

            .setContentIntent(pendingIntent)

            .build()



        NotificationManagerCompat.from(this)

            .notify("chat_reaction_$senderId".hashCode(), notification)

    }



    private fun postFriendRequestNotification(data: Map<String, String>) {

        if (!canPostNotifications()) return

        ensureChannel(FRIEND_CHANNEL_ID, getString(R.string.friend_request_notification_channel))



        val senderId = data["senderId"].orEmpty()

        val requestId = data["requestId"].orEmpty()

        val senderName = data["notificationTitle"] ?: data["senderName"] ?: "Someone"

        val body = data["notificationBody"] ?: "sent you a friend request"

        val avatarBitmap = loadCircularAvatarBitmap(data["avatarUrl"])



        val intent = Intent(

            Intent.ACTION_VIEW,

            Uri.parse("moment://friends"),

        ).apply {

            setClassName(packageName, "$packageName.MainActivity")

            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)

        }



        val pendingIntent = PendingIntent.getActivity(

            this,

            "friend_request_$requestId".hashCode(),

            intent,

            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,

        )



        val notification = baseNotificationBuilder(FRIEND_CHANNEL_ID, avatarBitmap)

            .setContentTitle(senderName)

            .setContentText(body)

            .setCategory(NotificationCompat.CATEGORY_SOCIAL)

            .setContentIntent(pendingIntent)

            .build()



        NotificationManagerCompat.from(this)

            .notify("friend_request_$requestId".hashCode(), notification)

    }



    private fun postReactionNotification(data: Map<String, String>) {

        if (!canPostNotifications()) return

        ensureChannel(CHANNEL_ID, getString(R.string.moment_notification_channel))



        val momentId = data["momentId"].orEmpty()

        val reactorId = data["reactorId"].orEmpty()

        val intent = Intent(

            Intent.ACTION_VIEW,

            Uri.parse("moment://moment/$momentId"),

        ).apply {

            setClassName(packageName, "$packageName.MainActivity")

            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)

        }



        val pendingIntent = PendingIntent.getActivity(

            this,

            "reaction_${momentId}_$reactorId".hashCode(),

            intent,

            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,

        )



        val notification = baseNotificationBuilder(CHANNEL_ID)

            .setContentTitle(data["notificationTitle"] ?: data["reactorName"])

            .setContentText(

                data["notificationBody"]

                    ?: "reacted ${data["reactionEmoji"] ?: "❤️"} to your moment",

            )

            .setCategory(NotificationCompat.CATEGORY_SOCIAL)

            .setContentIntent(pendingIntent)

            .build()



        NotificationManagerCompat.from(this)

            .notify("reaction_${momentId}_$reactorId".hashCode(), notification)

    }



    private fun applyToWidget(data: Map<String, String>) {
        val entry = WidgetFcmParser.parseEntry(data) ?: run {
            WidgetMomentSyncLog.error("FCM parse failed: type=${data.fcmType()}")
            return
        }
        WidgetMomentSyncLog.fcmReceived(entry.momentId)

        WidgetMomentQueue.upsertMoment(
            applicationContext,
            entry,
            promoteNew = true,
        )

        runBlocking {
            MomentWidgetUpdater.updateIncomingMoment(applicationContext, entry.momentId)
        }

        WidgetMediaDownloader.enqueue(
            applicationContext,
            entry.momentId,
            entry.imageUrl,
            entry.avatarUrl,
        )
    }

    private fun Map<String, String>.fcmType(): String {
        if (containsKey("type")) return get("type").orEmpty().lowercase()
        return entries.firstOrNull { it.key.equals("type", ignoreCase = true) }
            ?.value
            ?.lowercase()
            .orEmpty()
    }

    private fun Map<String, String>.fcm(key: String): String {
        if (containsKey(key)) return get(key).orEmpty()
        val lower = key.lowercase()
        if (containsKey(lower)) return get(lower).orEmpty()
        return entries.firstOrNull { it.key.equals(key, ignoreCase = true) }?.value.orEmpty()
    }



    private fun postMomentNotification(data: Map<String, String>) {

        if (!canPostNotifications()) return

        ensureChannel(CHANNEL_ID, getString(R.string.moment_notification_channel))



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



        val notification = baseNotificationBuilder(CHANNEL_ID)

            .setContentTitle(data["notificationTitle"] ?: data["senderName"])

            .setContentText(data["notificationBody"] ?: "sent you a moment")

            .setCategory(NotificationCompat.CATEGORY_SOCIAL)

            .setContentIntent(pendingIntent)

            .build()



        NotificationManagerCompat.from(this)

            .notify(momentId.hashCode(), notification)

    }



    private fun baseNotificationBuilder(

        channelId: String,

        avatarBitmap: Bitmap? = null,

    ): NotificationCompat.Builder {

        val builder = NotificationCompat.Builder(this, channelId)

            .setSmallIcon(R.drawable.ic_notification)

            .setPriority(NotificationCompat.PRIORITY_HIGH)

            .setAutoCancel(true)



        val largeIcon = avatarBitmap ?: loadLargeAppIcon()

        largeIcon?.let { builder.setLargeIcon(it) }

        return builder

    }



    private fun loadCircularAvatarBitmap(url: String?): Bitmap? {

        if (url.isNullOrBlank()) return null

        return runCatching {

            val bytes = downloadBytes(url) ?: return null

            val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null

            circleCropBitmap(decoded)

        }.getOrNull()

    }



    private fun downloadBytes(url: String): ByteArray? {

        return try {

            val connection = (URL(url).openConnection() as HttpURLConnection).apply {

                connectTimeout = 10_000

                readTimeout = 15_000

                requestMethod = "GET"

            }

            connection.use { conn ->

                val bytes = conn.inputStream.readBytes()

                bytes.takeIf { it.isNotEmpty() }

            }

        } catch (_: Exception) {

            null

        }

    }



    private fun circleCropBitmap(source: Bitmap): Bitmap {

        val size = minOf(source.width, source.height)

        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)

        val canvas = Canvas(output)

        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        val rect = Rect(0, 0, size, size)

        canvas.drawARGB(0, 0, 0, 0)

        canvas.drawCircle(size / 2f, size / 2f, size / 2f, paint)

        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)

        canvas.drawBitmap(source, null, rect, paint)

        if (source != output) {

            source.recycle()

        }

        return output

    }



    private fun loadLargeAppIcon(): Bitmap? {

        return runCatching {

            drawableToBitmap(packageManager.getApplicationIcon(applicationInfo))

        }.getOrNull()

    }



    private fun drawableToBitmap(drawable: Drawable): Bitmap {

        if (drawable is BitmapDrawable && drawable.bitmap != null) {

            return drawable.bitmap

        }

        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 128

        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 128

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

        val canvas = Canvas(bitmap)

        drawable.setBounds(0, 0, canvas.width, canvas.height)

        drawable.draw(canvas)

        return bitmap

    }



    private fun canPostNotifications(): Boolean {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&

            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) !=

            PackageManager.PERMISSION_GRANTED

        ) {

            return false

        }

        return true

    }



    private fun ensureChannel(channelId: String, name: String) {

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        manager.createNotificationChannel(

            NotificationChannel(

                channelId,

                name,

                NotificationManager.IMPORTANCE_HIGH,

            ),

        )

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

        private const val CHAT_CHANNEL_ID = "chats"

        private const val FRIEND_CHANNEL_ID = "friend_requests"

    }

}


