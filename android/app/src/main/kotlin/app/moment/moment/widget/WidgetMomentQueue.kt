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
    val imageUrl: String? = null,
    val avatarUrl: String? = null,
    val isUnread: Boolean = false,
)

data class UpsertResult(
    val wasDuplicate: Boolean,
    val queueSize: Int,
    val sortedMomentIds: List<String>,
    val promotedToFront: Boolean = false,
)

object WidgetMomentQueue {
    private const val KEY_QUEUE = "recent_moments_json"
    private const val KEY_QUEUE_INDEX = "recent_moment_index"
    /** Set when FCM prepends a moment; mergeQueue must jump to front. */
    private const val KEY_RESET_VIEW_TO_FRONT = "widget_reset_view_to_front"
    private const val KEY_LAST_APPLIED_SYNC_GEN = "widget_last_applied_sync_gen"
    private const val MAX_ENTRIES = 1

    private val queueLock = Any()

    fun saveQueue(
        context: Context,
        entries: List<WidgetMomentEntry>,
        selectIndex: Int = 0,
    ) {
        synchronized(queueLock) {
            saveQueueUnsafe(context, entries, selectIndex)
        }
    }

    /**
     * Idempotent insert/update by [WidgetMomentEntry.momentId].
     * Merges with the existing queue, sorts by server time, and preserves the current card
     * unless [focusFront] is true.
     */
    fun upsertMoment(
        context: Context,
        entry: WidgetMomentEntry,
        focusFront: Boolean = false,
        /** FCM / push delivery — always show brand-new moments on the front card. */
        promoteNew: Boolean = false,
    ): UpsertResult {
        synchronized(queueLock) {
            migrateLegacyMomentIfNeeded(context)
            val existing = loadQueueUnsafe(context)
            val wasDuplicate = existing.any { it.momentId == entry.momentId }
            if (wasDuplicate) {
                WidgetMomentSyncLog.duplicateMerged(entry.momentId, "upsert")
            }
            val merged = mergeEntries(
                listOf(WidgetSeenOnDeviceStore.applySeenState(context, entry)),
                existing,
            )
            val prefs =
                context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
            val currentIndex =
                prefs.getInt(KEY_QUEUE_INDEX, 0).coerceIn(0, existing.lastIndex.coerceAtLeast(0))
            val viewingMomentId = existing.getOrNull(currentIndex)?.momentId
            val newIndex =
                when {
                    focusFront || (promoteNew && !wasDuplicate) -> 0
                    viewingMomentId == null -> 0
                    else -> {
                        val found = merged.indexOfFirst { it.momentId == viewingMomentId }
                        if (found >= 0) found else 0
                    }
                }
            saveQueueUnsafe(context, merged, newIndex)
            val ids = merged.map { it.momentId }
            WidgetMomentSyncLog.queueUpsert(
                entry.momentId,
                wasDuplicate,
                merged.size,
                ids,
                newIndex,
            )
            return UpsertResult(wasDuplicate, merged.size, ids, newIndex == 0)
        }
    }

    /** @deprecated Use [upsertMoment] — prepending by arrival order drops simultaneous moments. */
    @Deprecated("Use upsertMoment", ReplaceWith("upsertMoment(context, entry, focusFront)"))
    fun insertAtFront(
        context: Context,
        entry: WidgetMomentEntry,
        focusFront: Boolean = false,
    ) {
        upsertMoment(context, entry, focusFront = focusFront)
    }

