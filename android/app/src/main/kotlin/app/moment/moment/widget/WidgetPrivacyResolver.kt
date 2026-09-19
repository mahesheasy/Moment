package app.moment.moment.widget

import android.content.Context

object WidgetPrivacyResolver {
    /**
     * Resolves privacy for a moment sender.
     *
     * Priority: per-sender override → legacy [MomentWidgetDataStore.KEY_PRIVACY_PERSON]
     * → global privacy mode.
     */
    fun resolvePrivacyForSender(
        context: Context,
        senderId: String?,
    ): String = resolve(context, senderId)

    /** @see resolvePrivacyForSender */
    fun resolve(
        context: Context,
        senderId: String?,
    ): String {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        val global = prefs.getString(MomentWidgetDataStore.KEY_PRIVACY_MODE, "full") ?: "full"

        if (!senderId.isNullOrBlank()) {
            WidgetPrivacyOverridesStore.load(context)[senderId]?.let { return it }
            val legacyPerson =
                prefs.getString(MomentWidgetDataStore.KEY_PRIVACY_PERSON, null)?.takeIf {
                    it.isNotBlank()
                }
            if (legacyPerson != null) {
                return if (legacyPerson == senderId) global else "full"
            }
        }
        return global
    }
}
