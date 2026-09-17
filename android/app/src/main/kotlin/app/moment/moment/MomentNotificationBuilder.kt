package app.moment.moment

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

/**
 * Shared styling for Moment vs Chat push notifications — distinct icons, colors, and branding.
 */
object MomentNotificationBuilder {
    enum class Kind {
        MOMENT,
        REACTION,
        CHAT,
        FRIEND,
    }

    private const val COLOR_MOMENT = 0xFFFF6B8A.toInt()
    private const val COLOR_CHAT = 0xFF6B8AFF.toInt()
    private const val COLOR_FRIEND = 0xFFB86BFF.toInt()

    fun create(
        context: Context,
        channelId: String,
        kind: Kind,
        largeIcon: Bitmap? = null,
    ): NotificationCompat.Builder {
        val smallIcon =
            when (kind) {
                Kind.CHAT -> R.drawable.ic_notification_chat
                else -> R.drawable.ic_notification
            }
        val color =
            when (kind) {
                Kind.CHAT -> COLOR_CHAT
                Kind.FRIEND -> COLOR_FRIEND
                Kind.MOMENT, Kind.REACTION -> COLOR_MOMENT
            }
        val subText =
            when (kind) {
                Kind.CHAT -> "Chat"
                Kind.MOMENT -> "Moment"
                Kind.REACTION -> "Reaction"
                Kind.FRIEND -> "Friend request"
            }

        val resolvedLarge =
            when {
                largeIcon != null -> largeIcon
                kind == Kind.CHAT -> null
                else -> loadBrandLogo(context)
            }

        return NotificationCompat.Builder(context, channelId)
            .setSmallIcon(smallIcon)
            .setColor(color)
            .setColorized(false)
            .setSubText(subText)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .apply {
                resolvedLarge?.let { setLargeIcon(it) }
            }
    }

    fun ensureChannel(
        context: Context,
        channelId: String,
        name: String,
        description: String,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannel(
            NotificationChannel(channelId, name, NotificationManager.IMPORTANCE_HIGH).apply {
                this.description = description
                enableLights(true)
                lightColor = ContextCompat.getColor(context, R.color.notification_accent)
            },
        )
    }

    fun loadBrandLogo(context: Context): Bitmap? =
        runCatching {
            BitmapFactory.decodeResource(context.resources, R.drawable.ic_notification_logo)
        }.getOrNull()

    fun bigPictureStyle(
        picture: Bitmap,
        summary: String,
        hideLargeIconWhenExpanded: Boolean = true,
    ): NotificationCompat.BigPictureStyle {
        val style =
            NotificationCompat.BigPictureStyle()
                .bigPicture(picture)
                .setSummaryText(summary)
        if (hideLargeIconWhenExpanded) {
            style.bigLargeIcon(null as Bitmap?)
        }
        return style
    }
}