    /**
     * Merges [incoming] with the local queue (never blind-replaces).
     * [showLatest] jumps to the newest moment after merge.
     * [syncGeneration] guards against stale Flutter sync responses.
     */
    fun mergeQueue(
        context: Context,
        incoming: List<WidgetMomentEntry>,
        showLatest: Boolean = false,
        syncGeneration: Long = 0L,
    ) {
        synchronized(queueLock) {
            migrateLegacyMomentIfNeeded(context)
            if (syncGeneration > 0L) {
                val prefs =
                    context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
                val lastApplied = prefs.getLong(KEY_LAST_APPLIED_SYNC_GEN, 0L)
                if (syncGeneration <= lastApplied) {
                    WidgetMomentSyncLog.staleSyncIgnored(syncGeneration, lastApplied)
                    return
                }
                prefs.edit().putLong(KEY_LAST_APPLIED_SYNC_GEN, syncGeneration).commit()
            }

            val existing = loadQueueUnsafe(context)
            if (incoming.isEmpty()) {
                if (existing.isEmpty()) clearUnsafe(context)
                return
            }

            val adjustedIncoming =
                incoming.map { WidgetSeenOnDeviceStore.applySeenState(context, it) }
            val merged = mergeEntries(adjustedIncoming, existing)
            val prefs =
                context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
            val currentIndex =
                prefs.getInt(KEY_QUEUE_INDEX, 0).coerceIn(0, existing.lastIndex.coerceAtLeast(0))
            val viewingMomentId = existing.getOrNull(currentIndex)?.momentId
            val pendingFront = consumeViewFrontPending(context)
            val hasNewMoment =
                incoming.any { entry -> existing.none { it.momentId == entry.momentId } }
            val newIndex =
                when {
                    showLatest || pendingFront || hasNewMoment -> 0
                    viewingMomentId == null -> 0
                    else -> {
                        val found = merged.indexOfFirst { it.momentId == viewingMomentId }
                        if (found >= 0) found else 0
                    }
                }
            saveQueueUnsafe(context, merged, newIndex)
            WidgetMomentSyncLog.queueUpsert(
                incoming.first().momentId,
                incoming.size == 1 && existing.any { it.momentId == incoming.first().momentId },
                merged.size,
                merged.map { it.momentId },
                newIndex,
            )
        }
    }

    fun findEntry(context: Context, momentId: String): WidgetMomentEntry? {
        synchronized(queueLock) {
            migrateLegacyMomentIfNeeded(context)
            return loadQueueUnsafe(context).firstOrNull { it.momentId == momentId }
        }
    }

    fun patchMedia(
        context: Context,
        momentId: String,
        imagePath: String?,
        avatarPath: String?,
    ) {
        synchronized(queueLock) {
            val queue = loadQueueUnsafe(context)
            val index = queue.indexOfFirst { it.momentId == momentId }
            if (index < 0) return
            val current = queue[index]
            val updated =
                current.copy(
                    imagePath = imagePath?.takeIf { it.isNotBlank() } ?: current.imagePath,
                    avatarPath = avatarPath?.takeIf { it.isNotBlank() } ?: current.avatarPath,
                )
            if (updated == current) return
            val next = queue.toMutableList()
            next[index] = updated
            val prefs =
                context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
            val viewIndex =
                prefs.getInt(KEY_QUEUE_INDEX, 0).coerceIn(0, queue.lastIndex.coerceAtLeast(0))
            saveQueueUnsafe(context, next, viewIndex)
        }
    }

    fun activeEntry(context: Context): WidgetMomentEntry? {
        synchronized(queueLock) {
            val queue = loadQueueUnsafe(context)
            if (queue.isEmpty()) return null
            val (index, _) = queueMetaUnsafe(context)
            return queue.getOrNull(index)
        }
    }

    fun cycle(context: Context, delta: Int) {
        synchronized(queueLock) {
            val queue = loadQueueUnsafe(context)
            if (queue.size <= 1) return
            val prefs =
                context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
            val current = prefs.getInt(KEY_QUEUE_INDEX, 0)
            val next = (current + delta).floorMod(queue.size)
            prefs.edit().putInt(KEY_QUEUE_INDEX, next).commit()
            applyEntryToLegacyFields(context, queue[next])
        }
    }

    fun setDisplayMoment(context: Context, entry: WidgetMomentEntry) {
        synchronized(queueLock) {
            migrateLegacyMomentIfNeeded(context)
            saveQueueUnsafe(
                context,
                listOf(WidgetSeenOnDeviceStore.applySeenState(context, entry)),
                selectIndex = 0,
            )
        }
    }

