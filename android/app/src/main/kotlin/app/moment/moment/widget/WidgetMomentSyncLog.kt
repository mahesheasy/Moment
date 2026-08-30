package app.moment.moment.widget

import android.util.Log

/** Debug logging for the home-widget sync pipeline. */
internal object WidgetMomentSyncLog {
    private const val TAG = "MomentSync"

    fun fcmReceived(momentId: String) {
        Log.d(TAG, "FCM received: momentId=$momentId")
    }

    fun queueUpsert(
        momentId: String,
        duplicate: Boolean,
        size: Int,
        sortedIds: List<String>,
        viewIndex: Int,
    ) {
        Log.d(
            TAG,
            "Queue upsert: momentId=$momentId duplicate=$duplicate size=$size viewIndex=$viewIndex order=${sortedIds.joinToString()}",
        )
    }

    fun duplicateMerged(momentId: String, source: String) {
        Log.d(TAG, "Duplicate merged ($source): momentId=$momentId")
    }

    fun staleSyncIgnored(generation: Long, lastApplied: Long) {
        Log.d(TAG, "Ignoring stale sync response: gen=$generation last=$lastApplied")
    }

    fun mediaDownloadStart(momentId: String) {
        Log.d(TAG, "Media download started: momentId=$momentId")
    }

    fun mediaDownloadDone(momentId: String, hasImage: Boolean, hasAvatar: Boolean) {
        Log.d(TAG, "Media download done: momentId=$momentId image=$hasImage avatar=$hasAvatar")
    }

    fun widgetUpdateStarted() {
        Log.d(TAG, "Widget update started")
    }

    fun widgetUpdateCompleted() {
        Log.d(TAG, "Widget update completed")
    }

    fun error(message: String, error: Throwable? = null) {
        if (error != null) Log.w(TAG, message, error) else Log.w(TAG, message)
    }
}
