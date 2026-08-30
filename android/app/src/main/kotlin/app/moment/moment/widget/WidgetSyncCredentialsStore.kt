package app.moment.moment.widget

import android.content.Context

/**
 * Supabase session cached for native background widget sync when the app is killed.
 * Written by Flutter after login; never contains the service-role key.
 */
data class WidgetSyncCredentials(
    val supabaseUrl: String,
    val anonKey: String,
    val userId: String,
    val accessToken: String,
    val refreshToken: String?,
)

object WidgetSyncCredentialsStore {
    private const val PREFS = "widget_sync_credentials"
    private const val KEY_URL = "supabase_url"
    private const val KEY_ANON = "anon_key"
    private const val KEY_USER = "user_id"
    private const val KEY_ACCESS = "access_token"
    private const val KEY_REFRESH = "refresh_token"

    fun save(
        context: Context,
        supabaseUrl: String,
        anonKey: String,
        userId: String,
        accessToken: String,
        refreshToken: String?,
    ) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_URL, supabaseUrl.trimEnd('/'))
            .putString(KEY_ANON, anonKey)
            .putString(KEY_USER, userId)
            .putString(KEY_ACCESS, accessToken)
            .putString(KEY_REFRESH, refreshToken.orEmpty())
            .commit()
        WidgetSyncScheduler.schedulePeriodic(context.applicationContext)
    }

    fun clear(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().commit()
        WidgetSyncScheduler.cancel(context.applicationContext)
    }

    fun load(context: Context): WidgetSyncCredentials? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val url = prefs.getString(KEY_URL, null).orEmpty()
        val anon = prefs.getString(KEY_ANON, null).orEmpty()
        val userId = prefs.getString(KEY_USER, null).orEmpty()
        val access = prefs.getString(KEY_ACCESS, null).orEmpty()
        if (url.isBlank() || anon.isBlank() || userId.isBlank() || access.isBlank()) {
            return null
        }
        val refresh = prefs.getString(KEY_REFRESH, null)?.takeIf { it.isNotBlank() }
        return WidgetSyncCredentials(url, anon, userId, access, refresh)
    }

    fun updateAccessToken(context: Context, accessToken: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_ACCESS, accessToken)
            .commit()
    }
}