    /** Marks a moment viewed and clears the widget (empty state when caught up). */
    fun markSeenOnWidget(context: Context, momentId: String) {
        if (momentId.isBlank()) return
        WidgetSeenOnDeviceStore.markSeen(context, momentId)
        MomentWidgetDataStore.clearActiveMoment(context)
    }

    /** @deprecated Prefer [markSeenOnWidget] — keeps the moment visible as a clear read photo. */
    fun markViewed(context: Context, momentId: String) {
        markSeenOnWidget(context, momentId)
    }

    fun loadQueue(context: Context): List<WidgetMomentEntry> {
        synchronized(queueLock) {
            migrateLegacyMomentIfNeeded(context)
            return loadQueueUnsafe(context)
        }
    }

    fun clear(context: Context) {
        synchronized(queueLock) {
            clearUnsafe(context)
        }
    }

    fun patchEntries(
        context: Context,
        updates: List<WidgetMomentEntry>,
    ) {
        if (updates.isEmpty()) return
        synchronized(queueLock) {
            val byId = updates.associateBy { it.momentId }
            val queue = loadQueueUnsafe(context).map { byId[it.momentId] ?: it }
            val (index, _) = queueMetaUnsafe(context)
            saveQueueUnsafe(context, queue, index)
        }
    }

    fun queueMeta(context: Context): Pair<Int, Int> {
        synchronized(queueLock) {
            return queueMetaUnsafe(context)
        }
    }

    private fun queueMetaUnsafe(context: Context): Pair<Int, Int> {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        val queue = loadQueueUnsafe(context)
        if (queue.isEmpty()) return 0 to 0
        val index = prefs.getInt(KEY_QUEUE_INDEX, 0).coerceIn(0, queue.lastIndex)
        return index to queue.size
    }

