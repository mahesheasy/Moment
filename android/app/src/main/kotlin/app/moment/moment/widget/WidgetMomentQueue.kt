package app.moment.moment.widget

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class WidgetMomentEntry(
    val momentId: String,
    val senderName: String,
    val senderId: String,
    val imagePath: String?,
    val avatarPath: String?,
    val caption: String,
    val createdAtMillis: Long,
    val relativeTime: String,
)

object WidgetMomentQueue {
    private const val KEY_QUEUE = "recent_moments_json"
    private const val KEY_QUEUE_INDEX = "recent_moment_index"
    private const val MAX_ENTRIES = 5

    fun saveQueue(
        context: Context,
        entries: List<WidgetMomentEntry>,
        selectIndex: Int = 0,
    ) {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        val trimmed = entries.take(MAX_ENTRIES)
        val array = JSONArray()
        trimmed.forEach { entry ->
            array.put(
                JSONObject()
                    .put("momentId", entry.momentId)
                    .put("senderName", entry.senderName)
                    .put("senderId", entry.senderId)
                    .put("imagePath", entry.imagePath.orEmpty())
                    .put("avatarPath", entry.avatarPath.orEmpty())
                    .put("caption", entry.caption)
                    .put("createdAtMillis", entry.createdAtMillis)
                    .put("relativeTime", entry.relativeTime),
            )
        }
        val index = if (trimmed.isEmpty()) 0 else selectIndex.coerceIn(0, trimmed.lastIndex)
        prefs
            .edit()
            .putString(KEY_QUEUE, array.toString())
            .putInt(KEY_QUEUE_INDEX, index)
            .commit()
        applyEntryToLegacyFields(context, trimmed.getOrNull(index))
    }

    fun prependMoment(
        context: Context,
        entry: WidgetMomentEntry,
    ) {
        val existing = loadQueue(context).filter { it.momentId != entry.momentId }
        saveQueue(context, listOf(entry) + existing, selectIndex = 0)
    }

    fun cycle(context: Context, delta: Int) {
        val queue = loadQueue(context)
        if (queue.size <= 1) return
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        val current = prefs.getInt(KEY_QUEUE_INDEX, 0)
        val next = (current + delta).floorMod(queue.size)
        prefs.edit().putInt(KEY_QUEUE_INDEX, next).commit()
        applyEntryToLegacyFields(context, queue[next])
    }

    fun loadQueue(context: Context): List<WidgetMomentEntry> {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_QUEUE, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    add(
                        WidgetMomentEntry(
                            momentId = obj.optString("momentId", ""),
                            senderName = obj.optString("senderName", ""),
                            senderId = obj.optString("senderId", ""),
                            imagePath = obj.optString("imagePath").ifBlank { null },
                            avatarPath = obj.optString("avatarPath").ifBlank { null },
                            caption = obj.optString("caption", ""),
                            createdAtMillis = obj.optLong("createdAtMillis", 0L),
                            relativeTime = obj.optString("relativeTime", ""),
                        ),
                    )
                }
            }
        }.getOrDefault(emptyList())
    }

    fun clear(context: Context) {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        prefs
            .edit()
            .remove(KEY_QUEUE)
            .remove(KEY_QUEUE_INDEX)
            .commit()
    }

    fun queueMeta(context: Context): Pair<Int, Int> {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        val queue = loadQueue(context)
        if (queue.isEmpty()) return 0 to 0
        val index = prefs.getInt(KEY_QUEUE_INDEX, 0).coerceIn(0, queue.lastIndex)
        return index to queue.size
    }

    private fun applyEntryToLegacyFields(context: Context, entry: WidgetMomentEntry?) {
        if (entry == null) return
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        val existing = MomentWidgetDataStore.load(context)
        prefs
            .edit()
            .putBoolean(MomentWidgetDataStore.KEY_HAS_MOMENT, true)
            .putString(MomentWidgetDataStore.KEY_SENDER, entry.senderName)
            .putString(MomentWidgetDataStore.KEY_SENDER_ID, entry.senderId)
            .putString(MomentWidgetDataStore.KEY_MOMENT_ID, entry.momentId)
            .putString(MomentWidgetDataStore.KEY_IMAGE_PATH, entry.imagePath)
            .putString(MomentWidgetDataStore.KEY_CAPTION, entry.caption)
            .putString(MomentWidgetDataStore.KEY_RELATIVE_TIME, entry.relativeTime)
            .putLong(MomentWidgetDataStore.KEY_CREATED_AT, entry.createdAtMillis)
            .putString(MomentWidgetDataStore.KEY_AVATAR_PATH, entry.avatarPath)
            .putString(MomentWidgetDataStore.KEY_WIDGET_MODE, existing.widgetMode)
            .commit()
    }

    private fun Int.floorMod(other: Int): Int {
        val mod = this % other
        return if (mod < 0) mod + other else mod
    }
}
