package app.moment.moment.widget

import android.content.Context
import org.json.JSONArray

/**
 * Moments the user has opened on-device. Stays unread=false on the widget even if
 * a background Supabase sync has not yet observed [seen_at] on the server.
 */
object WidgetSeenOnDeviceStore {
    private const val KEY_SEEN_IDS = "widget_seen_moment_ids_v1"
    private const val MAX_IDS = 64

    fun markSeen(context: Context, momentId: String) {
        if (momentId.isBlank()) return
        val prefs =
            context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        val ids = loadIds(prefs).toMutableSet()
        ids.add(momentId)
        val trimmed = ids.toList().takeLast(MAX_IDS)
        val array = JSONArray()
        trimmed.forEach { array.put(it) }
        prefs.edit().putString(KEY_SEEN_IDS, array.toString()).commit()
    }

    fun isSeen(context: Context, momentId: String): Boolean {
        if (momentId.isBlank()) return false
        val prefs =
            context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        return loadIds(prefs).contains(momentId)
    }

    fun applySeenState(context: Context, entry: WidgetMomentEntry): WidgetMomentEntry {
        if (!entry.isUnread) return entry
        return if (isSeen(context, entry.momentId)) {
            entry.copy(isUnread = false)
        } else {
            entry
        }
    }

    private fun loadIds(prefs: android.content.SharedPreferences): Set<String> {
        val raw = prefs.getString(KEY_SEEN_IDS, null) ?: return emptySet()
        return runCatching {
            val array = JSONArray(raw)
            buildSet {
                for (i in 0 until array.length()) {
                    val id = array.optString(i)
                    if (id.isNotBlank()) add(id)
                }
            }
        }.getOrDefault(emptySet())
    }
}