    private fun saveQueueUnsafe(
        context: Context,
        entries: List<WidgetMomentEntry>,
        selectIndex: Int,
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
                    .put("relativeTime", entry.relativeTime)
                    .put("imageUrl", entry.imageUrl.orEmpty())
                    .put("avatarUrl", entry.avatarUrl.orEmpty())
                    .put("isUnread", entry.isUnread),
            )
        }
        val index = if (trimmed.isEmpty()) 0 else selectIndex.coerceIn(0, trimmed.lastIndex)
        val nextRenderSeq = prefs.getLong(MomentWidgetDataStore.KEY_RENDER_SEQ, 0L) + 1L
        prefs
            .edit()
            .putString(KEY_QUEUE, array.toString())
            .putInt(KEY_QUEUE_INDEX, index)
            .putLong(MomentWidgetDataStore.KEY_RENDER_SEQ, nextRenderSeq)
            .commit()
        applyEntryToLegacyFields(context, trimmed.getOrNull(index))
    }

    private fun clearUnsafe(context: Context) {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        prefs
            .edit()
            .remove(KEY_QUEUE)
            .remove(KEY_QUEUE_INDEX)
            .commit()
    }

    private fun resolveViewingMomentId(
        context: Context,
        existing: List<WidgetMomentEntry>,
    ): String? {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        val currentIndex =
            prefs.getInt(KEY_QUEUE_INDEX, 0).coerceIn(0, existing.lastIndex.coerceAtLeast(0))
        return existing.getOrNull(currentIndex)?.momentId
    }

    private fun applyEntryToLegacyFields(context: Context, entry: WidgetMomentEntry?) {
        if (entry == null) return
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        val widgetMode = prefs.getString(MomentWidgetDataStore.KEY_WIDGET_MODE, "latest") ?: "latest"
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
            .putString(MomentWidgetDataStore.KEY_WIDGET_MODE, widgetMode)
            .putBoolean(MomentWidgetDataStore.KEY_IS_UNREAD, entry.isUnread)
            .commit()
    }

    private fun mergeEntries(
        incoming: List<WidgetMomentEntry>,
        existing: List<WidgetMomentEntry>,
    ): List<WidgetMomentEntry> {
        val byId = linkedMapOf<String, WidgetMomentEntry>()
        for (entry in existing) {
            byId[entry.momentId] = entry
        }
        for (entry in incoming) {
            val previous = byId[entry.momentId]
            byId[entry.momentId] =
                if (previous == null) {
                    entry
                } else {
                    mergeDuplicate(entry, previous)
                }
        }
        return byId.values
            .sortedWith(
                compareByDescending<WidgetMomentEntry> { it.createdAtMillis }
                    .thenByDescending { it.momentId },
            )
            .take(MAX_ENTRIES)
    }

    private fun mergeDuplicate(
        incoming: WidgetMomentEntry,
        previous: WidgetMomentEntry,
    ): WidgetMomentEntry {
        val createdAtMillis =
            when {
                incoming.createdAtMillis > 0L && previous.createdAtMillis > 0L ->
                    maxOf(incoming.createdAtMillis, previous.createdAtMillis)
                incoming.createdAtMillis > 0L -> incoming.createdAtMillis
                else -> previous.createdAtMillis
            }
        val isUnread =
            when {
                !previous.isUnread -> false
                incoming.isUnread -> true
                else -> false
            }
        return incoming.copy(
            senderName = incoming.senderName.takeIf { it.isNotBlank() } ?: previous.senderName,
            senderId = incoming.senderId.takeIf { it.isNotBlank() } ?: previous.senderId,
            caption = incoming.caption.takeIf { it.isNotBlank() } ?: previous.caption,
            relativeTime = incoming.relativeTime.takeIf { it.isNotBlank() } ?: previous.relativeTime,
            imagePath = incoming.imagePath?.takeIf { it.isNotBlank() } ?: previous.imagePath,
            avatarPath = incoming.avatarPath?.takeIf { it.isNotBlank() } ?: previous.avatarPath,
            imageUrl = incoming.imageUrl?.takeIf { it.isNotBlank() } ?: previous.imageUrl,
            avatarUrl = incoming.avatarUrl?.takeIf { it.isNotBlank() } ?: previous.avatarUrl,
            createdAtMillis = createdAtMillis,
            isUnread = isUnread,
        )
    }

    private fun loadQueueUnsafe(context: Context): List<WidgetMomentEntry> {
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
                            imageUrl = obj.optString("imageUrl").ifBlank { null },
                            avatarUrl = obj.optString("avatarUrl").ifBlank { null },
                            isUnread = obj.optBoolean("isUnread", false),
                        ),
                    )
                }
            }
        }.getOrDefault(emptyList())
    }

    private fun migrateLegacyMomentIfNeeded(context: Context) {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        if (prefs.contains(KEY_QUEUE)) return
        if (!prefs.getBoolean(MomentWidgetDataStore.KEY_HAS_MOMENT, false)) return

        val momentId = prefs.getString(MomentWidgetDataStore.KEY_MOMENT_ID, null).orEmpty()
        if (momentId.isBlank()) return

        val entry =
            WidgetMomentEntry(
                momentId = momentId,
                senderName = prefs.getString(MomentWidgetDataStore.KEY_SENDER, "") ?: "",
                senderId = prefs.getString(MomentWidgetDataStore.KEY_SENDER_ID, "") ?: "",
                imagePath = prefs.getString(MomentWidgetDataStore.KEY_IMAGE_PATH, null),
                avatarPath = prefs.getString(MomentWidgetDataStore.KEY_AVATAR_PATH, null),
                caption = prefs.getString(MomentWidgetDataStore.KEY_CAPTION, "") ?: "",
                createdAtMillis = prefs.getLong(MomentWidgetDataStore.KEY_CREATED_AT, 0L),
                relativeTime = prefs.getString(MomentWidgetDataStore.KEY_RELATIVE_TIME, "") ?: "",
            )
        saveQueueUnsafe(context, listOf(entry), selectIndex = 0)
    }

    private fun consumeViewFrontPending(context: Context): Boolean {
        val prefs = context.getSharedPreferences(MomentWidgetDataStore.PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_RESET_VIEW_TO_FRONT, false)) return false
        prefs.edit().remove(KEY_RESET_VIEW_TO_FRONT).commit()
        return true
    }

    private fun Int.floorMod(other: Int): Int {
        val mod = this % other
        return if (mod < 0) mod + other else mod
    }
}
