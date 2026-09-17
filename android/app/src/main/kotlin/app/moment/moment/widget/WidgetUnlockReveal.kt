package app.moment.moment.widget

import android.content.Context

/** One-shot clear frame on widget after unlock (Full mode only). */
object WidgetUnlockReveal {
    const val RECENT_MOMENT_WINDOW_MS = 2 * 60 * 1000L
    const val CLEAR_FRAME_REVERT_MS = 1_500L

    private const val KEY_ARMED_MOMENT = "unlock_reveal_armed_moment"
    private const val KEY_CONSUMED = "unlock_reveal_consumed"

    fun arm(context: Context, momentId: String) {
        if (momentId.isBlank()) return
        context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_ARMED_MOMENT, momentId)
            .putBoolean(KEY_CONSUMED, false)
            .commit()
    }

    fun consumeClearFrame(context: Context, momentId: String): Boolean {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        val armed = prefs.getString(KEY_ARMED_MOMENT, null) ?: return false
        if (armed != momentId) return false
        if (prefs.getBoolean(KEY_CONSUMED, false)) return false
        prefs.edit().putBoolean(KEY_CONSUMED, true).commit()
        return true
    }

    fun clear(context: Context) {
        context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_ARMED_MOMENT)
            .remove(KEY_CONSUMED)
            .commit()
    }
}
