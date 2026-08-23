package app.moment.moment.widget

import android.content.Context

data class MomentWidgetData(
    val hasMoment: Boolean,
    val senderName: String,
    val senderId: String,
    val momentId: String,
    val imagePath: String?,
    val caption: String,
    val relativeTime: String,
    val createdAtMillis: Long,
    val widgetMode: String,
    val headerEmoji: String,
    val avatarPath: String?,
    val theme: String,
    val accentColor: String,
    val typography: String,
    val displaySize: String,
    val privacyMode: String,
    val showSender: Boolean,
    val showTimestamp: Boolean,
    val showCaptions: Boolean,
    val lockScreenPrivacy: Boolean,
    val paused: Boolean,
    val recentIndex: Int = 0,
    val recentCount: Int = 0,
)

object MomentWidgetDataStore {
    const val PREFS = "moment_widget_prefs"

    const val KEY_HAS_MOMENT = "has_moment"
    const val KEY_SENDER = "sender_name"
    const val KEY_SENDER_ID = "sender_id"
    const val KEY_MOMENT_ID = "moment_id"
    const val KEY_IMAGE_PATH = "image_path"
    const val KEY_CAPTION = "caption"
    const val KEY_RELATIVE_TIME = "relative_time"
    const val KEY_CREATED_AT = "created_at_millis"
    const val KEY_WIDGET_MODE = "widget_mode"
    const val KEY_HEADER_EMOJI = "header_emoji"
    const val KEY_AVATAR_PATH = "avatar_path"
    const val KEY_THEME = "theme"
    const val KEY_ACCENT = "accent_color"
    const val KEY_TYPOGRAPHY = "typography"
    const val KEY_DISPLAY_SIZE = "display_size"
    const val KEY_PRIVACY_MODE = "privacy_mode"
    const val KEY_SHOW_SENDER = "show_sender"
    const val KEY_SHOW_TIMESTAMP = "show_timestamp"
    const val KEY_SHOW_CAPTIONS = "show_captions"
    const val KEY_LOCK_SCREEN = "lock_screen_privacy"
    const val KEY_PAUSED = "paused"
    const val KEY_PRIVACY_PERSON = "privacy_person_id"
    const val KEY_HAS_CUSTOMIZATION = "has_customization"

