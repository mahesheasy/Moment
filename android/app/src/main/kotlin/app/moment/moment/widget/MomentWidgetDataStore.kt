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
    val showStreak: Boolean = true,
    val streakCount: Int = 0,
    val renderSeq: Long = 0L,
    val isUnread: Boolean = false,
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
    const val KEY_SHOW_STREAK = "show_streak"
    const val KEY_STREAK_COUNT = "streak_count"
    const val KEY_RENDER_SEQ = "widget_render_seq"
    const val KEY_IS_UNREAD = "widget_moment_is_unread"

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
        privacyOverridesJson: String? = null,
        showStreak: Boolean? = null,
        streakCount: Int? = null,
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
        if (showStreak != null) editor.putBoolean(KEY_SHOW_STREAK, showStreak)
        if (streakCount != null) editor.putInt(KEY_STREAK_COUNT, streakCount)
        when {
            privacyPersonId.isNullOrBlank() -> editor.remove(KEY_PRIVACY_PERSON)
            privacyPersonId != null -> editor.putString(KEY_PRIVACY_PERSON, privacyPersonId)
        }
        if (privacyOverridesJson != null) {
            editor.putString(
                WidgetPrivacyOverridesStore.KEY_PRIVACY_OVERRIDES,
                privacyOverridesJson,
            )
        }
        editor.putBoolean(KEY_HAS_CUSTOMIZATION, true)
        editor.commit()
    }

    fun clear(context: Context) {
        clearActiveMoment(context)
    }

    /** Clears the visible moment but keeps widget customization prefs. */
    fun clearActiveMoment(context: Context) {
        WidgetMomentQueue.clear(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val nextRenderSeq = prefs.getLong(KEY_RENDER_SEQ, 0L) + 1L
        prefs
            .edit()
            .putBoolean(KEY_HAS_MOMENT, false)
            .remove(KEY_SENDER)
            .remove(KEY_SENDER_ID)
            .remove(KEY_MOMENT_ID)
            .remove(KEY_IMAGE_PATH)
            .remove(KEY_CAPTION)
            .remove(KEY_RELATIVE_TIME)
            .remove(KEY_CREATED_AT)
            .remove(KEY_HEADER_EMOJI)
            .remove(KEY_AVATAR_PATH)
            .putBoolean(KEY_IS_UNREAD, false)
            .putLong(KEY_RENDER_SEQ, nextRenderSeq)
            .commit()
    }

    fun load(context: Context): MomentWidgetData {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val (recentIndex, recentCount) = WidgetMomentQueue.queueMeta(context)
        val queue = WidgetMomentQueue.loadQueue(context)
        val active = queue.getOrNull(recentIndex)
        val senderId =
            active?.senderId
                ?: (prefs.getString(KEY_SENDER_ID, "") ?: "")
        val effectivePrivacy = WidgetPrivacyResolver.resolvePrivacyForSender(context, senderId)

        return MomentWidgetData(
            hasMoment = prefs.getBoolean(KEY_HAS_MOMENT, false) || active != null,
            senderName =
                active?.senderName
                    ?: (prefs.getString(KEY_SENDER, "") ?: ""),
            senderId = senderId,
            momentId =
                active?.momentId
                    ?: (prefs.getString(KEY_MOMENT_ID, "") ?: ""),
            imagePath =
                if (active != null) active.imagePath else prefs.getString(KEY_IMAGE_PATH, null),
            caption =
                active?.caption
                    ?: (prefs.getString(KEY_CAPTION, "") ?: ""),
            relativeTime =
                active?.relativeTime
                    ?: (prefs.getString(KEY_RELATIVE_TIME, "") ?: ""),
            createdAtMillis =
                active?.createdAtMillis
                    ?: prefs.getLong(KEY_CREATED_AT, 0L),
            widgetMode = prefs.getString(KEY_WIDGET_MODE, "latest") ?: "latest",
            headerEmoji = prefs.getString(KEY_HEADER_EMOJI, "") ?: "",
            avatarPath =
                if (active != null) active.avatarPath else prefs.getString(KEY_AVATAR_PATH, null),
            theme = prefs.getString(KEY_THEME, "minimal") ?: "minimal",
            accentColor = prefs.getString(KEY_ACCENT, "#FF6B8A") ?: "#FF6B8A",
            typography = prefs.getString(KEY_TYPOGRAPHY, "default") ?: "default",
            displaySize = prefs.getString(KEY_DISPLAY_SIZE, "small") ?: "small",
            privacyMode = effectivePrivacy,
            showSender = prefs.getBoolean(KEY_SHOW_SENDER, true),
            showTimestamp = prefs.getBoolean(KEY_SHOW_TIMESTAMP, true),
            showCaptions = prefs.getBoolean(KEY_SHOW_CAPTIONS, false),
            lockScreenPrivacy = prefs.getBoolean(KEY_LOCK_SCREEN, true),
            paused = prefs.getBoolean(KEY_PAUSED, false),
            recentIndex = recentIndex,
            recentCount = recentCount,
            showStreak = prefs.getBoolean(KEY_SHOW_STREAK, true),
            streakCount = prefs.getInt(KEY_STREAK_COUNT, 0),
            renderSeq = prefs.getLong(KEY_RENDER_SEQ, 0L),
            isUnread = active?.isUnread ?: prefs.getBoolean(KEY_IS_UNREAD, false),
        )
    }
}
