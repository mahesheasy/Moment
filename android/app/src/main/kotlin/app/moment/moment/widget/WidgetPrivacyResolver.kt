package app.moment.moment.widget

import android.content.Context

object WidgetPrivacyResolver {
    fun resolve(
        context: Context,
        senderId: String?,
    ): String {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        val globalMode = prefs.getString(MomentWidgetDataStore.KEY_PRIVACY_MODE, "full") ?: "full"
        val privacyPersonId =
            prefs.getString(MomentWidgetDataStore.KEY_PRIVACY_PERSON, null)?.takeIf {
                it.isNotBlank()
            }
        if (privacyPersonId == null) return globalMode
        if (senderId.isNullOrBlank()) return globalMode
        return if (privacyPersonId == senderId) globalMode else "full"
    }
}