    fun save(
        context: Context,
        senderName: String,
        momentId: String,
        imagePath: String?,
        caption: String?,
        relativeTime: String?,
        createdAtMillis: Long,
        widgetMode: String?,
        headerEmoji: String?,
        avatarPath: String?,
        senderId: String? = null,
    ) {
        val editor =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_HAS_MOMENT, true)
                .putString(KEY_SENDER, senderName)
                .putString(KEY_MOMENT_ID, momentId)
                .putString(KEY_IMAGE_PATH, imagePath)
                .putString(KEY_CAPTION, caption.orEmpty())
                .putString(KEY_RELATIVE_TIME, relativeTime.orEmpty())
                .putLong(KEY_CREATED_AT, createdAtMillis)
                .putString(KEY_WIDGET_MODE, widgetMode ?: "latest")
                .putString(KEY_HEADER_EMOJI, headerEmoji.orEmpty())
                .putString(KEY_AVATAR_PATH, avatarPath)
        if (!senderId.isNullOrBlank()) {
            editor.putString(KEY_SENDER_ID, senderId)
        }
        editor.commit()
    }

    fun savePreferences(
        context: Context,
        theme: String,
        accentColor: String,
        typography: String,
        widgetMode: String?,
        displaySize: String? = null,
        privacyMode: String?,
        showSender: Boolean?,
        showTimestamp: Boolean?,
        showCaptions: Boolean?,
        lockScreenPrivacy: Boolean?,
        paused: Boolean?,
        privacyPersonId: String? = null,
    ) {
        val editor =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_THEME, theme)
                .putString(KEY_ACCENT, accentColor)
                .putString(KEY_TYPOGRAPHY, typography)
        if (!widgetMode.isNullOrBlank()) {
            editor.putString(KEY_WIDGET_MODE, widgetMode)
        }
        if (!displaySize.isNullOrBlank()) {
            editor.putString(KEY_DISPLAY_SIZE, displaySize)
        }
        if (!privacyMode.isNullOrBlank()) {
            editor.putString(KEY_PRIVACY_MODE, privacyMode)
        }
        if (showSender != null) editor.putBoolean(KEY_SHOW_SENDER, showSender)
        if (showTimestamp != null) editor.putBoolean(KEY_SHOW_TIMESTAMP, showTimestamp)
        if (showCaptions != null) editor.putBoolean(KEY_SHOW_CAPTIONS, showCaptions)
        if (lockScreenPrivacy != null) {
            editor.putBoolean(KEY_LOCK_SCREEN, lockScreenPrivacy)
        }
        if (paused != null) editor.putBoolean(KEY_PAUSED, paused)
        when {
            privacyPersonId.isNullOrBlank() -> editor.remove(KEY_PRIVACY_PERSON)
            privacyPersonId != null -> editor.putString(KEY_PRIVACY_PERSON, privacyPersonId)
        }
        editor.putBoolean(KEY_HAS_CUSTOMIZATION, true)
        editor.commit()
    }

    fun clear(context: Context) {
        WidgetMomentQueue.clear(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val theme = prefs.getString(KEY_THEME, "minimal")
        val accent = prefs.getString(KEY_ACCENT, "#FF6B8A")
        val typography = prefs.getString(KEY_TYPOGRAPHY, "default")
        val displaySize = prefs.getString(KEY_DISPLAY_SIZE, "large")
        val widgetMode = prefs.getString(KEY_WIDGET_MODE, "latest")
        val privacyMode = prefs.getString(KEY_PRIVACY_MODE, "full")
        val showSender = prefs.getBoolean(KEY_SHOW_SENDER, true)
        val showTimestamp = prefs.getBoolean(KEY_SHOW_TIMESTAMP, true)
        val showCaptions = prefs.getBoolean(KEY_SHOW_CAPTIONS, false)
        val lockScreen = prefs.getBoolean(KEY_LOCK_SCREEN, true)
        val paused = prefs.getBoolean(KEY_PAUSED, false)
        prefs
            .edit()
            .putBoolean(KEY_HAS_MOMENT, false)
            .remove(KEY_SENDER)
            .remove(KEY_MOMENT_ID)
            .remove(KEY_IMAGE_PATH)
            .remove(KEY_CAPTION)
            .remove(KEY_RELATIVE_TIME)
            .remove(KEY_CREATED_AT)
            .remove(KEY_HEADER_EMOJI)
            .remove(KEY_AVATAR_PATH)
            .putString(KEY_THEME, theme)
            .putString(KEY_ACCENT, accent)
            .putString(KEY_TYPOGRAPHY, typography)
            .putString(KEY_DISPLAY_SIZE, displaySize)
            .putString(KEY_WIDGET_MODE, widgetMode)
            .putString(KEY_PRIVACY_MODE, privacyMode)
            .putBoolean(KEY_SHOW_SENDER, showSender)
            .putBoolean(KEY_SHOW_TIMESTAMP, showTimestamp)
            .putBoolean(KEY_SHOW_CAPTIONS, showCaptions)
            .putBoolean(KEY_LOCK_SCREEN, lockScreen)
            .putBoolean(KEY_PAUSED, paused)
            .commit()
    }

    fun load(context: Context): MomentWidgetData {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val (recentIndex, recentCount) = WidgetMomentQueue.queueMeta(context)
        val queue = WidgetMomentQueue.loadQueue(context)
        val active = queue.getOrNull(recentIndex)
        val senderId = active?.senderId ?: (prefs.getString(KEY_SENDER_ID, "") ?: "")
        val effectivePrivacy = WidgetPrivacyResolver.resolve(context, senderId)

        return MomentWidgetData(
            hasMoment = prefs.getBoolean(KEY_HAS_MOMENT, false) || active != null,
            senderName = active?.senderName ?: (prefs.getString(KEY_SENDER, "") ?: ""),
            senderId = senderId,
            momentId = active?.momentId ?: (prefs.getString(KEY_MOMENT_ID, "") ?: ""),
            imagePath = active?.imagePath ?: prefs.getString(KEY_IMAGE_PATH, null),
            caption = active?.caption ?: (prefs.getString(KEY_CAPTION, "") ?: ""),
            relativeTime = active?.relativeTime ?: (prefs.getString(KEY_RELATIVE_TIME, "") ?: ""),
            createdAtMillis = active?.createdAtMillis ?: prefs.getLong(KEY_CREATED_AT, 0L),
            widgetMode = prefs.getString(KEY_WIDGET_MODE, "latest") ?: "latest",
            headerEmoji = prefs.getString(KEY_HEADER_EMOJI, "") ?: "",
            avatarPath = active?.avatarPath ?: prefs.getString(KEY_AVATAR_PATH, null),
            theme = prefs.getString(KEY_THEME, "minimal") ?: "minimal",
            accentColor = prefs.getString(KEY_ACCENT, "#FF6B8A") ?: "#FF6B8A",
            typography = prefs.getString(KEY_TYPOGRAPHY, "default") ?: "default",
            displaySize = prefs.getString(KEY_DISPLAY_SIZE, "large") ?: "large",
            privacyMode = effectivePrivacy,
            showSender = prefs.getBoolean(KEY_SHOW_SENDER, true),
            showTimestamp = prefs.getBoolean(KEY_SHOW_TIMESTAMP, true),
            showCaptions = prefs.getBoolean(KEY_SHOW_CAPTIONS, false),
            lockScreenPrivacy = prefs.getBoolean(KEY_LOCK_SCREEN, true),
            paused = prefs.getBoolean(KEY_PAUSED, false),
            recentIndex = recentIndex,
            recentCount = recentCount,
        )
    }
}
