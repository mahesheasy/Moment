package app.moment.moment

import android.content.Context

/**
 * Local notification preference flags synced from Flutter.
 *
 * Read by [MomentFirebaseMessagingService] when the app is killed so push
 * alerts respect the user's settings.
 */
object NotificationPreferencesStore {
    const val PREFS = "moment_notification_prefs"

    private const val KEY_PUSH = "push_enabled"
    private const val KEY_MOMENTS = "moments"
    private const val KEY_FRIEND_REQUESTS = "friend_requests"
    private const val KEY_MENTIONS = "mentions"
    private const val KEY_MEMORIES = "memories"
    private const val KEY_SECURITY = "security"
    private const val KEY_EMAIL_DIGEST = "email_digest"

    fun save(context: Context, values: Map<String, Boolean>) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_PUSH, values[KEY_PUSH] ?: true)
            .putBoolean(KEY_MOMENTS, values[KEY_MOMENTS] ?: true)
            .putBoolean(KEY_FRIEND_REQUESTS, values[KEY_FRIEND_REQUESTS] ?: true)
            .putBoolean(KEY_MENTIONS, values[KEY_MENTIONS] ?: true)
            .putBoolean(KEY_MEMORIES, values[KEY_MEMORIES] ?: true)
            .putBoolean(KEY_SECURITY, values[KEY_SECURITY] ?: true)
            .putBoolean(KEY_EMAIL_DIGEST, values[KEY_EMAIL_DIGEST] ?: false)
            .commit()
    }

    fun shouldShowNotification(context: Context, type: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_PUSH, true)) return false

        return when (type) {
            "moment" -> prefs.getBoolean(KEY_MOMENTS, true)
            "reaction" -> prefs.getBoolean(KEY_MOMENTS, true)
            "friend_request" -> prefs.getBoolean(KEY_FRIEND_REQUESTS, true)
            "chat" -> prefs.getBoolean(KEY_MOMENTS, true)
            "mention" -> prefs.getBoolean(KEY_MENTIONS, true)
            "memory" -> prefs.getBoolean(KEY_MEMORIES, true)
            "security" -> prefs.getBoolean(KEY_SECURITY, true)
            else -> true
        }
    }
}
